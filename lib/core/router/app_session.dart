import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SessionStage {
  signedOut,
  unverified,
  needsProfile,
  needsServer,
  student,
  completed,
  admin,
}

abstract interface class AppSession {
  Future<SessionStage> resolve();
}

class FirebaseAppSession implements AppSession {
  FirebaseAppSession({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  @override
  Future<SessionStage> resolve() async {
    final user = auth.currentUser;
    if (user == null) return SessionStage.signedOut;
    if (!user.emailVerified) return SessionStage.unverified;
    final email = user.email?.trim().toLowerCase();
    if (email != null && email.isNotEmpty) {
      final admin = await firestore.collection('admins').doc(email).get();
      if (admin.exists) return SessionStage.admin;
    }
    final profile = await firestore.collection('users').doc(user.uid).get();
    if (!profile.exists) return SessionStage.needsProfile;
    final data = profile.data()!;
    if (data['status'] == 'completed') return SessionStage.completed;
    if ((data['name'] as String? ?? '').trim().isEmpty ||
        (data['bio'] as String? ?? '').trim().isEmpty ||
        (data['skills'] as List? ?? const []).isEmpty) {
      return SessionStage.needsProfile;
    }
    if (data['serverId'] == null) return SessionStage.needsServer;
    return SessionStage.student;
  }
}
