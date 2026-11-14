import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';

class FloatingNavDestination {
  const FloatingNavDestination({
    required this.icon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final int badge;
}

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<FloatingNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ocean = Theme.of(context).extension<OceanColors>()!;
    final motion = Motion.of(context);
    final bar = Container(
      height: AppSizes.navHeight,
      decoration: BoxDecoration(
        color: motion.reduced ? scheme.surface : ocean.seaGlass,
        borderRadius: BorderRadius.circular(AppRadius.r28),
        border: Border.all(color: ocean.foam),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(
              destinations.length == 1
                  ? 0
                  : -1 + selectedIndex * 2 / (destinations.length - 1),
              0,
            ),
            duration: motion.use(MotionTokens.standard),
            curve: MotionTokens.enter,
            child: FractionallySizedBox(
              widthFactor: 1 / destinations.length,
              child: Container(
                height: AppSizes.navHeight - AppSpacing.s8,
                margin: const EdgeInsets.all(AppSpacing.s4),
                decoration: BoxDecoration(
                  color: ocean.lagoon,
                  borderRadius: BorderRadius.circular(AppRadius.r28),
                ),
              ),
            ),
          ),
          Row(children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == selectedIndex,
                  label: destinations[i].label,
                  child: InkWell(
                    onTap: () => onSelected(i),
                    borderRadius: BorderRadius.circular(AppRadius.r28),
                    child: Container(
                      height: AppSizes.navHeight - AppSpacing.s8,
                      margin: const EdgeInsets.all(AppSpacing.s4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedScale(
                                scale: i == selectedIndex
                                    ? MotionTokens.navSelectedScale
                                    : 1,
                                duration: motion.use(MotionTokens.micro),
                                curve: MotionTokens.pop,
                                child: Icon(destinations[i].icon,
                                    color: i == selectedIndex
                                        ? scheme.primary
                                        : scheme.onSurfaceVariant,
                                    size: AppSizes.icon),
                              ),
                              if (destinations[i].badge > 0)
                                Positioned(
                                  right: -AppSpacing.s16,
                                  top: -AppSpacing.s8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.s4),
                                    decoration: BoxDecoration(
                                      color: scheme.error,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.r12),
                                    ),
                                    child: Text('${destinations[i].badge}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                                color: scheme.onPrimary)),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            destinations[i].label,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: i == selectedIndex
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ],
      ),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.r28),
          child: motion.reduced
              ? bar
              : BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: AppSizes.glassBlur, sigmaY: AppSizes.glassBlur),
                  child: bar,
                ),
        ),
      ),
    );
  }
}
