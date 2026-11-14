import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';

abstract final class ToastService {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_rounded,
    bool error = false,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyLarge;
    final motion = Motion.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: motion.reduced ? 1 : 0, end: 1),
              duration: motion.use(MotionTokens.standard),
              curve: MotionTokens.enter,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, (value - 1) * AppSizes.touchTarget),
                child: Opacity(opacity: value, child: child),
              ),
              child: Material(
                color:
                    error ? scheme.errorContainer : AppPalette.successContainer,
                borderRadius: BorderRadius.circular(AppRadius.r20),
                elevation: AppElevation.level3,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          color: error ? scheme.error : AppPalette.success),
                      const SizedBox(width: AppSpacing.s8),
                      Flexible(
                        child: Text(message,
                            style: style?.copyWith(
                                color:
                                    error ? scheme.error : AppPalette.success)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    unawaited(Future<void>.delayed(MotionTokens.toastDisplay).then((_) {
      if (entry.mounted) entry.remove();
      entry.dispose();
    }));
  }
}
