import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/ocean_colors.dart';
import '../../../shared/ocean/reef_standalone_scaffold.dart';
import '../../../shared/widgets/error_notice.dart';
import '../../team/domain/team_policy.dart';

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({super.key, required this.isRegistration});

  final bool isRegistration;

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _error = email.isEmpty
          ? AppStrings.emailRequired
          : password.isEmpty
              ? AppStrings.passwordRequired
              : null;
    });
    if (_error != null) return;
    setState(() => _busy = true);
    try {
      if (widget.isRegistration) {
        TeamPolicy.validateRegistration(email, password);
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      if (mounted) context.go('/gate');
    } catch (error) {
      if (mounted) setState(() => _error = AppErrorMapper.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.isRegistration ? AppStrings.register : AppStrings.login;
    return ReefStandaloneScaffold(
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.icon,
                  backgroundColor:
                      (Theme.of(context).extension<OceanColors>() ??
                              OceanColors.light)
                          .lagoon,
                  child: const Icon(Icons.waves_rounded),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Text(AppStrings.appName,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.s8),
            Text(
              widget.isRegistration
                  ? AppStrings.registerIntro
                  : AppStrings.loginIntro,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              widget.isRegistration
                  ? AppStrings.adminRegistrationHint
                  : AppStrings.adminLoginHint,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (kDebugMode &&
                const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) ...[
              const SizedBox(height: AppSpacing.s16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.s16),
                  child: Text(AppStrings.localDemoMode),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: AppStrings.email,
              ),
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: true,
              autofillHints: [
                widget.isRegistration
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: AppStrings.password,
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s16),
              ErrorNotice(message: _error!),
            ],
            const SizedBox(height: AppSpacing.s24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? AppStrings.loading : title),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextButton(
              onPressed: () => context.go(
                widget.isRegistration ? '/login' : '/register',
              ),
              child: Text(
                widget.isRegistration
                    ? AppStrings.goToLogin
                    : AppStrings.goToRegister,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: AppSpacing.s8),
              TextButton.icon(
                onPressed: () => context.go('/debug-firebase'),
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text(AppStrings.firebaseDebug),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
