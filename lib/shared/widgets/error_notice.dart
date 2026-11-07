import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class ErrorNotice extends StatelessWidget {
  const ErrorNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: AppSizes.icon),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
