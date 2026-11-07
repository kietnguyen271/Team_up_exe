import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/error_notice.dart';
import '../domain/admin_access_service.dart';

class WebAdminLoginScreen extends StatefulWidget {
  const WebAdminLoginScreen({super.key, required this.access});

  final AdminAccessService access;

  @override
  State<WebAdminLoginScreen> createState() => _WebAdminLoginScreenState();
}

class _WebAdminLoginScreenState extends State<WebAdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = email.isEmpty
          ? AppStrings.emailRequired
          : AppStrings.passwordRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final allowed = await widget.access.signIn(email, password);
      if (!mounted) return;
      if (allowed) {
        context.go('/admin');
      } else {
        setState(() => _error = AppStrings.webAdminOnly);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.authFormWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppStrings.login,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.s8),
                  Text(AppStrings.adminIntro,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.s24),
                  TextField(
                    controller: _email,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: AppStrings.email),
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  TextField(
                    controller: _password,
                    focusNode: _passwordFocus,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration:
                        const InputDecoration(labelText: AppStrings.password),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.s16),
                    ErrorNotice(message: _error!),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? AppStrings.loading : AppStrings.login),
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
          ),
        ),
      ),
    );
  }
}
