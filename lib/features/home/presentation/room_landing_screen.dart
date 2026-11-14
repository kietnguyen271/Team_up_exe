import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/motion/reef_room_painter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/ocean_colors.dart';
import '../../../shared/ocean/reef_section_card.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_notice.dart';
import '../../team/data/firebase_team_repository.dart';
import '../../team/data/gemini_skill_summary_service.dart';
import '../../team/domain/skill_summary_service.dart';
import '../../team/domain/team_models.dart';
import '../../team/domain/team_policy.dart';

class RoomLandingScreen extends StatefulWidget {
  const RoomLandingScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<RoomLandingScreen> createState() => _RoomLandingScreenState();
}

class _RoomLandingScreenState extends State<RoomLandingScreen> {
  final _repository = FirebaseTeamRepository();
  static const _useFirebaseAi = bool.fromEnvironment('USE_FIREBASE_AI');
  bool _busy = false;
  String? _error;
  String? _membersKey;
  Future<List<TeamUser>>? _membersFuture;
  String? _summaryKey;
  Future<String>? _summaryFuture;
  final _requesterFutures = <String, Future<TeamUser?>>{};

  Future<TeamUser?> _requester(String uid) =>
      _requesterFutures.putIfAbsent(uid, () => _repository.getUser(uid));

  Future<List<TeamUser>> _loadMembers(TeamRoom room) {
    final key = room.memberIds.join('|');
    if (_membersKey != key) {
      _membersKey = key;
      _membersFuture = _repository.getMembers(room.memberIds);
    }
    return _membersFuture!;
  }

