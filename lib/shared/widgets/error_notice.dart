import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/app_error_mapper.dart';
import '../../core/theme/app_tokens.dart';

class ErrorNotice extends StatelessWidget {
  const ErrorNotice({
    super.key,
    required this.message,
    this.onRetry,
  });

  ErrorNotice.fromError({
    super.key,
    required Object error,
    this.onRetry,
  }) : message = AppErrorMapper.message(error);

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.r20),
          border: Border.all(color: scheme.error),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: AppSizes.icon),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.errorTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: scheme.error),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    message,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.error),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: AppSpacing.s8),
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text(AppStrings.retry),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
