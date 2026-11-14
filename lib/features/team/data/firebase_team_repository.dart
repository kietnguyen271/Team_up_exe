import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../domain/team_models.dart';
import '../domain/team_policy.dart';
import 'team_repository.dart';

class FirebaseTeamRepository implements TeamRepository {
  FirebaseTeamRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : db = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore db;
  final FirebaseAuth auth;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      db.collection('users').doc(uid);
  DocumentReference<Map<String, dynamic>> _room(String roomId) =>
      db.collection('rooms').doc(roomId);
  DocumentReference<Map<String, dynamic>> _request(String roomId, String uid) =>
      _room(roomId).collection('joinRequests').doc(uid);
  DocumentReference<Map<String, dynamic>> _vote(String roomId) =>
      _room(roomId).collection('voteSession').doc('current');
  DocumentReference<Map<String, dynamic>> _disband(String roomId) =>
      _room(roomId).collection('disband').doc('current');

  void _requireSignedInStudent(String uid) {
    final current = auth.currentUser;
    if (current == null ||
        current.uid != uid ||
        !TeamPolicy.validEmail(current.email ?? '')) {
      throw const TeamPolicyException(AppStrings.invalidSchoolEmail);
    }
  }

  TeamUser _userFrom(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return TeamUser(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      skills: List<String>.from(data['skills'] as List? ?? const []),
      serverId: data['serverId'] as String?,
      roomId: data['roomId'] as String?,
      status: data['status'] as String? ?? 'active',
      pendingRequestIds:
          List<String>.from(data['pendingRequestIds'] as List? ?? const []),
    );
  }

