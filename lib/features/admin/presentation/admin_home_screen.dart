import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/notifications/notification_runtime.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/ocean_colors.dart';
import '../../../shared/ocean/reef_section_card.dart';
import '../../../shared/widgets/error_notice.dart';
import '../../../shared/widgets/room_table_card.dart';
import '../../team/domain/team_models.dart';
import '../data/firebase_admin_repository.dart';
import '../domain/admin_access_service.dart';
import '../domain/rollover_preview.dart';
import 'admin_shell.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen(
      {super.key, required this.access, required this.selectedIndex});

  final AdminAccessService access;
  final int selectedIndex;

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _repository = FirebaseAdminRepository();
  String _serverId = 'exe1';
  String _notificationTarget = 'all';
  String _pushTarget = 'room';
  bool _busy = false;
  String? _error;
  RolloverPreview? _preview;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = AppErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askText(String title, String label,
      {String initial = ''}) async {
    var text = initial;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initial,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onChanged: (value) => text = value,
          onFieldSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  Future<void> _createRooms() async {
    final count = await _askText(AppStrings.createRooms, AppStrings.roomCount);
    if (count == null || !mounted) return;
    final capacity =
        await _askText(AppStrings.createRooms, AppStrings.capacity);
    if (capacity == null) return;
    await _run(() => _repository.createRooms(
          _serverId,
          int.parse(count),
          int.parse(capacity),
        ));
  }

  Future<void> _editTemplate() async {
    await _run(() async {
      final template = await _repository.getTemplate(_serverId);
      if (!mounted) return;
      final initial =
          template.map((room) => '${room.name}:${room.capacity}').join('\n');
      final text = await _askText(
        AppStrings.editTemplate,
        AppStrings.templateFormat,
        initial: initial,
      );
      if (text == null) return;
      final lines = text.split('\n').where((line) => line.trim().isNotEmpty);
      final rooms = <RoomTemplate>[];
      for (final line in lines) {
        final split = line.lastIndexOf(':');
        if (split <= 0) throw FormatException(AppStrings.templateFormat);
        rooms.add(RoomTemplate(
          line.substring(0, split).trim(),
          int.parse(line.substring(split + 1).trim()),
        ));
      }
      await _repository.saveTemplate(_serverId, rooms);
    });
  }

  Future<void> _showRoomMembers(String name, List<String> memberIds) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: SizedBox(
          width: AppSizes.serverCardWidth,
          child: FutureBuilder<List<TeamUser>>(
            future: _repository.getRoomMembers(memberIds),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorNotice.fromError(error: snapshot.error!);
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const Text(AppStrings.noMembers);
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  for (final member in snapshot.data!)
                    ListTile(
                      title: Text(member.name),
                      subtitle:
                          Text('${member.bio}\n${member.skills.join(', ')}'),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.close),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.selectedIndex.clamp(0, 3);
    return AdminShell(
      selectedIndex: index,
      onSignOut: () async {
        await NotificationRuntime.instance.beforeSignOut();
        await widget.access.auth.signOut();
        if (context.mounted) context.go('/login');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            ErrorNotice(message: _error!),
            const SizedBox(height: AppSpacing.s16),
          ],
          Expanded(
            child: switch (index) {
              0 => _roomsTab(),
              1 => _semesterTab(),
              2 => _announcementsTab(),
              _ => _demoTab(),
            },
          ),
        ],
      ),
    );
  }

  Widget _serverSelector() => DropdownButton<String>(
        value: _serverId,
        items: const [
          DropdownMenuItem(value: 'exe1', child: Text(AppStrings.exe1)),
          DropdownMenuItem(value: 'exe2', child: Text(AppStrings.exe2)),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _serverId = value);
        },
      );

  Widget _roomsTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.rooms,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s16),
          ReefSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _serverSelector(),
                Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : _createRooms,
                        icon: const Icon(Icons.add),
                        label: const Text(AppStrings.createRooms),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _editTemplate,
                        icon: const Icon(Icons.edit_note_outlined),
                        label: const Text(AppStrings.editTemplate),
                      ),
                    ]),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repository.watchRooms(_serverId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorNotice.fromError(
                    error: snapshot.error!,
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rooms = snapshot.data!.docs;
                if (rooms.isEmpty) {
                  return const Center(child: Text(AppStrings.noRooms));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: AppSizes.adminRoomTileMaxWidth,
                    mainAxisSpacing: AppSpacing.s16,
                    crossAxisSpacing: AppSpacing.s16,
                    childAspectRatio: AppSizes.reefCardAspectRatio,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final data = room.data();
                    final members =
                        (data['memberIds'] as List? ?? const []).length;
                    final capacity = (data['capacity'] as num?)?.toInt() ?? 0;
                    final name = data['name'] as String? ?? room.id;
                    final locked = data['locked'] == true;
                    final status = locked
                        ? AppStrings.roomLocked
                        : members >= capacity && capacity > 0
                            ? AppStrings.roomFull
                            : members == 0
                                ? AppStrings.roomEmpty
                                : AppStrings.roomOpen;
                    return RoomTableCard(
                      name: name,
                      members: members,
                      capacity: capacity,
                      status: status,
                      onTap: () => _showRoomMembers(
                        name,
                        List<String>.from(
                            data['memberIds'] as List? ?? const []),
                      ),
                      action: PopupMenuButton<String>(
                        tooltip: AppStrings.roomActions,
                        onSelected: (action) async {
                          if (action == 'rename') {
                            final name = await _askText(
                              AppStrings.renameRoom,
                              AppStrings.roomName,
                              initial: data['name'] as String? ?? '',
                            );
                            if (name != null) {
                              await _run(
                                  () => _repository.renameRoom(room.id, name));
                            }
                          } else if (action == 'capacity') {
                            final value = await _askText(
                              AppStrings.editCapacity,
                              AppStrings.capacity,
                              initial: '$capacity',
                            );
                            if (value != null) {
                              await _run(() => _repository.editCapacity(
                                  room.id, int.parse(value)));
                            }
                          } else if (action == 'delete') {
                            await _run(
                                () => _repository.deleteEmptyRoom(room.id));
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'rename',
                              child: Text(AppStrings.renameRoom)),
                          PopupMenuItem(
                              value: 'capacity',
                              child: Text(AppStrings.editCapacity)),
                          PopupMenuItem(
                              value: 'delete',
                              child: Text(AppStrings.deleteRoom)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

  Widget _semesterTab() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.semester,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.s16),
            ReefSectionCard(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _repository.watchRollover(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorNotice.fromError(
                    error: snapshot.error!,
                    onRetry: () => setState(() {}),
                  );
                }
                final data = snapshot.data?.data();
                if (data == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                  child: Text(AppStrings.rolloverStatus(
                    data['state'] as String? ?? '',
                    data['step'] as String? ?? '',
                  )),
                );
              },
            )),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        final preview = await _repository.previewRollover();
                        if (mounted) setState(() => _preview = preview);
                      }),
              icon: const Icon(Icons.preview_outlined),
              label: const Text(AppStrings.previewRollover),
            ),
            if (_preview != null) ...[
              const SizedBox(height: AppSpacing.s16),
              ReefSectionCard(
                  child: Text(
                      AppStrings.rolloverPreview(
                        _preview!.exe2StudentCount,
                        _preview!.exe1RoomCount,
                        _preview!.exe1StudentCount,
                        _preview!.renewedExe1RoomCount,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge)),
              const SizedBox(height: AppSpacing.s16),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final confirmation = await _askText(
                          AppStrings.finishSemester,
                          AppStrings.typeHoanTat,
                        );
                        if (confirmation != AppStrings.rolloverConfirmation) {
                          if (mounted) {
                            setState(
                                () => _error = AppStrings.wrongConfirmation);
                          }
                          return;
                        }
                        await _run(_repository.runRollover);
                      },
                icon: const Icon(Icons.event_available_outlined),
                label: const Text(AppStrings.finishSemester),
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final confirmation = await _askText(
                        AppStrings.prepareNextSemester,
                        AppStrings.typeKyMoi,
                      );
                      if (confirmation != AppStrings.nextSemesterConfirmation) {
                        if (mounted)
                          setState(() => _error =
                              AppStrings.wrongNextSemesterConfirmation);
                        return;
                      }
                      await _run(_repository.prepareNextSemester);
                    },
              icon: const Icon(Icons.restart_alt),
              label: const Text(AppStrings.prepareNextSemester),
            ),
          ],
        ),
      );

  Widget _announcementsTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.notifications,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s16),
          ReefSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: _notificationTarget,
                  items: const [
                    DropdownMenuItem(
                        value: 'all', child: Text(AppStrings.allServers)),
                    DropdownMenuItem(
                        value: 'exe1', child: Text(AppStrings.exe1)),
                    DropdownMenuItem(
                        value: 'exe2', child: Text(AppStrings.exe2)),
                  ],
                  onChanged: (value) {
                    if (value != null)
                      setState(() => _notificationTarget = value);
                  },
                ),
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final title = await _askText(
                              AppStrings.newAnnouncement,
                              AppStrings.announcementTitle);
                          if (title == null || !mounted) return;
                          final body = await _askText(
                              AppStrings.newAnnouncement,
                              AppStrings.announcementBody);
                          if (body != null) {
                            await _run(() => _repository.createAnnouncement(
                                title, body, _notificationTarget));
                          }
                        },
                  icon: const Icon(Icons.add_alert_outlined),
                  label: const Text(AppStrings.newAnnouncement),
                ),
                const SizedBox(height: AppSpacing.s8),
                DropdownButton<String>(
                  value: _pushTarget,
                  items: const [
                    DropdownMenuItem(
                        value: 'room', child: Text(AppStrings.pushRoom)),
                    DropdownMenuItem(
                        value: 'server', child: Text(AppStrings.pushServer)),
                    DropdownMenuItem(
                        value: 'user', child: Text(AppStrings.pushUser)),
                    DropdownMenuItem(
                        value: 'all', child: Text(AppStrings.pushAll)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _pushTarget = value);
                  },
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final targetKind = _pushTarget;
                          String targetId = '';
                          if (targetKind != 'all') {
                            final enteredId = await _askText(
                              AppStrings.sendPush,
                              targetKind == 'room'
                                  ? AppStrings.roomId
                                  : targetKind == 'server'
                                      ? AppStrings.serverId
                                      : AppStrings.userId,
                            );
                            if (enteredId == null || !mounted) return;
                            targetId = enteredId;
                          }
                          final title = await _askText(AppStrings.sendPush,
                              AppStrings.announcementTitle);
                          if (title == null || !mounted) return;
                          final body = await _askText(
                              AppStrings.sendPush, AppStrings.announcementBody);
                          if (body != null) {
                            await _run(() => _repository.queueBroadcastPush(
                                title, body, targetKind, targetId));
                          }
                        },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text(AppStrings.sendPush),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repository.watchAnnouncements(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorNotice.fromError(
                    error: snapshot.error!,
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text(AppStrings.noAnnouncements));
                }
                return ListView(
                  children: [
                    for (final doc in snapshot.data!.docs)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .extension<OceanColors>()!
                                .lagoon,
                            child: const Icon(Icons.notifications_outlined),
                          ),
                          title: Text(doc.data()['title'] as String? ?? ''),
                          subtitle: Text(doc.data()['body'] as String? ?? ''),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Text(AppStrings.pushJobs,
              style: Theme.of(context).textTheme.titleLarge),
          SizedBox(
            height: AppSizes.pushJobsHeight,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repository.watchPushJobs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorNotice.fromError(
                    error: snapshot.error!,
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  children: [
                    for (final job in snapshot.data!.docs)
                      ListTile(
                        leading: const Icon(Icons.send_outlined),
                        title: Text(job.data()['title'] as String? ?? ''),
                        subtitle: Text(AppStrings.pushJobDetails(
                          job.data()['status'] as String? ?? '',
                          job.data()['error'] as String?,
                        )),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      );

  Widget _demoTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.demoLog,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repository.watchDemoEvents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorNotice.fromError(
                    error: snapshot.error!,
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text(AppStrings.noDemoEvents));
                }
                return ListView(
                  children: [
                    for (final doc in snapshot.data!.docs)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .extension<OceanColors>()!
                                .lagoon,
                            child: const Icon(Icons.bug_report_outlined),
                          ),
                          title: Text(doc.data()['uid'] as String? ?? ''),
                          subtitle: Text(
                              '${doc.data()['deviceInfo']} · ${doc.data()['appVersion']}'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      );
}
