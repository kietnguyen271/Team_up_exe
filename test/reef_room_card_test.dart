import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/core/constants/app_strings.dart';
import 'package:teamup_exe/core/theme/app_theme.dart';
import 'package:teamup_exe/core/theme/app_tokens.dart';
import 'package:teamup_exe/shared/widgets/room_table_card.dart';

void main() {
  for (final capacity in [2, 12]) {
    testWidgets('reef card fits $capacity seats at 1.3 text scale',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: AppSizes.roomTileMin,
                height: AppSizes.roomTileMin / AppSizes.reefCardAspectRatio,
                child: RoomTableCard(
                  name: AppStrings.sampleRoom,
                  members: 1,
                  capacity: capacity,
                  status: AppStrings.roomOpen,
                  isMine: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.yourRoom), findsOneWidget);
      expect(find.text('1/$capacity'), findsOneWidget);
      expect(find.byIcon(Icons.circle), findsOneWidget);
    });
  }

  testWidgets('reef card keeps the room label and tap action', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox.square(
            dimension: AppSizes.studentRoomTileMaxWidth,
            child: RoomTableCard(
              name: AppStrings.sampleRoom,
              members: 2,
              capacity: 5,
              status: AppStrings.roomLocked,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    ));
    expect(
      find.bySemanticsLabel(AppStrings.roomCardSummary(
        AppStrings.sampleRoom,
        2,
        5,
        AppStrings.roomLocked,
      )),
      findsOneWidget,
    );
    await tester.tap(find.byType(RoomTableCard));
    expect(taps, 1);
    semantics.dispose();
  });
}
