import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/ocean/ocean_glass_panel.dart';
import '../../../shared/ocean/reef_hero_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_notice.dart';
import '../../../shared/widgets/room_table_card.dart';
import '../../team/data/firebase_team_repository.dart';
import '../../team/domain/team_models.dart';
import '../../team/domain/team_policy.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = FirebaseTeamRepository();
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return AppShell(
      openOcean: true,
      child: uid == null
          ? const Center(
              child: OceanGlassPanel(
                child: ErrorNotice(message: AppStrings.firebaseNotSignedIn),
              ),
            )
          : StreamBuilder<TeamUser?>(
              stream: _repository.watchUser(uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return Center(
                    child: OceanGlassPanel(
                      child: ErrorNotice.fromError(
                        error: userSnapshot.error!,
                        onRetry: () => setState(() {}),
                      ),
                    ),
                  );
                }
                if (!userSnapshot.hasData) {
                  return const Center(
                    child: OceanGlassPanel(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final user = userSnapshot.data!;
                final serverId = user.serverId;
                if (serverId == null) {
                  return Center(
                    child: OceanGlassPanel(
                      child: FilledButton(
                        onPressed: () => context.go('/servers'),
                        child: const Text(AppStrings.chooseServer),
                      ),
                    ),
                  );
                }
                final heroHeight = (MediaQuery.sizeOf(context).height *
                        AppSizes.reefHeroFraction)
                    .clamp(
                      AppSizes.reefHeroMinExpandedHeight,
                      AppSizes.reefHeroMaxExpandedHeight,
                    )
                    .toDouble();
                return CustomScrollView(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: ReefHeroHeader(
                        title:
                            '${AppStrings.rooms} · ${serverId.toUpperCase()}',
                        expandedHeight: heroHeight,
                        onSwitchServer: () => context.go('/servers'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s16,
                          AppSpacing.s16,
                          AppSpacing.s16,
                          AppSpacing.s8,
                        ),
                        child: OceanGlassPanel(
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: AppStrings.searchRooms,
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (user.roomId != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.s16,
                            AppSpacing.s8,
                            AppSpacing.s16,
                            AppSpacing.s8,
                          ),
                          child: StreamBuilder<List<TeamJoinRequest>>(
                            stream: _repository.watchRequests(user.roomId!),
                            builder: (context, snapshot) {
                              final pending = snapshot.data
                                      ?.where((request) =>
                                          request.isPendingAt(DateTime.now()))
                                      .length ??
                                  0;
                              return OceanGlassPanel(
                                padding: EdgeInsets.zero,
                                child: ListTile(
                                  leading: const Icon(
                                      Icons.pending_actions_outlined),
                                  title: const Text(AppStrings.joinRequests),
                                  subtitle: Text(snapshot.hasError
                                      ? AppErrorMapper.message(snapshot.error!)
                                      : snapshot.hasData
                                          ? AppStrings.pendingJoinRequests(
                                              pending)
                                          : AppStrings.loading),
                                  trailing:
                                      const Icon(Icons.chevron_right_rounded),
                                  onTap: () =>
                                      context.go('/rooms/${user.roomId}'),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    StreamBuilder<List<TeamRoom>>(
                      stream: _repository.watchRooms(serverId),
                      builder: (context, roomSnapshot) {
                        if (roomSnapshot.hasError) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: OceanGlassPanel(
                                child: ErrorNotice.fromError(
                                  error: roomSnapshot.error!,
                                  onRetry: () => setState(() {}),
                                ),
                              ),
                            ),
                          );
                        }
                        if (!roomSnapshot.hasData) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: OceanGlassPanel(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          );
                        }
                        final search = TeamPolicy.normalize(_search.text);
                        final rooms = roomSnapshot.data!
                            .where((room) =>
                                TeamPolicy.canSeeRoom(user, room) &&
                                TeamPolicy.normalize(room.name)
                                    .contains(search))
                            .toList();
                        if (rooms.isEmpty) {
                          final message = roomSnapshot.data!.isEmpty
                              ? AppStrings.noRoomsCreated(serverId)
                              : search.isNotEmpty
                                  ? AppStrings.noRooms
                                  : AppStrings.noOpenRooms;
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: OceanGlassPanel(child: Text(message)),
                            ),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.s16,
                            AppSpacing.s8,
                            AppSpacing.s16,
                            AppSpacing.s24,
                          ),
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent:
                                  AppSizes.studentRoomTileMaxWidth,
                              mainAxisSpacing: AppSpacing.s16,
                              crossAxisSpacing: AppSpacing.s16,
                              childAspectRatio: AppSizes.reefCardAspectRatio,
                            ),
                            itemCount: rooms.length,
                            itemBuilder: (context, index) {
                              final room = rooms[index];
                              final own = user.roomId == room.id;
                              return RoomTableCard(
                                name: room.name,
                                members: room.memberIds.length,
                                capacity: room.capacity,
                                status: _statusLabel(room),
                                isMine: own,
                                onTap: () => context.go('/rooms/${room.id}'),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _statusLabel(TeamRoom room) => switch (room.status) {
        'locked' => AppStrings.roomLocked,
        'full' => AppStrings.roomFull,
        'empty' => AppStrings.roomEmpty,
        _ => AppStrings.roomOpen,
      };
}