  Future<String> _summarize(List<TeamUser> members, {bool refresh = false}) {
    final key = members
        .map((member) => '${member.id}:${member.skills.join(',')}')
        .join('|');
    if (refresh || _summaryKey != key) {
      _summaryKey = key;
      _summaryFuture = (_useFirebaseAi
              ? const FallbackSkillSummaryService(
                  GeminiSkillSummaryService(), LocalSkillSummaryService())
              : const LocalSkillSummaryService())
          .summarize(members);
    }
    return _summaryFuture!;
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
    } catch (error) {
      if (mounted) setState(() => _error = AppErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rename(String uid, TeamRoom room) async {
    var roomName = room.name;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.renameRoom),
        content: TextFormField(
          initialValue: room.name,
          autofocus: true,
          decoration: const InputDecoration(labelText: AppStrings.roomName),
          onChanged: (value) => roomName = value,
          onFieldSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, roomName),
            child: const Text(AppStrings.save),
          ),
        ],
      ),
    );
    if (name != null)
      await _run(() => _repository.renameRoom(uid, room.id, name));
  }

  Future<void> _requestJoin(String uid, String roomId) async {
    var requestMessage = '';
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.requestJoin),
        content: TextFormField(
          maxLength: TeamPolicy.maxRequestMessageLength,
          maxLines: 3,
          onChanged: (value) => requestMessage = value,
          decoration:
              const InputDecoration(labelText: AppStrings.requestMessage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, requestMessage),
            child: const Text(AppStrings.requestJoin),
          ),
        ],
      ),
    );
    if (message != null) {
      await _run(() async {
        await _repository.joinOrRequest(uid, roomId, message: message);
      });
    }
  }

  Future<void> _vote(String uid, TeamRoom room, List<TeamUser> members) async {
    final candidate = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(AppStrings.chooseLeader),
        children: [
          for (final member in members)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, member.id),
              child: Text(member.name),
            ),
        ],
      ),
    );
    if (candidate != null) {
      await _run(() => _repository.castVote(uid, room.id, candidate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null)
      return const AppShell(child: Text(AppStrings.firebaseNotSignedIn));
    return AppShell(
      child: StreamBuilder<TeamRoom?>(
        stream: _repository.watchRoom(widget.roomId),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.hasError) {
            return ErrorNotice.fromError(
              error: roomSnapshot.error!,
              onRetry: () => setState(() {}),
            );
          }
          if (!roomSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final room = roomSnapshot.data;
          if (room == null) return const Text(AppStrings.roomMissing);
          return StreamBuilder<TeamUser?>(
            stream: _repository.watchUser(uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return ErrorNotice.fromError(
                  error: userSnapshot.error!,
                  onRetry: () => setState(() {}),
                );
              }
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final user = userSnapshot.data;
              if (user == null) return const Text(AppStrings.profileMissing);
              if (!TeamPolicy.canSeeRoom(user, room)) {
                return const Center(
                  child: ErrorNotice(message: AppStrings.roomIsLocked),
                );
              }
              return FutureBuilder<List<TeamUser>>(
                future: _loadMembers(room),
                builder: (context, membersSnapshot) {
                  if (membersSnapshot.hasError) {
                    return ErrorNotice.fromError(
                      error: membersSnapshot.error!,
                      onRetry: () => setState(() {
                        _membersKey = null;
                      }),
                    );
                  }
                  if (!membersSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _body(context, room, user, membersSnapshot.data!);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, TeamRoom room, TeamUser user,
      List<TeamUser> members) {
    final mine = room.contains(user.id);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back),
            label: const Text(AppStrings.rooms),
          ),
          if (mine) ...[
            ReefSectionCard(child: _requestsSection(user.id, room)),
            const SizedBox(height: AppSpacing.s16),
          ],
          ReefSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  '${members.length}/${room.capacity} · ${room.locked ? AppStrings.roomLocked : room.isFull ? AppStrings.roomFull : room.isEmpty ? AppStrings.roomEmpty : AppStrings.roomOpen}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.s8),
                Center(
                  child: SizedBox.square(
                    dimension: AppSizes.roomTileMin,
                    child: CustomPaint(
                      painter: ReefRoomPainter(
                        ocean: Theme.of(context).extension<OceanColors>()!,
                        capacity: room.capacity,
                        members: members.length,
                        isMine: mine,
                        locked: room.locked,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s16),
            ErrorNotice(message: _error!),
          ],
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              if (!mine && user.roomId == null && !room.isFull)
                StreamBuilder<TeamJoinRequest?>(
                  stream: _repository.watchOwnRequest(room.id, user.id),
                  builder: (context, snapshot) {
                    final pending =
                        snapshot.data?.isPendingAt(DateTime.now()) ?? false;
                    if (pending) {
                      return OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(() =>
                                _repository.cancelRequest(user.id, room.id)),
                        icon: const Icon(Icons.pending_actions_outlined),
                        label: const Text(AppStrings.cancelRequest),
                      );
                    }
                    return FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : room.isEmpty
                              ? () => _run(() async {
                                    await _repository.joinOrRequest(
                                        user.id, room.id);
                                  })
                              : () => _requestJoin(user.id, room.id),
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(room.isEmpty
                          ? AppStrings.joinRoom
                          : AppStrings.requestJoin),
                    );
                  },
                ),
              if (mine) ...[
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _rename(user.id, room),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text(AppStrings.renameRoom),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await _repository.leaveRoom(user.id, room.id);
                            if (context.mounted) context.go('/home');
                          }),
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text(AppStrings.leaveRoom),
                ),
                if (room.leaderId == user.id)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(() => _repository.setLocked(
                            user.id, room.id, !room.locked)),
                    icon: Icon(room.locked ? Icons.lock_open : Icons.lock),
                    label: Text(room.locked
                        ? AppStrings.unlockRoom
                        : AppStrings.lockRoom),
                  ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(AppStrings.members,
              style: Theme.of(context).textTheme.titleLarge),
          if (members.isEmpty) const Text(AppStrings.noMembers),
          for (final member in members)
            Card(
              child: ListTile(
                leading: Icon(member.id == room.leaderId
                    ? Icons.workspace_premium_outlined
                    : Icons.person_outline),
                title: Text(member.name),
                subtitle: Text('${member.bio}\n${member.skills.join(', ')}'),
                isThreeLine: true,
              ),
            ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s16),
            FutureBuilder<String>(
              future: _summarize(members),
              builder: (context, snapshot) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(AppStrings.aiSuggestion,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        IconButton(
                          tooltip: AppStrings.retry,
                          onPressed: () => setState(
                              () => _summarize(members, refresh: true)),
                          icon: const Icon(Icons.refresh),
                        ),
                      ]),
                      const SizedBox(height: AppSpacing.s8),
                      Text(snapshot.data ?? AppStrings.loading),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (mine) ...[
            const SizedBox(height: AppSpacing.s24),
            ReefSectionCard(child: _voteSection(user.id, room, members)),
            const SizedBox(height: AppSpacing.s24),
            ReefSectionCard(child: _disbandSection(user.id, room)),
          ],
        ],
      ),
    );
  }

  Widget _voteSection(String uid, TeamRoom room, List<TeamUser> members) =>
      StreamBuilder<TeamVote?>(
        stream: _repository.watchVote(room.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorNotice.fromError(
              error: snapshot.error!,
              onRetry: () => setState(() {}),
            );
          }
          final vote = snapshot.data;
          if (vote != null &&
              vote.status == 'active' &&
              DateTime.now().isAfter(vote.endsAt)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _run(() => _repository.finalizeVote(room.id));
            });
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.leaderVote,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s8),
              if (room.leaderId != null)
                Text(
                    '${AppStrings.leader}: ${members.where((m) => m.id == room.leaderId).map((m) => m.name).firstOrNull ?? room.leaderId}')
              else if (vote?.status == 'active') ...[
                Text(AppStrings.voteActive),
                const SizedBox(height: AppSpacing.s8),
                for (final member in members)
                  Text(AppStrings.voteCount(
                    member.name,
                    vote!.ballots.entries
                        .where((ballot) =>
                            room.contains(ballot.key) &&
                            ballot.value == member.id)
                        .length,
                  )),
                const SizedBox(height: AppSpacing.s8),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _vote(uid, room, members),
                  icon: const Icon(Icons.how_to_vote_outlined),
                  label: const Text(AppStrings.castVote),
                ),
              ] else
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() => _repository.startVote(uid, room.id)),
                  icon: const Icon(Icons.how_to_vote_outlined),
                  label: const Text(AppStrings.startVote),
                ),
            ],
          );
        },
      );

  Widget _disbandSection(String uid, TeamRoom room) =>
      StreamBuilder<TeamDisband?>(
        stream: _repository.watchDisband(room.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorNotice.fromError(
              error: snapshot.error!,
              onRetry: () => setState(() {}),
            );
          }
          final proposal = snapshot.data;
          final active = proposal != null &&
              proposal.status == 'active' &&
              DateTime.now().isBefore(proposal.endsAt);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.disbandRoom,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s8),
              if (active) ...[
                Text(
                    '${proposal.approvedBy.length}/${room.memberIds.length} ${AppStrings.approvedDisband}'),
                if (!proposal.approvedBy.contains(uid))
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => _repository.approveDisband(uid, room.id)),
                    child: const Text(AppStrings.approveDisband),
                  ),
              ] else
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () =>
                          _run(() => _repository.proposeDisband(uid, room.id)),
                  icon: const Icon(Icons.groups_2_outlined),
                  label: const Text(AppStrings.proposeDisband),
                ),
            ],
          );
        },
      );

  Widget _requestsSection(String uid, TeamRoom room) =>
      StreamBuilder<List<TeamJoinRequest>>(
        stream: _repository.watchRequests(room.id),
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
          final pending = snapshot.data!
              .where((request) => request.isPendingAt(DateTime.now()))
              .toList();
          final expired = snapshot.data!
              .where((request) =>
                  request.status == 'pending' &&
                  !request.isPendingAt(DateTime.now()))
              .toList();
          if (expired.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              for (final request in expired) {
                unawaited(_repository
                    .expireRequest(room.id, request.uid)
                    .catchError((Object error) {
                  if (mounted) {
                    setState(() => _error = AppErrorMapper.message(error));
                  }
                }));
              }
            });
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.joinRequests,
                  style: Theme.of(context).textTheme.titleLarge),
              Text(AppStrings.pendingJoinRequests(pending.length)),
              if (pending.isEmpty) const Text(AppStrings.noJoinRequests),
              for (final request in pending)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<TeamUser?>(
                          future: _requester(request.uid),
                          builder: (context, userSnapshot) => Text(
                            userSnapshot.data?.name ?? request.uid,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(request.message.isEmpty
                            ? AppStrings.requestPending
                            : '${AppStrings.requestPending} · ${request.message}'),
                        const SizedBox(height: AppSpacing.s16),
                        Wrap(
                          spacing: AppSpacing.s8,
                          runSpacing: AppSpacing.s8,
                          children: [
                            FilledButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() => _repository.decideRequest(
                                      uid, room.id, request.uid, true)),
                              icon: const Icon(Icons.check),
                              label: const Text(AppStrings.approve),
                            ),
                            OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _run(() => _repository.decideRequest(
                                      uid, room.id, request.uid, false)),
                              icon: const Icon(Icons.close),
                              label: const Text(AppStrings.reject),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
}
