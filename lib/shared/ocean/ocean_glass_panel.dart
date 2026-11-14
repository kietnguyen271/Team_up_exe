import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';

class OceanGlassPanel extends StatelessWidget {
  const OceanGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ocean =
        Theme.of(context).extension<OceanColors>() ?? OceanColors.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient: color == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ocean.foam.withValues(alpha: AppSizes.glassHighlightOpacity),
                  ocean.seaGlass,
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.r28),
        border: Border.all(color: ocean.foam, width: AppSizes.outlineWidth),
        boxShadow: [
          BoxShadow(
            color: ocean.deepWater.withValues(
              alpha: AppSizes.glassShadowOpacity,
            ),
            blurRadius: AppSizes.glowBlur,
            offset: const Offset(0, AppSpacing.s8),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.s16),
        child: child,
      ),
    );
  }
}
