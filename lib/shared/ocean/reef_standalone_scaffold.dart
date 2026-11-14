import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';
import 'ocean_backdrop.dart';
import 'ocean_glass_panel.dart';

/// Ocean backdrop and a readable sea-glass surface for standalone routes.
class ReefStandaloneScaffold extends StatelessWidget {
  const ReefStandaloneScaffold({
    super.key,
    required this.child,
    this.title,
    this.maxWidth = AppSizes.authFormWidth,
  });

  final Widget child;
  final String? title;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final ocean =
        Theme.of(context).extension<OceanColors>() ?? OceanColors.light;
    return Scaffold(
      backgroundColor: AppPalette.transparent,
      extendBodyBehindAppBar: title != null,
      appBar: title == null
          ? null
          : AppBar(
              backgroundColor: AppPalette.transparent,
              foregroundColor: ocean.deepNavy,
              surfaceTintColor: AppPalette.transparent,
              systemOverlayStyle: AppTheme.oceanSystemBars,
              title: OceanGlassPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s4,
                ),
                child: Text(title!),
              ),
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const OceanBackdrop(showDebugOverlay: false),
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      title == null ? AppSpacing.s24 : kToolbarHeight,
                      AppSpacing.s16,
                      AppSpacing.s24,
                    ),
                    child: OceanGlassPanel(
                      padding: const EdgeInsets.all(AppSpacing.s24),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
