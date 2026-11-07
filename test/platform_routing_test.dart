import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/core/router/app_router.dart';
import 'package:teamup_exe/core/router/app_session.dart';
import 'package:teamup_exe/core/theme/app_theme.dart';
import 'package:teamup_exe/features/admin/presentation/admin_shell.dart';
import 'package:teamup_exe/features/auth/presentation/auth_form_screen.dart';

class _Session implements AppSession {
  _Session(this.stage);
  SessionStage stage;

  @override
  Future<SessionStage> resolve() async => stage;
}

void main() {
  test('Android role routing sends admins to admin and students to rooms', () {
    expect(AppRouter.routeForStage(SessionStage.admin), '/admin');
    expect(AppRouter.routeForStage(SessionStage.student), '/home');
    expect(AppRouter.routeForStage(SessionStage.needsProfile), '/profile-setup');
    expect(AppRouter.routeForStage(SessionStage.unverified), '/verify-email');
    expect(AppRouter.routeForStage(SessionStage.completed), '/completed');
  });

  testWidgets('signed-out Android user sees login', (tester) async {
    final router = AppRouter.create(isWeb: false, session: _Session(SessionStage.signedOut));
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(AuthFormScreen), findsOneWidget);
  });

  testWidgets('admin shell on a phone uses bottom navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: AdminShell(
        selectedIndex: 0,
        onSignOut: () async {},
        child: const Text('Quản trị'),
      ),
    ));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
