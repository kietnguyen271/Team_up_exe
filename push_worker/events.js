'use strict';

const unique = (values) => [...new Set((values || []).filter(
  (value) => typeof value === 'string' && value.length > 0,
))];

function projectSource(kind, data) {
  if (!data) return null;
  if (kind === 'room') return {
    name: data.name || '',
    serverId: data.serverId || '',
    memberIds: unique(data.memberIds),
    locked: data.locked === true,
    leaderId: data.leaderId || null,
  };
  if (kind === 'request') return {
    status: data.status || '',
    message: data.message || '',
    createdAt: data.createdAt?.toMillis?.() || 0,
  };
  if (kind === 'vote') return {
    status: data.status || '',
    winnerUid: data.winnerUid || null,
    startedAt: data.startedAt?.toMillis?.() || 0,
  };
  if (kind === 'disband') return {
    status: data.status || '',
    approvedBy: unique(data.approvedBy),
    createdAt: data.createdAt?.toMillis?.() || 0,
  };
  return null;
}

function deriveEvents(kind, path, before, after) {
  const parts = path.split('/');
  const roomId = parts[1];
  if (!roomId) return [];
  const base = { roomId, title: 'TeamUp EXE' };
  if (kind === 'request') {
    const requesterUid = parts[3];
    if (!requesterUid || !after) return [];
    if (after.status === 'pending' &&
        (before?.status !== 'pending' || before?.createdAt !== after.createdAt)) {
      return [{ ...base, type: 'join_request', requesterUid,
        body: after.message
          ? `Có yêu cầu tham gia phòng. Lời nhắn: ${after.message}`
          : 'Có yêu cầu tham gia phòng.' }];
    }
    if (before?.status === 'pending' && after.status === 'approved') {
      return [{ ...base, type: 'request_approved', requesterUid,
        body: 'Bạn đã được nhận vào phòng.' }];
    }
    if (before?.status === 'pending' &&
        ['rejected', 'expired'].includes(after.status)) {
      return [{ ...base, type: 'request_rejected', requesterUid,
        body: 'Yêu cầu tham gia phòng không được chấp nhận.' }];
    }
    return [];
  }
  if (kind === 'room') {
    if (before && !after && before.serverId === 'exe2') {
      return [{ ...base, type: 'rollover_done',
        recipientUids: before.memberIds,
        body: 'Bạn đã hoàn thành kỳ học.' }];
    }
    if (!before || !after) return [];
    const events = [];
    if (before.serverId === 'exe1' && after.serverId === 'exe2') {
      events.push({ ...base, type: 'rollover_moved',
        recipientUids: after.memberIds,
        body: 'Phòng của bạn đã chuyển từ EXE1 lên EXE2.' });
    }
    if (JSON.stringify(before.memberIds) !== JSON.stringify(after.memberIds)) {
      const disbanded = before.memberIds.length > 1 &&
        after.memberIds.length === 0;
      events.push({ ...base,
        type: disbanded ? 'disband_done' : 'member_changed',
        recipientUids: unique([...before.memberIds, ...after.memberIds]),
        body: disbanded ? 'Nhóm đã giải tán.' :
          'Thành viên trong phòng đã thay đổi.' });
    }
    if (before.locked !== after.locked) {
      events.push({ ...base, type: 'room_lock',
        recipientUids: after.memberIds,
        body: after.locked ? 'Phòng đã khóa.' : 'Phòng đã mở khóa.' });
    }
    return events;
  }
  if (kind === 'vote' && after) {
    if (after.status === 'active' &&
        (before?.status !== 'active' || before?.startedAt !== after.startedAt)) {
      return [{ ...base, type: 'vote_started',
        body: 'Bắt đầu bình chọn trưởng nhóm.' }];
    }
    if (before?.status === 'active' && after.status === 'finished') {
      return [{ ...base, type: 'vote_finished',
        body: after.winnerUid
          ? 'Đã có trưởng nhóm mới.'
          : 'Phiên bầu kết thúc, chưa có trưởng nhóm.' }];
    }
  }
  if (kind === 'disband' && after) {
    if (after.status === 'active' &&
        (before?.status !== 'active' || before?.createdAt !== after.createdAt)) {
      return [{ ...base, type: 'disband_proposed',
        body: 'Có đề xuất giải tán nhóm, hãy xác nhận.' }];
    }
    if (before?.status === 'active' && after.status === 'done') {
      return [{ ...base, type: 'disband_done',
        recipientUids: after.approvedBy,
        body: 'Nhóm đã giải tán.' }];
    }
  }
  return [];
}

module.exports = { deriveEvents, projectSource };
