import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/app.dart';
import 'package:teamup_exe/core/constants/app_strings.dart';
import 'package:teamup_exe/core/router/app_router.dart';
import 'package:teamup_exe/core/router/app_session.dart';
import 'package:teamup_exe/core/theme/app_theme.dart';
import 'package:teamup_exe/features/debug_firebase/presentation/debug_firebase_screen.dart';

class _SignedOutSession implements AppSession {
  @override
  Future<SessionStage> resolve() async => SessionStage.signedOut;
}

void main() {
  testWidgets('login opens the debug-only Firebase route', (tester) async {
    final router = AppRouter.create(isWeb: false, session: _SignedOutSession());
    addTearDown(router.dispose);
    await tester.pumpWidget(TeamUpApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.firebaseDebug));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.firebaseInitialize), findsOneWidget);
  });

  testWidgets('debug Firebase screen renders without initializing Firebase',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const DebugFirebaseScreen()),
    );

    expect(find.text(AppStrings.firebaseInitialize), findsOneWidget);
    expect(find.text(AppStrings.firebaseNoLog), findsOneWidget);
    expect(find.text(AppStrings.firebaseNoResults), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('failed action offers retry and preserves credentials',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const DebugFirebaseScreen()),
    );
    await tester.enterText(find.byType(TextField).first, 'student@fpt.edu.vn');
    await tester.enterText(find.byType(TextField).at(1), 'test-password');
    await tester.ensureVisible(find.text(AppStrings.firebaseRead));
    await tester.tap(find.text(AppStrings.firebaseRead));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.retry), findsOneWidget);
    expect(
        find.textContaining(AppStrings.firebaseNotInitialized), findsWidgets);
    expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        'student@fpt.edu.vn');
    expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller?.text,
        'test-password');
  });
}
