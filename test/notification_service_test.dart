import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/core/notifications/notification_service.dart';

class _FakeMessaging implements MessagingGateway {
  final refreshes = StreamController<String>.broadcast();
  String? currentToken = 'token-1';
  bool permissionRequested = false;
  bool tokenDeleted = false;
  final subscribed = <String>[];
  final unsubscribed = <String>[];

  @override
  Future<bool> requestPermission() async {
    permissionRequested = true;
    return true;
  }

  @override
  Future<String?> getToken() async => currentToken;

  @override
  Stream<String> get onTokenRefresh => refreshes.stream;

  @override
  Future<void> deleteToken() async => tokenDeleted = true;

  @override
  Future<void> subscribeToTopic(String topic) async => subscribed.add(topic);

  @override
  Future<void> unsubscribeFromTopic(String topic) async =>
      unsubscribed.add(topic);
}

class _FakeStore implements FcmTokenStore {
  final saved = <String>[];
  final replaced = <String>[];
  final removed = <String>[];

  @override
  Future<void> save(String uid, String token) async => saved.add('$uid:$token');

  @override
  Future<void> replace(String uid, String oldToken, String newToken) async =>
      replaced.add('$uid:$oldToken:$newToken');

  @override
  Future<void> remove(String uid, String token) async =>
      removed.add('$uid:$token');
}

void main() {
  test('saves login token, replaces refreshed token, removes it on sign out',
      () async {
    final messaging = _FakeMessaging();
    final store = _FakeStore();
    final service = NotificationService(messaging, store);
    addTearDown(messaging.refreshes.close);

    expect(await service.startForUser('student-1'), 'token-1');
    expect(messaging.permissionRequested, isTrue);
    expect(store.saved, ['student-1:token-1']);

    messaging.refreshes.add('token-2');
    await Future<void>.delayed(Duration.zero);
    expect(store.replaced, ['student-1:token-1:token-2']);
    expect(service.token, 'token-2');

    await service.stopForSignOut();
    expect(store.removed, ['student-1:token-2']);
    expect(messaging.tokenDeleted, isTrue);
  });

  test('room topic actions use room_<id>', () async {
    final messaging = _FakeMessaging();
    final service = NotificationService(messaging, _FakeStore());
    addTearDown(messaging.refreshes.close);

    await service.subscribeToRoom('room-7');
    await service.unsubscribeFromRoom('room-7');
    expect(messaging.subscribed, ['room_room-7']);
    expect(messaging.unsubscribed, ['room_room-7']);
  });
}
