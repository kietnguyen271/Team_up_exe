import '../../../core/constants/app_strings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../team/domain/team_models.dart';
import '../../team/domain/team_policy.dart';
import '../domain/rollover_preview.dart';
import '../domain/rollover_engine.dart';

class FirebaseAdminRepository implements RolloverStore {
  FirebaseAdminRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : db = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore db;
  final FirebaseAuth auth;
  String? _rolloverAttemptId;

  Future<void> requireAdmin() async {
    final user = auth.currentUser;
    final email = user?.email?.trim().toLowerCase();
    if (user == null || email == null || email.isEmpty) {
      throw const TeamPolicyException(AppStrings.adminVerifiedRequired);
    }
    final admin = await db.collection('admins').doc(email).get();
    if (!admin.exists || admin.data()?['uid'] != user.uid) {
      throw const TeamPolicyException(AppStrings.adminAccessDenied);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRooms(String serverId) =>
      db.collection('rooms').where('serverId', isEqualTo: serverId).snapshots();

  Future<List<TeamUser>> getRoomMembers(List<String> memberIds) async {
    await requireAdmin();
    final documents = await Future.wait(
        memberIds.map((uid) => db.collection('users').doc(uid).get()));
    return [
      for (final doc in documents)
        if (doc.exists)
          TeamUser(
            id: doc.id,
            name: doc.data()?['name'] as String? ?? '',
            email: doc.data()?['email'] as String? ?? '',
            bio: doc.data()?['bio'] as String? ?? '',
            skills:
                List<String>.from(doc.data()?['skills'] as List? ?? const []),
          )
    ];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDemoEvents() => db
      .collection('crashDemoEvents')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAnnouncements() => db
      .collection('announcements')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPushJobs() => db
      .collection('notificationJobs')
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRollover() =>
      db.collection('rollover').doc('current').snapshots();

  Future<void> createAnnouncement(
      String title, String body, String serverId) async {
    await requireAdmin();
    if (title.trim().isEmpty || body.trim().isEmpty) {
      throw const TeamPolicyException(AppStrings.announcementFieldsRequired);
    }
    if (serverId != 'all' && serverId != 'exe1' && serverId != 'exe2') {
      throw const TeamPolicyException(AppStrings.invalidServer);
    }
    await db.collection('announcements').add({
      'title': title.trim(),
      'body': body.trim(),
      'serverId': serverId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': auth.currentUser!.uid,
    });
  }

  Future<void> queueRoomPush(String title, String body, String roomId) async {
    return queueBroadcastPush(title, body, 'room', roomId);
  }

  Future<void> queueBroadcastPush(
      String title, String body, String targetKind, String targetId) async {
    await requireAdmin();
    final cleanId = targetId.trim();
    if (title.trim().isEmpty ||
        body.trim().isEmpty ||
        !['room', 'server', 'user', 'all'].contains(targetKind) ||
        (targetKind != 'all' && cleanId.isEmpty)) {
      throw const TeamPolicyException(AppStrings.pushFieldsInvalid);
    }
    if (targetKind == 'room') {
      if (!RegExp(r'^[a-zA-Z0-9_.~%-]+$').hasMatch(cleanId)) {
        throw const TeamPolicyException(AppStrings.pushFieldsInvalid);
      }
      final room = await db.collection('rooms').doc(cleanId).get();
      if (!room.exists) {
        throw const TeamPolicyException(AppStrings.roomMissing);
      }
    } else if (targetKind == 'server') {
      if (cleanId != 'exe1' && cleanId != 'exe2') {
        throw const TeamPolicyException(AppStrings.invalidServer);
      }
    } else if (targetKind == 'user') {
      final user = await db.collection('users').doc(cleanId).get();
      if (!user.exists) {
        throw const TeamPolicyException(AppStrings.userOrRoomMissing);
      }
    }
    await db.collection('notificationJobs').add({
      if (targetKind != 'room') 'type': 'broadcast',
      'title': title.trim(),
      'body': body.trim(),
      'targetKind': targetKind,
      'targetId': targetKind == 'all' ? '' : cleanId,
      if (targetKind == 'room') 'roomId': cleanId,
      'status': 'pending',
      'createdBy': auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createRooms(String serverId, int count, int capacity) async {
    await requireAdmin();
    if ((serverId != 'exe1' && serverId != 'exe2') ||
        count <= 0 ||
        count > TeamPolicy.maxBatchWrites ||
        capacity <= 0) {
      throw const TeamPolicyException(AppStrings.roomCountOrCapacityInvalid);
    }
    final existing = await db
        .collection('rooms')
        .where('serverId', isEqualTo: serverId)
        .get();
    final usedNames =
        existing.docs.map((doc) => doc.data()['name'] as String? ?? '').toSet();
    final batch = db.batch();
    var next = 1;
    for (var i = 0; i < count; i++) {
      while (usedNames.contains('Room $next')) {
        next++;
      }
      final name = 'Room $next';
      usedNames.add(name);
      final ref = db.collection('rooms').doc();
      batch.set(ref, {
        'serverId': serverId,
        'name': name,
        'defaultName': name,
        'nameLower': TeamPolicy.normalize(name),
        'capacity': capacity,
        'memberIds': <String>[],
        'leaderId': null,
        'locked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      next++;
    }
    await batch.commit();
  }

  Future<void> renameRoom(String roomId, String name) async {
    await requireAdmin();
    final clean = name.trim();
    if (clean.isEmpty) {
      throw const TeamPolicyException(AppStrings.roomNameRequired);
    }
    await db.collection('rooms').doc(roomId).update({
      'name': clean,
      'nameLower': TeamPolicy.normalize(clean),
    });
  }

  Future<void> editCapacity(String roomId, int capacity) async {
    await requireAdmin();
    await db.runTransaction((tx) async {
      final ref = db.collection('rooms').doc(roomId);
      final doc = await tx.get(ref);
      if (!doc.exists) {
        throw const TeamPolicyException(AppStrings.roomMissing);
      }
      final members = (doc.data()?['memberIds'] as List? ?? const []).length;
      if (capacity < members || capacity <= 0) {
        throw const TeamPolicyException(AppStrings.capacityBelowMembers);
      }
      tx.update(ref, {'capacity': capacity});
    });
  }

  Future<void> deleteEmptyRoom(String roomId) async {
    await requireAdmin();
    await db.runTransaction((tx) async {
      final ref = db.collection('rooms').doc(roomId);
      final doc = await tx.get(ref);
      if (!doc.exists) return;
      if ((doc.data()?['memberIds'] as List? ?? const []).isNotEmpty) {
        throw const TeamPolicyException(AppStrings.deleteEmptyRoomOnly);
      }
      tx.delete(ref);
    });
    await _deleteRoomChildren(roomId);
  }

  Future<List<RoomTemplate>> getTemplate(String serverId) async {
    final doc = await db.collection('servers').doc(serverId).get();
    final rows = doc.data()?['roomTemplate'] as List? ?? const [];
    return rows.map((row) {
      final data = Map<String, dynamic>.from(row as Map);
      return RoomTemplate(
        data['name'] as String? ?? '',
        (data['capacity'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<void> saveTemplate(String serverId, List<RoomTemplate> rooms) async {
    await requireAdmin();
    if ((serverId != 'exe1' && serverId != 'exe2') ||
        rooms.any((room) => room.name.trim().isEmpty || room.capacity <= 0)) {
      throw const TeamPolicyException(AppStrings.templateInvalid);
    }
    await db.collection('servers').doc(serverId).set({
      'name': serverId.toUpperCase(),
      'roomTemplate': [
        for (final room in rooms)
          {'name': room.name.trim(), 'capacity': room.capacity}
      ],
    }, SetOptions(merge: true));
  }

  Future<RolloverPreview> previewRollover() async {
    await requireAdmin();
    final exe1 =
        await db.collection('rooms').where('serverId', isEqualTo: 'exe1').get();
    final exe2 =
        await db.collection('rooms').where('serverId', isEqualTo: 'exe2').get();
    final template = await getTemplate('exe1');
    return RolloverPreview(
      exe2RoomCount: exe2.docs.length,
      exe2StudentCount: exe2.docs.fold(
          0,
          (sum, doc) =>
              sum + (doc.data()['memberIds'] as List? ?? const []).length),
      exe1RoomCount: exe1.docs.length,
      exe1StudentCount: exe1.docs.fold(
          0,
          (sum, doc) =>
              sum + (doc.data()['memberIds'] as List? ?? const []).length),
      renewedExe1RoomCount: template.length,
    );
  }

  Future<void> runRollover() async {
    await requireAdmin();
    final progressRef = db.collection('rollover').doc('current');
    final attemptId =
        '${auth.currentUser!.uid}_${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final claim = await db.runTransaction<(String, String)?>((tx) async {
      final progress = await tx.get(progressRef);
      final data = progress.data();
      final state = data?['state'] as String?;
      if (state == 'done') return null;
      if (state == 'running') {
        final updatedAt = (data?['updatedAt'] as Timestamp?)?.toDate();
        if (updatedAt != null &&
            DateTime.now().difference(updatedAt) < TeamPolicy.rolloverLease) {
          throw const TeamPolicyException(AppStrings.rolloverInProgress);
        }
      }
      if (!progress.exists || state == 'idle') {
        final runId = DateTime.now().toUtc().microsecondsSinceEpoch.toString();
        tx.set(progressRef, {
          'state': 'running',
          'step': 'completeExe2',
          'runId': runId,
          'attemptId': attemptId,
          'startedBy': auth.currentUser!.uid,
          'startedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return (runId, 'completeExe2');
      }
      final runId = data?['runId'] as String?;
      if (runId == null) {
        throw const TeamPolicyException(AppStrings.rolloverIdMissing);
      }
      tx.update(progressRef, {
        'state': 'running',
        'attemptId': attemptId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return (runId, data?['step'] as String? ?? 'completeExe2');
    });
    if (claim == null) return;
    _rolloverAttemptId = attemptId;
    final (runId, step) = claim;
    try {
      await RolloverEngine(this).run(step, runId);
    } catch (_) {
      try {
        await _updateProgress({'state': 'failed'});
      } catch (_) {
        // A new attempt may have taken over the lease.
      }
      rethrow;
    } finally {
      _rolloverAttemptId = null;
    }
  }

  Future<void> prepareNextSemester() async {
    await requireAdmin();
    final ref = db.collection('rollover').doc('current');
    await db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (doc.data()?['state'] != 'done') {
        throw const TeamPolicyException(AppStrings.rolloverNotDone);
      }
      tx.update(ref, {
        'state': 'idle',
        'step': 'idle',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<List<String>> roomIds(String serverId) async {
    final query = await db
        .collection('rooms')
        .where('serverId', isEqualTo: serverId)
        .get();
    return query.docs.map((doc) => doc.id).toList();
  }

  @override
  Future<void> completeExe2Room(String roomId) async {
    final room = await db.collection('rooms').doc(roomId).get();
    if (!room.exists) return;
    await _deleteRoomChildren(room.id);
    final memberIds =
        List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    for (var start = 0;
        start < memberIds.length;
        start += TeamPolicy.maxBatchWrites) {
      final batch = db.batch();
      for (final uid in memberIds.skip(start).take(TeamPolicy.maxBatchWrites)) {
        batch.update(db.collection('users').doc(uid), {
          'status': 'completed',
          'serverId': null,
          'roomId': null,
        });
      }
      await batch.commit();
    }
    await room.reference.delete();
  }

  @override
  Future<void> moveExe1Room(String roomId) async {
    final room = await db.collection('rooms').doc(roomId).get();
    if (!room.exists || room.data()?['serverId'] != 'exe1') return;
    await _deleteRoomChildren(room.id);
    final memberIds =
        List<String>.from(room.data()?['memberIds'] as List? ?? const []);
    for (var start = 0;
        start < memberIds.length;
        start += TeamPolicy.maxBatchWrites) {
      final batch = db.batch();
      for (final uid in memberIds.skip(start).take(TeamPolicy.maxBatchWrites)) {
        batch.update(db.collection('users').doc(uid), {'serverId': 'exe2'});
      }
      await batch.commit();
    }
    await room.reference.update({'serverId': 'exe2'});
  }

  @override
  Future<List<RoomTemplate>> exe1Template() => getTemplate('exe1');

  @override
  Future<void> ensureRenewedRoom(
      String runId, int index, RoomTemplate item) async {
    final roomRef = db.collection('rooms').doc('exe1_${runId}_$index');
    await db.runTransaction((tx) async {
      final existing = await tx.get(roomRef);
      if (existing.exists) return;
      tx.set(roomRef, {
        'serverId': 'exe1',
        'name': item.name,
        'defaultName': item.name,
        'nameLower': TeamPolicy.normalize(item.name),
        'capacity': item.capacity,
        'memberIds': <String>[],
        'leaderId': null,
        'locked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> heartbeat() => _updateProgress(const {});

  @override
  Future<void> setStep(String step) => _updateProgress({'step': step});

  @override
  Future<void> setDone() => _updateProgress({'state': 'done', 'step': 'done'});

  Future<void> _updateProgress(Map<String, dynamic> fields) async {
    final attemptId = _rolloverAttemptId;
    if (attemptId == null) {
      throw const TeamPolicyException(AppStrings.rolloverInProgress);
    }
    final ref = db.collection('rollover').doc('current');
    await db.runTransaction((tx) async {
      final progress = await tx.get(ref);
      if (progress.data()?['attemptId'] != attemptId) {
        throw const TeamPolicyException(AppStrings.rolloverInProgress);
      }
      tx.update(ref, {
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _deleteRoomChildren(String roomId) async {
    final room = db.collection('rooms').doc(roomId);
    final requests = await room.collection('joinRequests').get();
    final vote = room.collection('voteSession').doc('current');
    final ballots = await vote.collection('ballots').get();
    final disband = room.collection('disband').doc('current');
    final refs = <DocumentReference<Map<String, dynamic>>>[
      ...requests.docs.map((doc) => doc.reference),
      ...ballots.docs.map((doc) => doc.reference),
      vote,
      disband,
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
