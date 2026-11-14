import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_tokens.dart';
import '../ocean/reef_standalone_scaffold.dart';
import 'error_notice.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return ReefStandaloneScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppStrings.firebaseSetupRequired,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s16),
          Text(AppStrings.firebaseSetupCommand,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.s16),
          ErrorNotice(message: AppStrings.errorSetup),
        ],
      ),
    );
  }
}
