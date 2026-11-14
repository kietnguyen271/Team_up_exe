'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const projectId = 'teamup-exe';
const email = 'admin.demo@teamup.local';
const password = process.env.TEAMUP_DEMO_ADMIN_PASSWORD;

if (process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099' ||
    process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') {
  throw new Error('Refusing to seed outside the local Firebase emulators.');
}
if (!password || password.length < 8) {
  throw new Error('Set TEAMUP_DEMO_ADMIN_PASSWORD to at least 8 characters.');
}

initializeApp({ projectId });

async function seed() {
  const auth = getAuth();
  const db = getFirestore();
  let user;
  try {
    user = await auth.getUserByEmail(email);
    user = await auth.updateUser(user.uid, { password, emailVerified: true });
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    user = await auth.createUser({ email, password, emailVerified: true });
  }

  await db.collection('admins').doc(email).set({
    uid: user.uid,
    addedAt: FieldValue.serverTimestamp(),
    demo: true,
  }, { merge: true });

  const templates = {
    exe1: [{ name: 'Room 1', capacity: 6 }, { name: 'Room 2', capacity: 6 }],
    exe2: [{ name: 'Room 1', capacity: 6 }, { name: 'Room 2', capacity: 6 }],
  };
  for (const [serverId, rooms] of Object.entries(templates)) {
    await db.collection('servers').doc(serverId).set({
      name: serverId.toUpperCase(),
      roomTemplate: rooms,
    });
    for (let index = 0; index < rooms.length; index++) {
      const room = rooms[index];
      const ref = db.collection('rooms').doc(`local-${serverId}-${index + 1}`);
      if ((await ref.get()).exists) continue;
      await ref.set({
        serverId,
        name: room.name,
        defaultName: room.name,
        nameLower: room.name.toLowerCase(),
        capacity: room.capacity,
        memberIds: [],
        leaderId: null,
        locked: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  }

  await db.collection('announcements').doc('local-demo-welcome').set({
    title: 'Chào mừng đến TeamUp EXE',
    body: 'Đây là dữ liệu mẫu trên Firebase Emulator cục bộ.',
    serverId: 'all',
    createdBy: user.uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  console.log(`Local demo admin ready: ${email}`);
}

seed().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
