import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/ocean_colors.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_notice.dart';
import '../../team/data/firebase_team_repository.dart';
import '../../team/domain/team_policy.dart';

class ServerPickerScreen extends StatefulWidget {
  const ServerPickerScreen({super.key});

  @override
  State<ServerPickerScreen> createState() => _ServerPickerScreenState();
}

class _ServerPickerScreenState extends State<ServerPickerScreen> {
  final _repository = FirebaseTeamRepository();
  bool _busy = false;
  String? _error;

  Future<void> _choose(String serverId) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw const TeamPolicyException(AppStrings.firebaseNotSignedIn);
      }
      await _repository.chooseServer(uid, serverId);
      if (mounted) context.go('/gate');
    } catch (error) {
      if (mounted) setState(() => _error = AppErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppShell(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.chooseServer,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.s8),
              Text(AppStrings.serverIntro,
                  style: Theme.of(context).textTheme.bodyLarge),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s16),
                ErrorNotice(message: _error!),
              ],
              const SizedBox(height: AppSpacing.s24),
              Wrap(
                spacing: AppSpacing.s16,
                runSpacing: AppSpacing.s16,
                children: [
                  _ServerCard(
                    label: AppStrings.exe1,
                    onTap: _busy ? null : () => _choose('exe1'),
                  ),
                  _ServerCard(
                    label: AppStrings.exe2,
                    onTap: _busy ? null : () => _choose('exe2'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ocean = Theme.of(context).extension<OceanColors>()!;
    return SizedBox(
      width: AppSizes.serverCardWidth,
      child: Card(
        child: InkWell(
          onTap: onTap,
          hoverColor: scheme.surfaceContainer,
          focusColor: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.r20),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: AppSizes.icon,
                  backgroundColor: ocean.lagoon,
                  child: Icon(Icons.water_rounded,
                      color: ocean.deepNavy, size: AppSizes.icon),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(label, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: [
                    Expanded(
                      child: Text(AppStrings.select,
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        color: ocean.teal, size: AppSizes.icon),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
