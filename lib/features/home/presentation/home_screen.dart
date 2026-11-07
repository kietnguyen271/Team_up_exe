import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_tokens.dart';
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
      child: uid == null
          ? const ErrorNotice(message: AppStrings.firebaseNotSignedIn)
          : StreamBuilder<TeamUser?>(
              stream: _repository.watchUser(uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return ErrorNotice(message: userSnapshot.error.toString());
                }
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final user = userSnapshot.data!;
                final serverId = user.serverId;
                if (serverId == null) {
                  return Center(
                    child: FilledButton(
                      onPressed: () => context.go('/servers'),
                      child: const Text(AppStrings.chooseServer),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${AppStrings.rooms} · ${serverId.toUpperCase()}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: AppStrings.chooseServer,
                          onPressed: () => context.go('/servers'),
                          icon: const Icon(Icons.swap_horiz),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: AppStrings.searchRooms,
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Expanded(
                      child: StreamBuilder<List<TeamRoom>>(
                        stream: _repository.watchRooms(serverId),
                        builder: (context, roomSnapshot) {
                          if (roomSnapshot.hasError) {
                            return ErrorNotice(
                              message: roomSnapshot.error.toString(),
                            );
                          }
                          if (!roomSnapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final search = TeamPolicy.normalize(_search.text);
                          final rooms = roomSnapshot.data!
                              .where((room) => TeamPolicy.normalize(room.name)
                                  .contains(search))
                              .toList();
                          if (rooms.isEmpty) {
                            return const Center(
                                child: Text(AppStrings.noRooms));
                          }
                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent:
                                  AppSizes.studentRoomTileMaxWidth,
                              mainAxisSpacing: AppSpacing.s8,
                              crossAxisSpacing: AppSpacing.s8,
                              childAspectRatio: 1,
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
                          );
                        },
                      ),
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