  TeamRoom _roomFrom(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return TeamRoom(
      id: snapshot.id,
      serverId: data['serverId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      defaultName: data['defaultName'] as String?,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
      memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
      leaderId: data['leaderId'] as String?,
      locked: data['locked'] as bool? ?? false,
    );
  }

  TeamJoinRequest _requestFrom(
      String roomId, DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return TeamJoinRequest(
      uid: snapshot.id,
      roomId: roomId,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
      status: data['status'] as String? ?? 'pending',
      decidedBy: data['decidedBy'] as String?,
      message: data['message'] as String? ?? '',
    );
  }

  @override
  Stream<TeamUser?> watchUser(String uid) =>
      _user(uid).snapshots().map((doc) => doc.exists ? _userFrom(doc) : null);

  @override
  Future<TeamUser?> getUser(String uid) async {
    final doc = await _user(uid).get();
    return doc.exists ? _userFrom(doc) : null;
  }

  @override
  Future<List<TeamUser>> getMembers(List<String> uids) async {
    final docs = await Future.wait(uids.map((uid) => _user(uid).get()));
    return docs.where((doc) => doc.exists).map(_userFrom).toList();
  }

  @override
  Stream<List<TeamRoom>> watchRooms(String serverId) => db
      .collection('rooms')
      .where('serverId', isEqualTo: serverId)
      .snapshots()
      .map((query) => query.docs.map(_roomFrom).toList()
        ..sort((a, b) => a.name.compareTo(b.name)));

  @override
  Stream<TeamRoom?> watchRoom(String roomId) => _room(roomId)
      .snapshots()
      .map((doc) => doc.exists ? _roomFrom(doc) : null);

  @override
  Stream<List<TeamJoinRequest>> watchRequests(String roomId) =>
      _room(roomId).collection('joinRequests').snapshots().map((query) =>
          query.docs.map((doc) => _requestFrom(roomId, doc)).toList());

  @override
  Stream<TeamJoinRequest?> watchOwnRequest(String roomId, String uid) =>
      _request(roomId, uid)
          .snapshots()
          .map((doc) => doc.exists ? _requestFrom(roomId, doc) : null);

  @override
  Stream<TeamVote?> watchVote(String roomId) =>
      _vote(roomId).snapshots().map((doc) {
        if (!doc.exists) return null;
        final data = doc.data()!;
        return TeamVote(
          startedBy: data['startedBy'] as String? ?? '',
          endsAt: (data['endsAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
          status: data['status'] as String? ?? 'active',
          ballots:
              Map<String, String>.from(data['ballots'] as Map? ?? const {}),
        );
      });

  @override
  Stream<TeamDisband?> watchDisband(String roomId) =>
      _disband(roomId).snapshots().map((doc) {
        if (!doc.exists) return null;
        final data = doc.data()!;
        return TeamDisband(
          requestedBy: data['requestedBy'] as String? ?? '',
          endsAt: (data['endsAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
          status: data['status'] as String? ?? 'active',
          approvedBy:
              List<String>.from(data['approvedBy'] as List? ?? const []),
        );
      });

  @override
  Future<void> saveProfile(String uid, String email, String name, String bio,
      List<String> skills) async {
    _requireSignedInStudent(uid);
    TeamPolicy.validateProfile(name, bio, skills);
    await db.runTransaction((tx) async {
      final ref = _user(uid);
      final existing = await tx.get(ref);
      if (existing.exists) {
        tx.update(ref, {
          'name': name.trim(),
          'bio': bio.trim(),
          'skills': skills,
        });
      } else {
        tx.set(ref, {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'bio': bio.trim(),
          'skills': skills,
          'serverId': null,
          'roomId': null,
          'status': 'active',
          'pendingRequestIds': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> chooseServer(String uid, String serverId) async {
    _requireSignedInStudent(uid);
    if (serverId != 'exe1' && serverId != 'exe2') {
      throw const TeamPolicyException(AppStrings.invalidServer);
    }
    await db.runTransaction((tx) async {
      final ref = _user(uid);
      final doc = await tx.get(ref);
      if (!doc.exists) {
        throw const TeamPolicyException(AppStrings.setupProfileFirst);
      }
      final user = _userFrom(doc);
      if (!user.hasProfile || user.completed || user.roomId != null) {
        throw const TeamPolicyException(AppStrings.cannotChangeServer);
      }
      tx.update(ref, {'serverId': serverId});
    });
  }

  @override
  Future<String> joinOrRequest(String uid, String roomId,
      {String message = ''}) async {
    _requireSignedInStudent(uid);
    if (message.length > TeamPolicy.maxRequestMessageLength) {
      throw const TeamPolicyException(AppStrings.requestMessageTooLong);
    }
    return db.runTransaction((tx) async {
      final userRef = _user(uid);
      final roomRef = _room(roomId);
      final userDoc = await tx.get(userRef);
      final roomDoc = await tx.get(roomRef);
      if (!userDoc.exists || !roomDoc.exists) {
        throw const TeamPolicyException(AppStrings.userOrRoomMissing);
      }
      final user = _userFrom(userDoc);
      final room = _roomFrom(roomDoc);
      TeamPolicy.checkJoin(user, room);
      final now = DateTime.now().toUtc();
      final activePending = <String>[];
      final pendingDocs = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final pendingRoomId in user.pendingRequestIds) {
        final doc = await tx.get(_request(pendingRoomId, uid));
        pendingDocs.add(doc);
        if (doc.exists && _requestFrom(pendingRoomId, doc).isPendingAt(now)) {
          activePending.add(pendingRoomId);
        }
      }
      if (room.isEmpty) {
        tx.update(roomRef, {
          'memberIds': [uid]
        });
        tx.update(userRef, {
          'roomId': roomId,
          'serverId': room.serverId,
          'pendingRequestIds': <String>[],
        });
        for (final doc in pendingDocs) {
          if (doc.exists && doc.data()?['status'] == 'pending') {
            tx.update(doc.reference, {'status': 'cancelled'});
          }
        }
        return 'joined';
      }
      final requestRef = _request(roomId, uid);
      final requestDoc = pendingDocs
              .where((doc) => doc.reference.path == requestRef.path)
              .firstOrNull ??
          await tx.get(requestRef);
      if (requestDoc.exists &&
          !TeamPolicy.canResendRequest(_requestFrom(roomId, requestDoc), now)) {
        throw const TeamPolicyException(AppStrings.requestAlreadyPending);
      }
      if (activePending.length >= TeamPolicy.maxPendingRequests) {
        throw const TeamPolicyException(AppStrings.tooManyRequests);
      }
      tx.set(requestRef, {
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(now.add(TeamPolicy.requestLifetime)),
        'status': 'pending',
        'decidedBy': null,
        'message': message.trim(),
      });
      tx.update(userRef, {
        'pendingRequestIds': [...activePending, roomId]
      });
      for (final doc in pendingDocs) {
        if (doc.exists &&
            doc.reference.path != requestRef.path &&
            doc.data()?['status'] == 'pending' &&
            !activePending.contains(doc.reference.parent.parent!.id)) {
          tx.update(doc.reference, {'status': 'expired'});
        }
      }
      return 'requested';
    });
  }

  @override
  Future<void> decideRequest(
      String actorUid, String roomId, String requesterUid, bool approve) async {
    _requireSignedInStudent(actorUid);
    final expired = await db.runTransaction((tx) async {
      final roomRef = _room(roomId);
      final requesterRef = _user(requesterUid);
      final requestRef = _request(roomId, requesterUid);
      final roomDoc = await tx.get(roomRef);
      final requesterDoc = await tx.get(requesterRef);
      final requestDoc = await tx.get(requestRef);
      if (!roomDoc.exists || !requesterDoc.exists || !requestDoc.exists) {
        throw const TeamPolicyException(AppStrings.requestMissing);
      }
      final room = _roomFrom(roomDoc);
      final requester = _userFrom(requesterDoc);
      final request = _requestFrom(roomId, requestDoc);
      if (!room.contains(actorUid)) {
        throw const TeamPolicyException(AppStrings.membersApproveOnly);
      }
      if (request.status != 'pending') {
        throw const TeamPolicyException(AppStrings.requestHandled);
      }
      final otherRefs = requester.pendingRequestIds
          .where((id) => id != roomId)
          .map((id) => _request(id, requesterUid))
          .toList();
      final otherDocs = <DocumentSnapshot<Map<String, dynamic>>>[];
      if (approve) {
        for (final ref in otherRefs) {
          otherDocs.add(await tx.get(ref));
        }
      }
      final valid = request.isPendingAt(DateTime.now()) &&
          requester.roomId == null &&
          requester.serverId == room.serverId &&
          !room.locked &&
          !room.isFull;
      if (!valid) {
        tx.update(requestRef, {'status': 'expired', 'decidedBy': actorUid});
        tx.update(requesterRef, {
          'pendingRequestIds':
              requester.pendingRequestIds.where((id) => id != roomId).toList(),
        });
        return true;
      }
      if (!approve) {
        tx.update(requestRef, {'status': 'rejected', 'decidedBy': actorUid});
        tx.update(requesterRef, {
          'pendingRequestIds':
              requester.pendingRequestIds.where((id) => id != roomId).toList(),
        });
        return false;
      }
      tx.update(roomRef, {
        'memberIds': [...room.memberIds, requesterUid]
      });
      tx.update(requesterRef, {
        'roomId': roomId,
        'serverId': room.serverId,
        'pendingRequestIds': <String>[],
      });
      tx.update(requestRef, {'status': 'approved', 'decidedBy': actorUid});
      for (final doc in otherDocs) {
        if (doc.exists && doc.data()?['status'] == 'pending') {
          tx.update(doc.reference, {'status': 'cancelled'});
        }
      }
      return false;
    });
    if (expired) {
      throw const TeamPolicyException(AppStrings.requestExpired);
    }
  }

  @override
  Future<void> cancelRequest(String uid, String roomId) async {
    _requireSignedInStudent(uid);
    await db.runTransaction((tx) async {
      final userRef = _user(uid);
      final requestRef = _request(roomId, uid);
      final userDoc = await tx.get(userRef);
      final requestDoc = await tx.get(requestRef);
      if (!userDoc.exists || !requestDoc.exists) return;
      final request = _requestFrom(roomId, requestDoc);
      if (request.status != 'pending') return;
      final user = _userFrom(userDoc);
      tx.update(requestRef, {'status': 'cancelled'});
      tx.update(userRef, {
        'pendingRequestIds':
            user.pendingRequestIds.where((id) => id != roomId).toList(),
      });
    });
  }

  @override
  Future<void> expireRequest(String roomId, String requesterUid) async {
    await db.runTransaction((tx) async {
      final ref = _request(roomId, requesterUid);
      final doc = await tx.get(ref);
      if (!doc.exists) return;
      final request = _requestFrom(roomId, doc);
      if (request.status == 'pending' &&
          !DateTime.now().isBefore(request.expiresAt)) {
        tx.update(ref, {'status': 'expired'});
      }
    });
  }

  @override
  Future<void> leaveRoom(String uid, String roomId) async {
    _requireSignedInStudent(uid);
    final emptied = await db.runTransaction((tx) async {
      final roomRef = _room(roomId);
      final userRef = _user(uid);
      final voteRef = _vote(roomId);
      final disbandRef = _disband(roomId);
      final roomDoc = await tx.get(roomRef);
      final userDoc = await tx.get(userRef);
      final voteDoc = await tx.get(voteRef);
      final disbandDoc = await tx.get(disbandRef);
      if (!roomDoc.exists || !userDoc.exists) {
        throw const TeamPolicyException(AppStrings.roomOrAccountMissing);
      }
      final room = _roomFrom(roomDoc);
      if (!room.contains(uid)) {
        throw const TeamPolicyException(AppStrings.notInRoom);
      }
      final remaining = room.memberIds.where((id) => id != uid).toList();
      tx.update(userRef, {'roomId': null});
      if (remaining.isEmpty) {
        tx.update(roomRef, {
          'memberIds': <String>[],
          'leaderId': null,
          'locked': false,
          'name': room.defaultName ?? room.name,
          'nameLower': TeamPolicy.normalize(room.defaultName ?? room.name),
        });
        if (voteDoc.exists) tx.delete(voteRef);
        if (disbandDoc.exists) tx.delete(disbandRef);
        return true;
      }
      tx.update(roomRef, {
        'memberIds': remaining,
        if (room.leaderId == uid) 'leaderId': null,
        if (room.leaderId == uid) 'locked': false,
      });
      if (voteDoc.exists) {
        final ballots = Map<String, String>.from(
            voteDoc.data()?['ballots'] as Map? ?? const {});
        final removedVoters = ballots.entries
            .where((entry) => entry.key == uid || entry.value == uid)
            .map((entry) => entry.key)
            .toList();
        ballots.remove(uid);
        ballots.removeWhere((_, candidate) => candidate == uid);
        final data = voteDoc.data()!;
        final active = data['status'] == 'active';
        final expired = active &&
            !DateTime.now().isBefore((data['endsAt'] as Timestamp).toDate());
        final winner = active
            ? TeamPolicy.voteWinner(remaining, ballots, expired: expired)
            : null;
        tx.update(voteRef, {
          'ballots': ballots,
          if (winner != null || expired) 'status': 'finished',
          if (winner != null || expired) 'winnerUid': winner,
        });
        if (winner != null) tx.update(roomRef, {'leaderId': winner});
        for (final voterId in removedVoters) {
          tx.delete(voteRef.collection('ballots').doc(voterId));
        }
      }
      if (disbandDoc.exists) {
        final approved = List<String>.from(
            disbandDoc.data()?['approvedBy'] as List? ?? const []);
        approved.remove(uid);
        tx.update(disbandRef, {'approvedBy': approved});
      }
      return false;
    });
    if (emptied) await cleanupRoomSubcollections(roomId);
  }

  @override
  Future<void> renameRoom(String uid, String roomId, String name) async {
    _requireSignedInStudent(uid);
    final clean = name.trim();
    if (clean.isEmpty) {
      throw const TeamPolicyException(AppStrings.roomNameRequired);
    }
    await db.runTransaction((tx) async {
      final ref = _room(roomId);
      final doc = await tx.get(ref);
      if (!doc.exists || !_roomFrom(doc).contains(uid)) {
        throw const TeamPolicyException(AppStrings.membersRenameOnly);
      }
      tx.update(ref, {'name': clean, 'nameLower': TeamPolicy.normalize(clean)});
    });
  }

  @override
  Future<void> setLocked(String uid, String roomId, bool locked) async {
    _requireSignedInStudent(uid);
    await db.runTransaction((tx) async {
      final ref = _room(roomId);
      final doc = await tx.get(ref);
      if (!doc.exists || _roomFrom(doc).leaderId != uid) {
        throw const TeamPolicyException(AppStrings.leaderLocksOnly);
      }
      tx.update(ref, {'locked': locked});
    });
  }

  @override
  Future<void> startVote(String uid, String roomId) async {
    _requireSignedInStudent(uid);
    await finalizeVote(roomId);
    await db.runTransaction((tx) async {
      final roomRef = _room(roomId);
      final voteRef = _vote(roomId);
      final roomDoc = await tx.get(roomRef);
      final voteDoc = await tx.get(voteRef);
      if (!roomDoc.exists || !_roomFrom(roomDoc).contains(uid)) {
        throw const TeamPolicyException(AppStrings.membersStartVoteOnly);
      }
      if (_roomFrom(roomDoc).leaderId != null) {
        throw const TeamPolicyException(AppStrings.leaderExists);
      }
      final existing = voteDoc.data();
      if (existing?['status'] == 'active' &&
          DateTime.now()
              .isBefore((existing!['endsAt'] as Timestamp).toDate())) {
        throw const TeamPolicyException(AppStrings.voteActiveAlready);
      }
      final now = DateTime.now().toUtc();
      tx.set(voteRef, {
        'startedBy': uid,
        'startedAt': Timestamp.fromDate(now),
        'endsAt': Timestamp.fromDate(now.add(TeamPolicy.voteLifetime)),
        'status': 'active',
        'winnerUid': null,
        'ballots': <String, String>{},
      });
    });
  }

  @override
  Future<void> castVote(String uid, String roomId, String candidateUid) async {
    _requireSignedInStudent(uid);
    await db.runTransaction((tx) async {
      final roomRef = _room(roomId);
      final voteRef = _vote(roomId);
      final roomDoc = await tx.get(roomRef);
      final voteDoc = await tx.get(voteRef);
      if (!roomDoc.exists || !voteDoc.exists) {
        throw const TeamPolicyException(AppStrings.noActiveVote);
      }
      final room = _roomFrom(roomDoc);
      final vote = voteDoc.data()!;
      final endsAt = (vote['endsAt'] as Timestamp).toDate();
      if (vote['status'] != 'active' || !DateTime.now().isBefore(endsAt)) {
        throw const TeamPolicyException(AppStrings.voteExpired);
      }
      if (!room.contains(uid) || !room.contains(candidateUid)) {
        throw const TeamPolicyException(AppStrings.voteCurrentMemberOnly);
      }
      final ballots =
          Map<String, String>.from(vote['ballots'] as Map? ?? const {});
      ballots[uid] = candidateUid;
      final winner =
          TeamPolicy.voteWinner(room.memberIds, ballots, expired: false);
      tx.update(voteRef, {
        'ballots': ballots,
        if (winner != null) 'status': 'finished',
        if (winner != null) 'winnerUid': winner,
      });
      tx.set(voteRef.collection('ballots').doc(uid), {
        'candidateUid': candidateUid,
      });
      if (winner != null) tx.update(roomRef, {'leaderId': winner});
    });
  }

  @override
  Future<void> finalizeVote(String roomId) async {
    await db.runTransaction((tx) async {
      final roomRef = _room(roomId);
      final voteRef = _vote(roomId);
      final roomDoc = await tx.get(roomRef);
      final voteDoc = await tx.get(voteRef);
      if (!roomDoc.exists || !voteDoc.exists) return;
      final vote = voteDoc.data()!;
      if (vote['status'] != 'active' ||
          DateTime.now().isBefore((vote['endsAt'] as Timestamp).toDate())) {
        return;
      }
      final room = _roomFrom(roomDoc);
      final winner = TeamPolicy.voteWinner(
        room.memberIds,
        Map<String, String>.from(vote['ballots'] as Map? ?? const {}),
        expired: true,
      );
      tx.update(voteRef, {'status': 'finished', 'winnerUid': winner});
      if (winner != null && room.leaderId == null) {
        tx.update(roomRef, {'leaderId': winner});
      }
    });
  }

  @override
  Future<void> proposeDisband(String uid, String roomId) async {
    _requireSignedInStudent(uid);
    await db.runTransaction((tx) async {
      final roomDoc = await tx.get(_room(roomId));
      final ref = _disband(roomId);
      final disbandDoc = await tx.get(ref);
      if (!roomDoc.exists || !_roomFrom(roomDoc).contains(uid)) {
        throw const TeamPolicyException(AppStrings.membersProposeDisbandOnly);
      }
      final current = disbandDoc.data();
      if (current?['status'] == 'active' &&
          DateTime.now().isBefore((current!['endsAt'] as Timestamp).toDate())) {
        throw const TeamPolicyException(AppStrings.disbandAlreadyProposed);
      }
      final now = DateTime.now().toUtc();
      tx.set(ref, {
        'requestedBy': uid,
        'createdAt': Timestamp.fromDate(now),
        'endsAt': Timestamp.fromDate(now.add(TeamPolicy.disbandLifetime)),
        'approvedBy': [uid],
        'status': 'active',
      });
    });
    await approveDisband(uid, roomId);
  }

  @override
  Future<void> approveDisband(String uid, String roomId) async {
    _requireSignedInStudent(uid);
    final completed = await db.runTransaction((tx) async {
      final roomRef = _room(roomId);
      final disbandRef = _disband(roomId);
      final roomDoc = await tx.get(roomRef);
      final disbandDoc = await tx.get(disbandRef);
      if (!roomDoc.exists || !disbandDoc.exists) {
        throw const TeamPolicyException(AppStrings.disbandMissing);
      }
      final room = _roomFrom(roomDoc);
      final proposal = disbandDoc.data()!;
      if (!room.contains(uid)) {
        throw const TeamPolicyException(AppStrings.membersVoteOnly);
      }
      if (proposal['status'] != 'active') {
        throw const TeamPolicyException(AppStrings.disbandFinished);
      }
      if (!DateTime.now()
          .isBefore((proposal['endsAt'] as Timestamp).toDate())) {
        tx.update(disbandRef, {'status': 'expired'});
        return false;
      }
      final approvals =
          List<String>.from(proposal['approvedBy'] as List? ?? const []);
      if (!approvals.contains(uid)) approvals.add(uid);
      if (!TeamPolicy.disbandApproved(room.memberIds, approvals)) {
        tx.update(disbandRef, {'approvedBy': approvals});
        return false;
      }
      tx.update(disbandRef, {'approvedBy': approvals, 'status': 'done'});
      tx.update(roomRef, {
        'memberIds': <String>[],
        'leaderId': null,
        'locked': false,
        'name': room.defaultName ?? room.name,
        'nameLower': TeamPolicy.normalize(room.defaultName ?? room.name),
      });
      for (final memberId in room.memberIds) {
        tx.update(_user(memberId), {'roomId': null});
      }
      return true;
    });
    if (completed) await cleanupRoomSubcollections(roomId);
  }

  Future<void> cleanupRoomSubcollections(String roomId) async {
    final roomRef = _room(roomId);
    final requests = await roomRef.collection('joinRequests').get();
    final ballots = await _vote(roomId).collection('ballots').get();
    final refs = <DocumentReference<Map<String, dynamic>>>[
      ...requests.docs.map((doc) => doc.reference),
      ...ballots.docs.map((doc) => doc.reference),
      _vote(roomId),
      _disband(roomId),
    ];
    for (var start = 0;
        start < refs.length;
        start += TeamPolicy.maxBatchWrites) {
      final batch = db.batch();
      for (final ref in refs.skip(start).take(TeamPolicy.maxBatchWrites)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
