import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/ocean_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_notice.dart';
import '../../team/data/firebase_team_repository.dart';
import '../../team/domain/team_models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return AppShell(
      selectedIndex: 1,
      child: uid == null
          ? const ErrorNotice(message: AppStrings.firebaseNotSignedIn)
          : StreamBuilder<TeamUser?>(
              stream: FirebaseTeamRepository().watchUser(uid),
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
                final serverId = userSnapshot.data?.serverId;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.notifications,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.s16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('announcements')
                            .orderBy('createdAt', descending: true)
                            .limit(50)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return ErrorNotice.fromError(
                              error: snapshot.error!,
                              onRetry: () => setState(() {}),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final items = snapshot.data!.docs.where((doc) {
                            final target = doc.data()['serverId'];
                            return target == 'all' || target == serverId;
                          }).toList();
                          if (items.isEmpty) {
                            return const Center(
                                child: Text(AppStrings.noAnnouncements));
                          }
                          return ListView(
                            children: [
                              for (final item in items)
                                Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .extension<OceanColors>()!
                                          .lagoon,
                                      child: const Icon(
                                        Icons.notifications_outlined,
                                      ),
                                    ),
                                    title: Text(
                                        item.data()['title'] as String? ?? ''),
                                    subtitle: Text(
                                        item.data()['body'] as String? ?? ''),
                                  ),
                                ),
                            ],
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
}
