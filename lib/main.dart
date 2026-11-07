import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/constants/app_strings.dart';
import 'core/notifications/fcm_background_handler.dart';
import 'core/notifications/notification_runtime.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  const requestedLocalDemo = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  final useLocalDemo = kDebugMode && requestedLocalDemo;
  if (kDebugMode) {
    debugPrint('TeamUp Firebase emulator mode: $useLocalDemo');
  }

  if (!isAndroid) {
    runApp(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(child: Text(AppStrings.androidOnly)),
      ),
    ));
    return;
  }

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    if (useLocalDemo) {
      await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
    }
    if (isAndroid && !useLocalDemo) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        ));
        return true;
      };
    }
  } catch (error) {
    startupError = error.toString();
  }

  runApp(ProviderScope(child: TeamUpApp(startupError: startupError)));
  if (isAndroid && startupError == null && !useLocalDemo) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationRuntime.instance.start(
        router: AppRouter.router,
        messengerKey: appScaffoldMessengerKey,
      ));
    });
  }
}
