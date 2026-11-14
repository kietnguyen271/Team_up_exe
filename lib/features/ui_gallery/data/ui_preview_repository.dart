import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../../../shared/widgets/seat_avatar.dart';
import '../../../shared/widgets/status_chip.dart';

enum UiPreviewState {
  data,
  loading,
  empty,
  error,
  success,
  denied,
  processing,
  confirm,
}

class PreviewRoom {
  const PreviewRoom({
    required this.id,
    required this.name,
    required this.capacity,
    required this.members,
    required this.status,
    this.isMine = false,
  });

  final String id;
  final String name;
  final int capacity;
  final List<SeatMember> members;
  final RoomStatus status;
  final bool isMine;
}

class PreviewEvent {
  const PreviewEvent(this.title, this.status);
  final String title;
  final String status;
}

class PreviewProfile {
  const PreviewProfile(this.name, this.bio, this.skills);
  final String name;
  final String bio;
  final List<String> skills;
}

abstract interface class UiPreviewRepository {
  Future<List<PreviewRoom>> rooms(UiPreviewState state);
  Future<List<PreviewEvent>> notifications(UiPreviewState state);
}

class FakeUiPreviewRepository implements UiPreviewRepository {
  const FakeUiPreviewRepository();

  static const members = <SeatMember>[
    SeatMember(id: 'an', name: AppStrings.uiSeedAn, isLeader: true),
    SeatMember(id: 'binh', name: AppStrings.uiSeedBinh, isSelf: true),
    SeatMember(id: 'chi', name: AppStrings.uiSeedChi),
    SeatMember(id: 'dung', name: AppStrings.uiSeedDung),
    SeatMember(id: 'huyen', name: AppStrings.uiSeedHuyen),
    SeatMember(id: 'khoa', name: AppStrings.uiSeedKhoa),
    SeatMember(id: 'linh', name: AppStrings.uiSeedLinh),
    SeatMember(id: 'minh', name: AppStrings.uiSeedMinh),
  ];
  static const profiles = <PreviewProfile>[
    PreviewProfile(AppStrings.uiSeedAn, AppStrings.uiSeedBackendBio,
        [AppStrings.uiSkillBackend, AppStrings.uiSkillDatabase]),
    PreviewProfile(AppStrings.uiSeedBinh, AppStrings.uiSeedFrontendBio,
        [AppStrings.uiSkillFrontend, AppStrings.uiSkillTesting]),
  ];
  static const servers = <String>[AppStrings.exe1, AppStrings.exe2];

  static final seedRooms = <PreviewRoom>[
    PreviewRoom(
        id: 'empty',
        name: AppStrings.uiSeedRoom1,
        capacity: 5,
        members: [],
        status: RoomStatus.empty),
    PreviewRoom(
        id: 'open',
        name: AppStrings.uiSeedRoom3,
        capacity: 5,
        members: [members[0], members[1]],
        status: RoomStatus.open),
    PreviewRoom(
        id: 'full',
        name: AppStrings.uiSeedRoom5,
        capacity: 5,
        members: [members[0], members[1], members[2], members[3], members[4]],
        status: RoomStatus.full),
    PreviewRoom(
        id: 'locked',
        name: AppStrings.uiSeedRoom8,
        capacity: 4,
        members: [members[0], members[2]],
        status: RoomStatus.locked),
    PreviewRoom(
        id: 'mine',
        name: AppStrings.uiSeedMyRoom,
        capacity: 6,
        members: [members[0], members[1], members[2]],
        status: RoomStatus.open,
        isMine: true),
    PreviewRoom(
        id: 'large',
        name: AppStrings.uiSeedLargeRoom,
        capacity: 8,
        members: members,
        status: RoomStatus.full),
  ];

  static const joinRequests = <PreviewEvent>[
    PreviewEvent(AppStrings.uiSeedAn, AppStrings.requestPending),
    PreviewEvent(AppStrings.uiSeedBinh, AppStrings.uiSeedApproved),
    PreviewEvent(AppStrings.uiSeedChi, AppStrings.uiSeedRejected),
    PreviewEvent(AppStrings.uiSeedDung, AppStrings.uiSeedExpired),
  ];
  static const vote = <PreviewEvent>[
    PreviewEvent(AppStrings.uiSeedAn, AppStrings.uiSeedTwoVotes),
    PreviewEvent(AppStrings.uiSeedBinh, AppStrings.uiSeedOneVote),
  ];
  static const disband =
      PreviewEvent(AppStrings.disbandRoom, AppStrings.uiSeedTwoOfFive);
  static const rollover = <PreviewEvent>[
    PreviewEvent(AppStrings.semester, AppStrings.uiSeedReady),
    PreviewEvent(AppStrings.semester, AppStrings.uiSeedRunning),
    PreviewEvent(AppStrings.semester, AppStrings.uiSeedDone),
    PreviewEvent(AppStrings.semester, AppStrings.uiSeedFailed),
  ];
  static const pushJobs = <PreviewEvent>[
    PreviewEvent(AppStrings.uiSeedRoom3, AppStrings.uiSeedPending),
    PreviewEvent(AppStrings.exe1, AppStrings.uiSeedSending),
    PreviewEvent(AppStrings.pushUser, AppStrings.uiSeedSent),
    PreviewEvent(AppStrings.uiSeedAll, AppStrings.uiSeedPushFailed),
  ];
  static const crashEvents = <PreviewEvent>[
    PreviewEvent(AppStrings.crashTestException, AppStrings.uiSeedAndroid),
  ];
  static const announcements = <PreviewEvent>[
    PreviewEvent(
        AppStrings.uiSeedAnnouncement, AppStrings.uiSeedAnnouncementBody),
  ];

  Future<List<T>> _load<T>(UiPreviewState state, List<T> data) async {
    await Future<void>.delayed(state == UiPreviewState.loading
        ? MotionTokens.celebration
        : MotionTokens.micro);
    if (state == UiPreviewState.error) throw StateError('mock-load-failed');
    if (state == UiPreviewState.empty) return <T>[];
    return data;
  }

  @override
  Future<List<PreviewRoom>> rooms(UiPreviewState state) =>
      _load(state, seedRooms);

  @override
  Future<List<PreviewEvent>> notifications(UiPreviewState state) =>
      _load(state, announcements);
}

final uiPreviewRepositoryProvider = Provider<UiPreviewRepository>(
  (ref) => const FakeUiPreviewRepository(),
);

final previewRoomsProvider =
    FutureProvider.family<List<PreviewRoom>, UiPreviewState>(
  (ref, state) => ref.watch(uiPreviewRepositoryProvider).rooms(state),
);
