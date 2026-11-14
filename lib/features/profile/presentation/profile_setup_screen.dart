import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/notifications/notification_runtime.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/ocean_colors.dart';
import '../../../shared/ocean/reef_section_card.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/error_notice.dart';
import '../../../shared/ocean/ocean_effects_control.dart';
import '../../crash_demo/presentation/crash_demo_section.dart';
import '../../team/data/firebase_team_repository.dart';
import '../../team/domain/team_models.dart';
import '../../team/domain/team_policy.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _repository = FirebaseTeamRepository();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _skills = <String>{};
  bool _busy = false;
  bool _loaded = false;
  bool _profileComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final profile = uid == null ? null : await _repository.getUser(uid);
      if (!mounted) return;
      if (profile != null) {
        _name.text = profile.name;
        _bio.text = profile.bio;
        _skills.addAll(profile.skills);
        _profileComplete = profile.hasProfile;
      }
      setState(() => _loaded = true);
    } catch (error) {
      if (mounted)
        setState(() {
          _error = AppErrorMapper.message(error);
          _loaded = true;
        });
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw const TeamPolicyException(AppStrings.firebaseNotSignedIn);
      }
      await _repository.saveProfile(
        user.uid,
        user.email!,
        _name.text,
        _bio.text,
        _skills.toList(),
      );
      if (mounted) context.go('/gate');
    } catch (error) {
      if (mounted) setState(() => _error = AppErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await NotificationRuntime.instance.beforeSignOut();
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/login');
    } catch (error) {
      if (mounted) setState(() => _error = AppErrorMapper.message(error));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppShell(
        selectedIndex: 2,
        child: _loaded
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: AppSizes.icon,
                          backgroundColor: Theme.of(context)
                              .extension<OceanColors>()!
                              .lagoon,
                          child: const Icon(Icons.person_outline_rounded),
                        ),
                        const SizedBox(width: AppSpacing.s16),
                        Expanded(
                          child: Text(AppStrings.profileSetup,
                              style: Theme.of(context).textTheme.headlineSmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(AppStrings.profileIntro,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.s24),
                    TextField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(labelText: AppStrings.name),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    TextField(
                      controller: _bio,
                      maxLength: TeamPolicy.maxBioLength,
                      minLines: 3,
                      maxLines: 5,
                      decoration:
                          const InputDecoration(labelText: AppStrings.bio),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    ReefSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.skills,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.s8),
                          Wrap(
                            spacing: AppSpacing.s8,
                            runSpacing: AppSpacing.s8,
                            children: [
                              for (final skill in teamSkills)
                                FilterChip(
                                  label: Text(skill),
                                  selected: _skills.contains(skill),
                                  showCheckmark: true,
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
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.s16),
                      ErrorNotice(message: _error!),
                    ],
                    const SizedBox(height: AppSpacing.s24),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Text(_busy ? AppStrings.loading : AppStrings.save),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    if (_profileComplete)
                      OutlinedButton.icon(
                        onPressed: () => context.go('/servers'),
                        icon: const Icon(Icons.dns_outlined),
                        label: const Text(AppStrings.chooseServer),
                      ),
                    const SizedBox(height: AppSpacing.s24),
                    ReefSectionCard(
                      child: Column(
                        children: [
                          const OceanEffectsControl(),
                          AnimatedBuilder(
                            animation: Motion.settings,
                            builder: (context, _) => SwitchListTile(
                              title: const Text(AppStrings.uiReduceMotion),
                              value: Motion.settings.reduced,
                              onChanged: Motion.settings.setReduced,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    const CrashDemoSection(),
                    const SizedBox(height: AppSpacing.s24),
                    TextButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text(AppStrings.signOut),
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
}
