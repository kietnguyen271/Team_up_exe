import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../constants/app_strings.dart';
import 'app_user_exception.dart';

abstract final class AppErrorMapper {
  static String message(Object error) {
    if (error is AppUserException) return error.message;
    if (error is FirebaseAuthException) return _authMessage(error.code);
    if (error is FirebaseException) return _serviceMessage(error.code);
    if (error is TimeoutException) return AppStrings.errorTimeout;
    if (error is PlatformException) return _serviceMessage(error.code);
    if (error is FormatException) return AppStrings.errorInvalidInput;
    if (error is StateError) {
      final detail = error.message.toString();
      if (detail == AppStrings.crashNeedsSignIn) {
        return detail;
      }
    }
    return AppStrings.errorUnexpected;
  }

  static String _authMessage(String code) => switch (code) {
        'invalid-email' => AppStrings.errorInvalidEmail,
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' ||
        'invalid-login-credentials' =>
          AppStrings.errorInvalidCredentials,
        'email-already-in-use' => AppStrings.errorEmailAlreadyUsed,
        'weak-password' => AppStrings.errorWeakPassword,
        'user-disabled' => AppStrings.errorAccountDisabled,
        'too-many-requests' => AppStrings.errorTooManyAttempts,
        'requires-recent-login' => AppStrings.errorSignInAgain,
        'network-request-failed' => AppStrings.errorNetwork,
        'operation-not-allowed' => AppStrings.errorAuthUnavailable,
        _ => _serviceMessage(code),
      };

  static String _serviceMessage(String code) => switch (code) {
        'permission-denied' => AppStrings.errorPermissionDenied,
        'unauthenticated' => AppStrings.errorSignInAgain,
        'unavailable' ||
        'network-error' ||
        'network-request-failed' =>
          AppStrings.errorNetwork,
        'deadline-exceeded' || 'timeout' => AppStrings.errorTimeout,
        'not-found' => AppStrings.errorDataMissing,
        'already-exists' => AppStrings.errorAlreadyExists,
        'failed-precondition' || 'aborted' => AppStrings.errorDataChanged,
        'resource-exhausted' => AppStrings.errorServiceBusy,
        'invalid-argument' => AppStrings.errorInvalidInput,
        _ => AppStrings.errorUnexpected,
      };
}
