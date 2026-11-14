import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/core/constants/app_strings.dart';
import 'package:teamup_exe/core/errors/app_error_mapper.dart';
import 'package:teamup_exe/core/theme/app_theme.dart';
import 'package:teamup_exe/features/team/domain/team_policy.dart';
import 'package:teamup_exe/shared/widgets/error_notice.dart';

void main() {
  test('authentication errors give an actionable Vietnamese message', () {
    final error = FirebaseAuthException(
      code: 'invalid-credential',
      message: 'Internal auth details',
    );
    expect(AppErrorMapper.message(error), AppStrings.errorInvalidCredentials);
  });

  test('service and policy errors stay safe and specific', () {
    final denied = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
      message: 'Secret document path',
    );
    expect(AppErrorMapper.message(denied), AppStrings.errorPermissionDenied);
    expect(
        AppErrorMapper.message(const TeamPolicyException(
          AppStrings.groupIsFull,
        )),
        AppStrings.groupIsFull);
  });

  test('unknown exceptions do not expose technical details', () {
    expect(
      AppErrorMapper.message(Exception('private server details')),
      AppStrings.errorUnexpected,
    );
  });

  test('push status does not expose a stored server error', () {
    final details = AppStrings.pushJobDetails('failed', 'private server trace');
    expect(details, contains(AppStrings.errorPushFailed));
    expect(details, isNot(contains('private server trace')));
  });

  testWidgets('error notice announces issue and offers retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ErrorNotice.fromError(
          error: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
          ),
          onRetry: () => attempts++,
        ),
      ),
    ));

    expect(find.text(AppStrings.errorTitle), findsOneWidget);
    expect(find.text(AppStrings.errorNetwork), findsOneWidget);
    await tester.tap(find.text(AppStrings.retry));
    expect(attempts, 1);
  });
}
