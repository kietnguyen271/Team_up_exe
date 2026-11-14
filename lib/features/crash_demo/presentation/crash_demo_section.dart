import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/error_notice.dart';
import '../data/firebase_crash_demo.dart';
import '../device_info.dart';
import '../domain/crash_demo_event.dart';

class CrashDemoSection extends StatefulWidget {
  const CrashDemoSection({super.key});

  @override
  State<CrashDemoSection> createState() => _CrashDemoSectionState();
}

class _CrashDemoSectionState extends State<CrashDemoSection> {
  final _demo = const FirebaseCrashDemo();
  bool _busy = false;
  String? _error;
  Future<void> Function()? _retry;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted)
        setState(() {
          _error = AppErrorMapper.message(error);
          _retry = action;
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _crash() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError(AppStrings.crashNeedsSignIn);
    await _demo.causeCrash(CrashDemoEvent(
      timestamp: DateTime.now().toUtc(),
      uid: uid,
      deviceInfo: currentDeviceInfo(),
      appVersion: AppStrings.appVersion,
    ));
  }

  Future<void> _nonFatal() async {
    await _demo.recordNonFatal(Exception(AppStrings.crashTestException));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.nonFatalSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.crashDemo,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s8),
            Text(AppStrings.crashExplanation,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.s16),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _run(_crash),
                  icon: const Icon(Icons.warning_amber_outlined),
                  label: const Text(AppStrings.causeCrash),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(_nonFatal),
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text(AppStrings.recordNonFatal),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s16),
              ErrorNotice(message: _error!),
              const SizedBox(height: AppSpacing.s8),
              TextButton.icon(
                onPressed: _busy || _retry == null ? null : () => _run(_retry!),
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
