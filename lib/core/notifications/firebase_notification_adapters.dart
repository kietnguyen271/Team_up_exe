import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

class FirebaseMessagingGateway implements MessagingGateway {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}

class FirestoreFcmTokenStore implements FcmTokenStore {
  DocumentReference<Map<String, dynamic>> _document(String uid, String token) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(token);

  @override
  Future<void> save(String uid, String token) async {
    final document = _document(uid, token);
    final existing = await document.get();
    if (existing.exists) {
      await document.update({'updatedAt': FieldValue.serverTimestamp()});
    } else {
      await document.set({
        'token': token,
        'platform': 'android',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Future<void> replace(String uid, String oldToken, String newToken) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_document(uid, newToken), {
      'token': newToken,
      'platform': 'android',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_document(uid, oldToken));
    await batch.commit();
  }

  @override
  Future<void> remove(String uid, String token) =>
      _document(uid, token).delete();
}
