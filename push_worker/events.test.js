'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { deriveEvents } = require('./events');

test('new request and approval notify the correct audiences', () => {
  const path = 'rooms/r1/joinRequests/u2';
  assert.equal(deriveEvents('request', path, null,
    { status: 'pending', createdAt: 1, message: '' })[0].type,
  'join_request');
  const approved = deriveEvents('request', path,
    { status: 'pending', createdAt: 1 },
    { status: 'approved', createdAt: 1 });
  assert.deepEqual(approved.map((event) => event.requesterUid), ['u2']);
});

test('room rollover keeps recipients when EXE2 room is removed', () => {
  const events = deriveEvents('room', 'rooms/r2',
    { serverId: 'exe2', memberIds: ['a', 'b'] }, null);
  assert.equal(events[0].type, 'rollover_done');
  assert.deepEqual(events[0].recipientUids, ['a', 'b']);
});

test('vote and lock changes create distinct events', () => {
  const vote = deriveEvents('vote', 'rooms/r1/voteSession/current',
    { status: 'active' }, { status: 'finished', winnerUid: 'a' });
  assert.equal(vote[0].type, 'vote_finished');
  const lock = deriveEvents('room', 'rooms/r1',
    { serverId: 'exe1', memberIds: ['a'], locked: false },
    { serverId: 'exe1', memberIds: ['a'], locked: true });
  assert.equal(lock[0].type, 'room_lock');
});

test('disband resets the room and notifies former members', () => {
  const events = deriveEvents('room', 'rooms/r1',
    { serverId: 'exe1', memberIds: ['a', 'b'], locked: false },
    { serverId: 'exe1', memberIds: [], locked: false });
  assert.equal(events[0].type, 'disband_done');
  assert.deepEqual(events[0].recipientUids, ['a', 'b']);
});
