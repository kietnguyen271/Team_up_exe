import 'dart:async';

import '../constants/app_strings.dart';

abstract interface class MessagingGateway {
  Future<bool> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Future<void> deleteToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
}

abstract interface class FcmTokenStore {
  Future<void> save(String uid, String token);
  Future<void> replace(String uid, String oldToken, String newToken);
  Future<void> remove(String uid, String token);
}

class NotificationService {
  NotificationService(this.gateway, this.store, {this.onError});

  final MessagingGateway gateway;
  final FcmTokenStore store;
  final void Function(Object error)? onError;
  StreamSubscription<String>? _refreshSubscription;
  String? _uid;
  String? _token;

  String? get token => _token;

  Future<bool> requestPermission() => gateway.requestPermission();

  Future<String?> startForUser(String uid) async {
    if (_uid == uid && _refreshSubscription != null) return _token;
    await _refreshSubscription?.cancel();
    _uid = uid;
    await gateway.requestPermission();
    final token = await gateway.getToken();
    if (token != null && token.isNotEmpty) {
      await store.save(uid, token);
      _token = token;
    }
    _refreshSubscription = gateway.onTokenRefresh.listen((newToken) {
      unawaited(_saveRefreshedToken(newToken).catchError((Object error) {
        onError?.call(error);
      }));
    });
    return _token;
  }

  Future<void> _saveRefreshedToken(String newToken) async {
    final uid = _uid;
    if (uid == null || newToken.isEmpty || newToken == _token) return;
    final oldToken = _token;
    if (oldToken == null) {
      await store.save(uid, newToken);
    } else {
      await store.replace(uid, oldToken, newToken);
    }
    _token = newToken;
  }

  Future<void> stopForSignOut() async {
    if (_uid == null && _token == null && _refreshSubscription == null) return;
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
    final uid = _uid;
    final token = _token;
    if (uid != null && token != null) await store.remove(uid, token);
    await gateway.deleteToken();
    _uid = null;
    _token = null;
  }

  Future<void> forgetLocalSession() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
    _uid = null;
    _token = null;
  }

  Future<void> subscribeToRoom(String roomId) =>
      gateway.subscribeToTopic(_topic(roomId));

  Future<void> unsubscribeFromRoom(String roomId) =>
      gateway.unsubscribeFromTopic(_topic(roomId));

  String _topic(String roomId) {
    final value = roomId.trim();
    if (value.isEmpty || !RegExp(r'^[a-zA-Z0-9_.~%-]+$').hasMatch(value)) {
      throw FormatException(AppStrings.invalidRoomId);
    }
    return 'room_$value';
  }
}
