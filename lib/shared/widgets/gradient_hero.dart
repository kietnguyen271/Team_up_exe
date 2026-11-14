import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';

class GradientHero extends StatefulWidget {
  const GradientHero({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
    this.scrollOffset = 0,
  });

  final String title;
  final String? subtitle;
  final Widget? child;
  final double scrollOffset;

  @override
  State<GradientHero> createState() => _GradientHeroState();
}

class _GradientHeroState extends State<GradientHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradient = AnimationController(
    vsync: this,
    duration: MotionTokens.heroLoop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.of(context).reduced && TickerMode.valuesOf(context).enabled) {
      if (!_gradient.isAnimating) _gradient.repeat(reverse: true);
    } else {
      _gradient.stop();
    }
  }

  @override
  void dispose() {
    _gradient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ocean = Theme.of(context).extension<OceanColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final motion = Motion.of(context);
    final parallax = motion.reduced
        ? 0.0
        : -widget.scrollOffset.clamp(0, AppSizes.heroHeight).toDouble() /
            AppSizes.heroHeight *
            AppSizes.parallax;
    return Column(
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _gradient,
            builder: (context, child) => Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: AppSizes.heroHeight),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.r28),
                ),
                gradient: LinearGradient(
                  begin: Alignment(
                      -1 +
                          (motion.reduced ? 0 : _gradient.value) *
                              AppSizes.heroShift,
                      -1),
                  end: Alignment(
                      1 +
                          (motion.reduced ? 0 : _gradient.value) *
                              AppSizes.heroShift,
                      1),
                  colors: [ocean.deepNavy, ocean.midWater],
                ),
              ),
              child: child,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Transform.translate(
                offset: Offset(0, parallax),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.title,
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: scheme.onPrimary,
                                )),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(widget.subtitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: scheme.onPrimary)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.child != null)
          Transform.translate(
            offset: const Offset(0, -AppSpacing.s24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: ocean.seaGlass,
                borderRadius: BorderRadius.circular(AppRadius.r28),
                border: Border.all(color: ocean.foam),
              ),
              child: widget.child,
            ),
          ),
      ],
    );
  }
}
