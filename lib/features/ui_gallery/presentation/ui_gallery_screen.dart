import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/confirm_dialogs.dart';
import '../../../shared/widgets/form_ornaments.dart';
import '../../../shared/widgets/floating_nav_bar.dart';
import '../../../shared/widgets/gradient_hero.dart';
import '../../../shared/widgets/motion_widgets.dart';
import '../../../shared/widgets/room_tile.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/toast_service.dart';
import '../../../shared/widgets/ui_states.dart';
import 'ocean_gallery_screen.dart';
import '../data/ui_preview_repository.dart';

class UiGalleryScreen extends ConsumerStatefulWidget {
  const UiGalleryScreen({super.key});

  @override
  ConsumerState<UiGalleryScreen> createState() => _UiGalleryScreenState();
}

class _UiGalleryScreenState extends ConsumerState<UiGalleryScreen> {
  UiPreviewState _state = UiPreviewState.data;
  int _navIndex = 0;
  bool _celebrate = false;
  final _bioController = TextEditingController();
  final _skills = <String>{};

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(previewRoomsProvider(_state));
    final scheme = Theme.of(context).colorScheme;
    final previewGroups = <String, List<PreviewEvent>>{
      AppStrings.uiMockRequests: FakeUiPreviewRepository.joinRequests,
      AppStrings.uiMockVotes: FakeUiPreviewRepository.vote,
      AppStrings.uiMockDisband: [FakeUiPreviewRepository.disband],
      AppStrings.uiMockRollover: FakeUiPreviewRepository.rollover,
      AppStrings.uiMockPush: FakeUiPreviewRepository.pushJobs,
      AppStrings.uiMockCrash: FakeUiPreviewRepository.crashEvents,
    };
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.uiGallery)),
      bottomNavigationBar: FloatingNavBar(
        destinations: const [
          FloatingNavDestination(
              icon: Icons.meeting_room_rounded, label: AppStrings.rooms),
          FloatingNavDestination(
              icon: Icons.notifications_rounded,
              label: AppStrings.notifications,
              badge: 3),
          FloatingNavDestination(
              icon: Icons.person_rounded, label: AppStrings.profile),
        ],
        selectedIndex: _navIndex,
        onSelected: (index) => setState(() => _navIndex = index),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const GradientHero(
              title: AppStrings.uiGallery,
              subtitle: AppStrings.uiGalleryIntro,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MotionPageSwitcher(
                    child: Text(
                      [
                        AppStrings.rooms,
                        AppStrings.notifications,
                        AppStrings.profile,
                      ][_navIndex],
                      key: ValueKey(_navIndex),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings:
                            const RouteSettings(name: '/ui-gallery/ocean'),
                        builder: (_) => const OceanGalleryScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.waves_outlined),
                    label: const Text(AppStrings.oceanGallery),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(AppStrings.uiState,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (final state in UiPreviewState.values)
                        ChoiceChip(
                          label:
                              Text(AppStrings.uiPreviewStateLabel(state.name)),
                          selected: _state == state,
                          onSelected: (_) => setState(() => _state = state),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Text(AppStrings.uiRoomExamples,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.s16),
                  if (_state == UiPreviewState.denied)
                    const PermissionDenied()
                  else if (_state == UiPreviewState.loading)
                    const Row(children: [
                      Expanded(child: RoomTileSkeleton()),
                      SizedBox(width: AppSpacing.s8),
                      Expanded(child: RoomTileSkeleton()),
                    ])
                  else
                    LoadingOverlay(
                      loading: _state == UiPreviewState.processing,
                      child: rooms.when(
                        loading: () => const Row(children: [
                          Expanded(child: RoomTileSkeleton()),
                          SizedBox(width: AppSpacing.s8),
                          Expanded(child: RoomTileSkeleton()),
                        ]),
                        error: (_, __) => ErrorState(
                          onRetry: () =>
                              setState(() => _state = UiPreviewState.data),
                        ),
                        data: (items) => items.isEmpty
                            ? const EmptyState()
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent:
                                      AppSizes.studentRoomTileMaxWidth,
                                  crossAxisSpacing: AppSpacing.s8,
                                  mainAxisSpacing: AppSpacing.s8,
                                  childAspectRatio: 1,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final room = items[index];
                                  return StaggeredEntrance(
                                    index: index,
                                    child: RoomTile(
                                      id: room.id,
                                      name: room.name,
                                      capacity: room.capacity,
                                      members: room.members,
                                      status: room.status,
                                      isMine: room.isMine,
                                      animateIdle: index == 1,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                _RoomPreview(room: room),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  if (_state == UiPreviewState.success) ...[
                    const SizedBox(height: AppSpacing.s16),
                    const AnimatedCheck(),
                  ],
                  if (_state == UiPreviewState.confirm) ...[
                    const SizedBox(height: AppSpacing.s16),
                    FilledButton(
                      onPressed: () => ConfirmDialog.show(
                        context,
                        title: AppStrings.uiStateConfirm,
                        message: AppStrings.uiDemoConfirm,
                      ),
                      child: const Text(AppStrings.uiDemoAction),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  Text(AppStrings.uiComponents,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.s16),
                  const Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      StatusChip(status: RoomStatus.empty),
                      StatusChip(status: RoomStatus.open),
                      StatusChip(status: RoomStatus.full),
                      StatusChip(status: RoomStatus.locked),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  const MemberRowSkeleton(),
                  const SizedBox(height: AppSpacing.s16),
                  Row(
                    children: [
                      Text(AppStrings.uiSeatCount,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(width: AppSpacing.s8),
                      CountUpText(
                        value: FakeUiPreviewRepository.seedRooms.length,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  FocusGlowField(
                    label: AppStrings.bio,
                    maxLength: AppLimits.bioMax,
                    controller: _bioController,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: AppSpacing.s8,
                    children: [
                      for (final skill in const [
                        AppStrings.uiSkillBackend,
                        AppStrings.uiSkillFrontend,
                      ])
                        SkillChoiceChip(
                          label: skill,
                          selected: _skills.contains(skill),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _skills.add(skill);
                            } else {
                              _skills.remove(skill);
                            }
                          }),
                        ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () => TypedConfirmDialog.show(
                      context,
                      title: AppStrings.finishSemester,
                      instruction: AppStrings.uiTypedInstruction,
                      expected: AppStrings.rolloverConfirmation,
                    ),
                    child: const Text(AppStrings.finishSemester),
                  ),
                  ConfettiBurst(
                    celebrate: _celebrate,
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() => _celebrate = !_celebrate);
                        ToastService.show(context, AppStrings.uiDemoToast);
                      },
                      icon: const Icon(Icons.celebration_rounded),
                      label: const Text(AppStrings.uiDemoAction),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text(AppStrings.uiReduceMotion),
                    value: Motion.settings.reduced,
                    onChanged: Motion.settings.setReduced,
                  ),
                  ExpansionTile(
                    title: const Text(AppStrings.uiMockMembers),
                    children: [
                      for (final profile in FakeUiPreviewRepository.profiles)
                        ListTile(
                          title: Text(profile.name),
                          subtitle: Text(
                            '${profile.bio}\n${profile.skills.join(', ')}',
                          ),
                        ),
                    ],
                  ),
                  for (final group in previewGroups.entries)
                    ExpansionTile(
                      title: Text(group.key),
                      children: [
                        for (final event in group.value)
                          ListTile(
                            title: Text(event.title),
                            subtitle: Text(event.status),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.s24),
                  Text(AppStrings.uiScreenList,
                      style: Theme.of(context).textTheme.titleLarge),
                  for (final name in AppStrings.uiMockScreens)
                    ListTile(
                      title: Text(name),
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: Text(name)),
                            body: const EmptyState(
                                message: AppStrings.uiComingLater),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomPreview extends StatelessWidget {
  const _RoomPreview({required this.room});
  final PreviewRoom room;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.uiRoomOpenDetails)),
        body: SingleChildScrollView(
          child: Column(
            children: [
              GradientHero(title: room.name),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.adminRoomTileMaxWidth,
                      ),
                      child: RoomTile(
                        id: room.id,
                        name: room.name,
                        capacity: room.capacity,
                        members: room.members,
                        status: room.status,
                        isMine: room.isMine,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    for (final member in room.members)
                      ListTile(
                        leading: Icon(Icons.person_rounded,
                            color: Theme.of(context).colorScheme.primary),
                        title: Text(member.name),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
