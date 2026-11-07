'use strict';

function messageForJob(job) {
  if (typeof job.roomId !== 'string' ||
      !/^[a-zA-Z0-9_.~%-]+$/.test(job.roomId) ||
      typeof job.title !== 'string' ||
      typeof job.body !== 'string' ||
      !job.title.trim() || !job.body.trim()) {
    throw new Error('Invalid push job payload');
  }
  return {
    topic: `room_${job.roomId}`,
    notification: { title: job.title, body: job.body },
    data: { roomId: job.roomId },
    android: { notification: { channelId: 'teamup_notifications' } },
  };
}

function multicastForEvent(job, tokens) {
  const roomId = job.roomId;
  const hasRoom = typeof roomId === 'string' &&
    /^[a-zA-Z0-9_.~%-]+$/.test(roomId);
  if (!Array.isArray(tokens) || tokens.length === 0 || tokens.length > 500 ||
      typeof job.type !== 'string' ||
      !/^[a-z_]+$/.test(job.type) ||
      (job.type !== 'broadcast' && !hasRoom) ||
      (roomId != null && !hasRoom) ||
      typeof job.title !== 'string' || !job.title.trim() ||
      typeof job.body !== 'string' || !job.body.trim()) {
    throw new Error('Invalid event notification');
  }
  return {
    tokens,
    notification: { title: job.title, body: job.body },
    data: {
      type: job.type,
      ...(hasRoom ? { roomId } : {}),
      ...(job.requesterUid ? { requestId: job.requesterUid } : {}),
    },
    android: { notification: { channelId: 'teamup_notifications' } },
  };
}

module.exports = { messageForJob, multicastForEvent };
