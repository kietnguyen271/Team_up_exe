import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';

/// A consistent readable surface for actions and details over ocean scenery.
class ReefSectionCard extends StatelessWidget {
  const ReefSectionCard({super.key, required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ocean = Theme.of(context).extension<OceanColors>()!;
    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: accent ?? ocean.teal,
              width: AppSizes.panelAccentWidth,
            ),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: child,
      ),
    );
  }
}
