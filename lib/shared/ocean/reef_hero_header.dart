import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';
import 'ocean_backdrop.dart';
import 'ocean_glass_panel.dart';

class ReefHeroHeader extends SliverPersistentHeaderDelegate {
  ReefHeroHeader({
    required this.title,
    required this.expandedHeight,
    required this.onSwitchServer,
  });

  final String title;
  final double expandedHeight;
  final VoidCallback onSwitchServer;

  @override
  double get minExtent => AppSizes.reefHeroMinHeight;

  @override
  double get maxExtent => expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final ocean = Theme.of(context).extension<OceanColors>()!;
    final collapse =
        (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0).toDouble();
    return ColoredBox(
      color: Color.lerp(AppPalette.transparent, ocean.foam, collapse)!,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: AppSpacing.s16,
            right: AppSpacing.s16,
            child: Opacity(
              opacity: 1 - collapse,
              child: const OceanDebugBadge(),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: OceanGlassPanel(
                color: Color.lerp(ocean.seaGlass, ocean.foam, collapse),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: ocean.deepNavy,
                                ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.chooseServer,
                      onPressed: onSwitchServer,
                      icon: const Icon(Icons.swap_horiz),
                      color: ocean.deepNavy,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant ReefHeroHeader oldDelegate) =>
      title != oldDelegate.title ||
      expandedHeight != oldDelegate.expandedHeight ||
      onSwitchServer != oldDelegate.onSwitchServer;
}
