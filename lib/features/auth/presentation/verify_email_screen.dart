import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/error_notice.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.verifyEmail)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: AppSizes.touchTarget),
                const SizedBox(height: AppSpacing.s16),
                Text(AppStrings.verifyEmailIntro,
                    style: Theme.of(context).textTheme.bodyLarge),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.s16),
                  ErrorNotice(message: _error!),
                ],
                const SizedBox(height: AppSpacing.s24),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await FirebaseAuth.instance.currentUser?.reload();
                            if (!context.mounted) return;
                            if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
                              context.go('/gate');
                            } else {
                              throw StateError(AppStrings.emailStillUnverified);
                            }
                          }),
                  child: const Text(AppStrings.iVerified),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await FirebaseAuth.instance.currentUser
                                ?.sendEmailVerification();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text(AppStrings.verificationSent)),
                              );
                            }
                          }),
                  child: const Text(AppStrings.resendVerification),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) context.go('/login');
                          }),
                  child: const Text(AppStrings.signOut),
                ),
              ],
            ),
          ),
        ),
      );
}
