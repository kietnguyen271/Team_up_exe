import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_tokens.dart';
import 'error_notice.dart';

class GenericErrorScreen extends StatelessWidget {
  const GenericErrorScreen({
    super.key,
    this.onRetry,
    this.message = AppStrings.genericError,
  });

  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorNotice(message: message),
                const SizedBox(height: AppSpacing.s16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
