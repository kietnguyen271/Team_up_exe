import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/core/theme/app_theme.dart';
import 'package:teamup_exe/shared/widgets/app_shell.dart';
import 'package:teamup_exe/shared/widgets/floating_nav_bar.dart';

void main() {
  Future<void> pumpAtWidth(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AppShell(child: Text('Nội dung')),
      ),
    );
  }

  testWidgets('student shell keeps bottom navigation on a wide Android device',
      (tester) async {
    await pumpAtWidth(tester, 1200);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });

  testWidgets('student shell uses bottom navigation below 600px',
      (tester) async {
    await pumpAtWidth(tester, 390);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(FloatingNavBar), findsOneWidget);
  });
}
