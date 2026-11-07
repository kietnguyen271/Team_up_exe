import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/core/theme/app_theme.dart';
import 'package:teamup_exe/core/theme/app_tokens.dart';

void main() {
  test('primary token is the specified navy', () {
    expect(AppTheme.light.colorScheme.primary, const Color(0xFF1A3A6B));
  });

  testWidgets('FilledButton meets the minimum touch height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: FilledButton(onPressed: () {}, child: const Text('Chọn')),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(AppSizes.touchTarget),
    );
  });
}
