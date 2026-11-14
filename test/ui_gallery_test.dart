import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/core/constants/app_strings.dart';
import 'package:teamup_exe/core/theme/app_theme.dart';
import 'package:teamup_exe/core/theme/app_tokens.dart';
import 'package:teamup_exe/features/ui_gallery/data/ui_preview_repository.dart';
import 'package:teamup_exe/features/ui_gallery/presentation/ui_gallery_screen.dart';
import 'package:teamup_exe/shared/widgets/confirm_dialogs.dart';
import 'package:teamup_exe/shared/widgets/floating_nav_bar.dart';
import 'package:teamup_exe/shared/widgets/form_ornaments.dart';
import 'package:teamup_exe/shared/widgets/motion_widgets.dart';
import 'package:teamup_exe/shared/widgets/room_tile.dart';
import 'package:teamup_exe/shared/widgets/status_chip.dart';

void main() {
  test('fake repository can supply data, empty and error states', () async {
    const repository = FakeUiPreviewRepository();
    expect(await repository.rooms(UiPreviewState.data), hasLength(6));
    expect(await repository.rooms(UiPreviewState.empty), isEmpty);
    await expectLater(repository.rooms(UiPreviewState.error), throwsStateError);
  });

  Future<void> pumpTile(WidgetTester tester, PreviewRoom room) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: AppSizes.roomTileMin,
            child: RoomTile(
              id: room.id,
              name: room.name,
              capacity: room.capacity,
              members: room.members,
              status: room.status,
              isMine: room.isMine,
              onTap: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  for (final room in FakeUiPreviewRepository.seedRooms.take(5)) {
    testWidgets('room tile announces ${room.id} occupancy and status',
        (tester) async {
      await pumpTile(tester, room);
      final status = switch (room.status) {
        RoomStatus.empty => AppStrings.roomEmpty,
        RoomStatus.open => AppStrings.roomOpen,
        RoomStatus.full => AppStrings.roomFull,
        RoomStatus.locked => AppStrings.roomLocked,
      };
      final label = AppStrings.roomTileSemantics(
        room.name,
        room.members.length,
        room.capacity,
        status,
        isMine: room.isMine,
      );
      expect(find.bySemanticsLabel(label), findsOneWidget);
      if (room.isMine) {
        expect(
            find.byWidgetPredicate((widget) =>
                widget is Banner && widget.message == AppStrings.yourRoom),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('buttons and icon buttons have at least 48 dp hit areas',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Column(children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add_rounded)),
          FilledButton(onPressed: () {}, child: const Text(AppStrings.save)),
          OutlinedButton(
              onPressed: () {}, child: const Text(AppStrings.cancel)),
          TextButton(onPressed: () {}, child: const Text(AppStrings.confirm)),
        ]),
      ),
    ));
    for (final type in [IconButton, FilledButton, OutlinedButton, TextButton]) {
      final size = tester.getSize(find.byType(type));
      expect(size.width, greaterThanOrEqualTo(AppSizes.touchTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.touchTarget));
    }
  });

  testWidgets('room tile receives taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: AppSizes.roomTileMin,
            child: RoomTile(
              id: 'tap',
              name: AppStrings.uiExampleName,
              capacity: 5,
              members: const [],
              status: RoomStatus.empty,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(RoomTile));
    expect(taps, 1);
  });

  for (final capacity in [2, 12]) {
    testWidgets('room tile fits $capacity seats', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: AppSizes.roomTileMin,
              child: RoomTile(
                id: 'capacity-$capacity',
                name: AppStrings.uiExampleName,
                capacity: capacity,
                members: const [],
                status: RoomStatus.empty,
              ),
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('four admin destinations fit and remain tappable at 390 dp',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var selected = -1;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Scaffold(
          bottomNavigationBar: FloatingNavBar(
            destinations: const [
              FloatingNavDestination(
                  icon: Icons.meeting_room_rounded, label: AppStrings.rooms),
              FloatingNavDestination(
                  icon: Icons.event_rounded, label: AppStrings.semester),
              FloatingNavDestination(
                  icon: Icons.notifications_rounded,
                  label: AppStrings.notifications),
              FloatingNavDestination(
                  icon: Icons.bug_report_rounded, label: AppStrings.demoLog),
            ],
            selectedIndex: 0,
            onSelected: (index) => selected = index,
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    for (final element in find.byType(InkWell).evaluate()) {
      final size = tester.getSize(find.byElementPredicate((e) => e == element));
      expect(size.width, greaterThanOrEqualTo(AppSizes.touchTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizes.touchTarget));
    }
    await tester.tap(find.text(AppStrings.demoLog));
    expect(selected, 3);
  });

  testWidgets('skill chip and profile counter keep accessible sizes',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Column(children: [
          FocusGlowField(
            label: AppStrings.bio,
            controller: controller,
            maxLength: AppLimits.bioMax,
          ),
          SkillChoiceChip(
            label: AppStrings.uiSkillBackend,
            selected: true,
            onSelected: (_) {},
          ),
        ]),
      ),
    ));
    expect(tester.getSize(find.byType(FilterChip)).height,
        greaterThanOrEqualTo(AppSizes.touchTarget));
    await tester.enterText(
        find.byType(TextField), List.filled(250, 'a').join());
    await tester.pump();
    expect(find.text('250/${AppLimits.bioMax}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion skips stagger and confetti', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Column(children: [
            StaggeredEntrance(index: 2, child: Text(AppStrings.rooms)),
            ConfettiBurst(
                celebrate: true, child: Text(AppStrings.uiStateSuccess)),
          ]),
        ),
      ),
    ));
    expect(find.byType(Animate), findsNothing);
    expect(find.byType(ConfettiWidget), findsNothing);
  });

  testWidgets('room preview and dialogs fit at 1.3 text scale', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: UiGalleryScreen(),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(RoomTile), findsWidgets);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -550),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(RoomTile).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.uiRoomOpenDetails), findsOneWidget);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => ConfirmDialog.show(
                context,
                title: AppStrings.uiStateConfirm,
                message: AppStrings.uiDemoConfirm,
              ),
              child: const Text(AppStrings.uiDemoAction),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.cancel), findsOneWidget);
    expect(
        find.widgetWithText(FilledButton, AppStrings.confirm), findsOneWidget);
  });

  testWidgets('typed confirmation stays disabled until exact text matches',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => TypedConfirmDialog.show(
                context,
                title: AppStrings.finishSemester,
                instruction: AppStrings.uiTypedInstruction,
                expected: AppStrings.rolloverConfirmation,
              ),
              child: const Text(AppStrings.uiDemoAction),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final confirm = find.widgetWithText(FilledButton, AppStrings.confirm);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'SAI');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.enterText(
        find.byType(TextField), AppStrings.rolloverConfirmation);
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
