import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../domain/admin_access_service.dart';

class FirebaseAdminAuthGateway implements AdminAuthGateway {
  @override
  Future<AdminIdentity> signIn(String email, String password) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null || user.email == null) {
      throw StateError(AppStrings.firebaseMissingEmail);
    }
    return AdminIdentity(uid: user.uid, email: user.email!);
  }

  @override
  Future<AdminIdentity?> currentIdentity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return null;
    return AdminIdentity(uid: user.uid, email: user.email!);
  }

  @override
  Future<void> signOut() => FirebaseAuth.instance.signOut();
}

class FirestoreAdminDirectory implements AdminDirectory {
  @override
  Future<bool> containsEmail(String emailLowercase) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('admins')
        .doc(emailLowercase)
        .get();
    return snapshot.exists;
  }
}
