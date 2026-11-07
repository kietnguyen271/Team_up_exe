'use strict';

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { messageForJob, multicastForEvent } = require('./message');
const { deriveEvents, projectSource } = require('./events');

initializeApp({
  credential: applicationDefault(),
  projectId: process.env.FIREBASE_PROJECT_ID || 'teamup-exe',
});

const db = getFirestore();
const workerId = `worker-${process.pid}-${Date.now()}`;
const staleAfterMs = 10 * 60 * 1000;
const active = new Set();
const observedQueues = new Map();

async function claim(ref) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return null;
    const job = snapshot.data();
    const stale = job.status === 'sending' &&
      job.claimedAt?.toMillis() < Date.now() - staleAfterMs;
    if (job.status !== 'pending' && !stale) return null;
    let message;
    try {
      message = job.type
        ? multicastForEvent(job, ['validation-token'])
        : messageForJob(job);
    } catch (error) {
      transaction.update(ref, {
        status: 'failed',
        error: String(error),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return null;
    }
    transaction.update(ref, {
      status: 'sending',
      claimedBy: workerId,
      claimedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { job, message };
  });
}

async function recipientsForEvent(job) {
  if (job.type === 'broadcast') {
    if (job.targetKind === 'user' && typeof job.targetId === 'string') {
      return [job.targetId];
    }
    if (job.targetKind === 'room' && typeof job.roomId === 'string') {
      const room = await db.collection('rooms').doc(job.roomId).get();
      return room.exists ? [...new Set(room.data().memberIds || [])] : [];
    }
    if (job.targetKind === 'server' &&
        ['exe1', 'exe2'].includes(job.targetId)) {
      const users = await db.collection('users')
        .where('serverId', '==', job.targetId).get();
      return users.docs.map((doc) => doc.id);
    }
    if (job.targetKind === 'all') {
      const users = await db.collection('users').get();
      return users.docs.map((doc) => doc.id);
    }
    throw new Error('Invalid broadcast audience');
  }
  if (['request_approved', 'request_rejected'].includes(job.type)) {
    return job.requesterUid ? [job.requesterUid] : [];
  }
  if (Array.isArray(job.recipientUids)) {
    return [...new Set(job.recipientUids)];
  }
  const room = await db.collection('rooms').doc(job.roomId).get();
  return room.exists ? [...new Set(room.data().memberIds || [])] : [];
}

async function sendEventJob(job) {
  const recipients = await recipientsForEvent(job);
  const tokenDocuments = (await Promise.all(recipients.map((uid) =>
    db.collection('users').doc(uid).collection('fcmTokens').get())))
    .flatMap((snapshot) => snapshot.docs);
  let successCount = 0;
  let failureCount = 0;
  const errors = [];
  for (let start = 0; start < tokenDocuments.length; start += 500) {
    const group = tokenDocuments.slice(start, start + 500);
    const result = await getMessaging().sendEachForMulticast(
      multicastForEvent(job, group.map((doc) => doc.id)));
    successCount += result.successCount;
    failureCount += result.failureCount;
    await Promise.all(result.responses.map(async (response, index) => {
      const code = response.error?.code;
      if (code) errors.push(code);
      if (code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token') {
        await group[index].ref.delete();
      }
    }));
  }
  return { successCount, failureCount, errors: [...new Set(errors)] };
}

async function processJob(ref) {
  if (active.has(ref.id)) return;
  active.add(ref.id);
  try {
    const claimed = await claim(ref);
    if (!claimed) return;
    const result = claimed.job.type
      ? await sendEventJob(claimed.job)
      : { messageId: await getMessaging().send(claimed.message) };
    const failed = result.failureCount > 0;
    await ref.update({
      status: failed ? 'failed' : 'sent',
      ...result,
      ...(failed ? { error: result.errors.join(', ') } :
        { sentAt: FieldValue.serverTimestamp() }),
      updatedAt: FieldValue.serverTimestamp(),
    });
    console.log(`Sent ${ref.id}:`, result);
  } catch (error) {
    console.error(`Failed ${ref.id}:`, error);
    try {
      await ref.update({
        status: 'failed',
        error: String(error),
        updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (updateError) {
      console.error(`Could not mark ${ref.id} as failed:`, updateError);
    }
  } finally {
    active.delete(ref.id);
  }
}

async function persistObservation(kind, path, after, initialSnapshot) {
  const stateRef = db.collection('_workerState')
    .doc(Buffer.from(path).toString('base64url'));
  const jobRefs = Array.from({ length: 3 }, () =>
    db.collection('notificationJobs').doc());
  await db.runTransaction(async (transaction) => {
    const state = await transaction.get(stateRef);
    const before = state.data()?.source || null;
    if (state.exists && JSON.stringify(before) === JSON.stringify(after)) return;
    const events = !state.exists && initialSnapshot
      ? [] : deriveEvents(kind, path, before, after);
    transaction.set(stateRef, { source: after, updatedAt: FieldValue.serverTimestamp() });
    for (let index = 0; index < events.length; index++) {
      transaction.set(jobRefs[index], {
        ...events[index],
        status: 'pending',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
}

async function processObserved(kind, change, initialSnapshot) {
  const after = change.type === 'removed'
    ? null : projectSource(kind, change.doc.data());
  await persistObservation(kind, change.doc.ref.path, after, initialSnapshot);
}

function observe(kind, query) {
  let initialSnapshot = true;
  query.onSnapshot((snapshot) => {
    const initial = initialSnapshot;
    initialSnapshot = false;
    for (const change of snapshot.docChanges()) {
      const path = change.doc.ref.path;
      const previous = observedQueues.get(path) || Promise.resolve();
      const next = previous.then(() =>
        processObserved(kind, change, initial)).catch((error) => {
        console.error(`Could not observe ${path}:`, error);
      });
      observedQueues.set(path, next);
      void next.finally(() => {
        if (observedQueues.get(path) === next) observedQueues.delete(path);
      });
    }
  }, (error) => console.error(`Source listener ${kind} failed:`, error));
}

observe('room', db.collection('rooms'));
observe('request', db.collectionGroup('joinRequests'));
observe('vote', db.collectionGroup('voteSession'));
observe('disband', db.collectionGroup('disband'));

async function reconcileDeletedRooms() {
  const states = await db.collection('_workerState').get();
  for (const state of states.docs) {
    const path = Buffer.from(state.id, 'base64url').toString();
    if (!/^rooms\/[^/]+$/.test(path) || !state.data().source) continue;
    const room = await db.doc(path).get();
    if (!room.exists) await persistObservation('room', path, null, false);
  }
}

setTimeout(() => {
  void reconcileDeletedRooms().catch((error) =>
    console.error('Deleted room reconciliation failed:', error));
}, 5000);

db.collection('notificationJobs')
  .where('status', 'in', ['pending', 'sending'])
  .onSnapshot((snapshot) => {
    for (const doc of snapshot.docs) {
      void processJob(doc.ref);
    }
  }, (error) => {
    console.error('Firestore listener failed:', error);
    process.exitCode = 1;
  });

setInterval(async () => {
  try {
    const snapshot = await db.collection('notificationJobs')
      .where('status', 'in', ['pending', 'sending']).get();
    for (const doc of snapshot.docs) void processJob(doc.ref);
  } catch (error) {
    console.error('Push job retry scan failed:', error);
  }
}, 60 * 1000);

console.log('TeamUp FCM worker listening for notificationJobs');
