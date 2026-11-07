const teamSkills = <String>[
  'Backend',
  'Frontend',
  'Mobile',
  'Database/SQL',
  'UI/UX',
  'DevOps',
  'Kiểm thử',
  'AI/ML',
  'Quản lý dự án',
];

class TeamUser {
  const TeamUser({
    required this.id,
    required this.name,
    required this.email,
    required this.bio,
    required this.skills,
    this.serverId,
    this.roomId,
    this.status = 'active',
    this.pendingRequestIds = const [],
  });

  final String id;
  final String name;
  final String email;
  final String bio;
  final List<String> skills;
  final String? serverId;
  final String? roomId;
  final String status;
  final List<String> pendingRequestIds;

  bool get hasProfile =>
      name.trim().isNotEmpty && bio.trim().isNotEmpty && skills.isNotEmpty;
  bool get completed => status == 'completed';
}

class TeamRoom {
  const TeamRoom({
    required this.id,
    required this.serverId,
    required this.name,
    required this.capacity,
    required this.memberIds,
    this.leaderId,
    this.locked = false,
    this.defaultName,
  });

  final String id;
  final String serverId;
  final String name;
  final String? defaultName;
  final int capacity;
  final List<String> memberIds;
  final String? leaderId;
  final bool locked;

  bool get isEmpty => memberIds.isEmpty;
  bool get isFull => memberIds.length >= capacity;
  bool contains(String uid) => memberIds.contains(uid);
  String get status => locked
      ? 'locked'
      : isFull
          ? 'full'
          : isEmpty
              ? 'empty'
              : 'open';
}

class TeamJoinRequest {
  const TeamJoinRequest({
    required this.uid,
    required this.roomId,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    this.decidedBy,
    this.message = '',
  });

  final String uid;
  final String roomId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status;
  final String? decidedBy;
  final String message;
  bool isPendingAt(DateTime now) =>
      status == 'pending' && now.isBefore(expiresAt);
}

class TeamVote {
  const TeamVote({
    required this.startedBy,
    required this.endsAt,
    required this.status,
    required this.ballots,
  });

  final String startedBy;
  final DateTime endsAt;
  final String status;
  final Map<String, String> ballots;
}

class TeamDisband {
  const TeamDisband({
    required this.requestedBy,
    required this.endsAt,
    required this.status,
    required this.approvedBy,
  });

  final String requestedBy;
  final DateTime endsAt;
  final String status;
  final List<String> approvedBy;
}

class RoomTemplate {
  const RoomTemplate(this.name, this.capacity);
  final String name;
  final int capacity;
}
