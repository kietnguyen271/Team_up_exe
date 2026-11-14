import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.message = AppStrings.uiEmptyRooms});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSizes.touchTarget),
              const SizedBox(height: AppSpacing.s16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = AppStrings.uiMockError,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: AppSizes.touchTarget,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.s16),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.s16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(AppStrings.uiTryAgain),
              ),
            ],
          ),
        ),
      );
}

class PermissionDenied extends StatelessWidget {
  const PermissionDenied({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
        message: AppStrings.uiNoPermission,
      );
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, required this.child, required this.loading});
  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          child,
          if (loading)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: AppSizes.overlayOpacity),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      );
}
