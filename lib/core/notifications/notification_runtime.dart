import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';
import '../errors/app_error_mapper.dart';
import '../../features/team/domain/team_policy.dart';
import 'firebase_notification_adapters.dart';
import 'notification_service.dart';

class NotificationRuntime {
  NotificationRuntime._()
      : service = NotificationService(
          FirebaseMessagingGateway(),
          FirestoreFcmTokenStore(),
        );

  static final instance = NotificationRuntime._();

  final NotificationService service;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _profileSubscription;
  String? _currentRoomId;
  String? _activeUid;
  Future<void> _authQueue = Future<void>.value();
  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  GoRouter? _router;

  Future<void> start({
    required GoRouter router,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    _router = router;
    _messengerKey = messengerKey;
    _authSubscription ??= FirebaseAuth.instance.userChanges().listen((user) {
      _authQueue = _authQueue
          .then((_) => _handleUserChange(user))
          .catchError((Object error) => _showError(error));
    });
    _foregroundSubscription ??=
        FirebaseMessaging.onMessage.listen(_showForegroundMessage);
    _openedSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen(_openRoomFromMessage);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _openRoomFromMessage(initialMessage);
  }

  Future<void> _handleUserChange(User? user) async {
    if (user == null || !TeamPolicy.validEmail(user.email ?? '')) {
      await beforeSignOut();
      return;
    }
    if (_activeUid == user.uid) return;
    if (_activeUid != null) await beforeSignOut();
    _activeUid = user.uid;
    await service.startForUser(user.uid);
    await _profileSubscription?.cancel();
    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((profile) {
      final roomId = profile.data()?['roomId'] as String?;
      unawaited(_syncRoomTopic(roomId).catchError(_showError));
    }, onError: (Object error) => _showError(error));
  }

  Future<void> beforeSignOut() async {
    _activeUid = null;
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    await _syncRoomTopic(null);
    await service.stopForSignOut();
  }

  Future<void> _syncRoomTopic(String? roomId) async {
    if (roomId == _currentRoomId) return;
    final oldRoom = _currentRoomId;
    if (oldRoom != null) await service.unsubscribeFromRoom(oldRoom);
    _currentRoomId = roomId;
    if (roomId != null) await service.subscribeToRoom(roomId);
  }

  void _showError(Object error) {
    final messenger = _messengerKey?.currentState;
    if (messenger == null) return;
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(MaterialBanner(
      leading: const Icon(Icons.error_outline),
      content: Text(AppErrorMapper.message(error)),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text(AppStrings.close),
        ),
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null)
              unawaited(service.startForUser(uid).catchError(_showError));
          },
          child: const Text(AppStrings.retry),
        ),
      ],
    ));
  }

  void _showForegroundMessage(RemoteMessage message) {
    final messenger = _messengerKey?.currentState;
    if (messenger == null) return;
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(MaterialBanner(
      leading: const Icon(Icons.notifications_outlined),
      content: Text(message.notification?.body ?? AppStrings.newNotification),
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: const Text(AppStrings.close),
        ),
      ],
    ));
  }

  void _openRoomFromMessage(RemoteMessage message) {
    final roomId = message.data['roomId'];
    if (roomId == null || roomId.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router?.go('/rooms/${Uri.encodeComponent(roomId)}');
    });
  }
}
