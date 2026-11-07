'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { messageForJob, multicastForEvent } = require('./message');

test('room push includes topic, roomId and Android channel', () => {
  const message = messageForJob({
    roomId: 'room123', title: 'Phòng mới', body: 'Hãy xem phòng',
  });
  assert.equal(message.topic, 'room_room123');
  assert.equal(message.data.roomId, 'room123');
  assert.equal(message.android.notification.channelId, 'teamup_notifications');
});

test('invalid job cannot target arbitrary topic', () => {
  assert.throws(() => messageForJob({ roomId: 'x/y', title: 'A', body: 'B' }));
});

test('event multicast includes type and room route', () => {
  const message = multicastForEvent({
    type: 'request_approved', roomId: 'r1', requesterUid: 'u2',
    title: 'TeamUp EXE', body: 'Đã được duyệt',
  }, ['token-1']);
  assert.equal(message.tokens[0], 'token-1');
  assert.equal(message.data.type, 'request_approved');
  assert.equal(message.data.requestId, 'u2');
});

test('broadcast to a server does not invent a room route', () => {
  const message = multicastForEvent({
    type: 'broadcast', targetKind: 'server', targetId: 'exe1',
    title: 'Thông báo', body: 'Nội dung',
  }, ['token-1']);
  assert.equal(message.data.type, 'broadcast');
  assert.equal(message.data.roomId, undefined);
});
