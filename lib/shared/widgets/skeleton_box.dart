import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.radius = AppRadius.r12,
    this.animate = false,
  });

  final double height;
  final double? width;
  final double radius;
  final bool animate;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: MotionTokens.celebration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animate &&
        !Motion.of(context).reduced &&
        TickerMode.valuesOf(context).enabled) {
      if (!_sweep.isAnimating) _sweep.repeat();
    } else {
      _sweep.stop();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, child) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: Motion.of(context).reduced || !widget.animate
                ? null
                : LinearGradient(
                    begin: Alignment(
                        MotionTokens.shimmerStart +
                            _sweep.value * MotionTokens.shimmerTravel,
                        0),
                    end: Alignment(
                        MotionTokens.shimmerStart +
                            1 +
                            _sweep.value * MotionTokens.shimmerTravel,
                        0),
                    colors: [
                      scheme.surfaceContainer,
                      AppPalette.lilac,
                      scheme.surfaceContainer,
                    ],
                  ),
            color: Motion.of(context).reduced || !widget.animate
                ? scheme.surfaceContainer
                : null,
          ),
        ),
      ),
    );
  }
}

class RoomTileSkeleton extends StatelessWidget {
  const RoomTileSkeleton({super.key, this.animate = true});
  final bool animate;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1,
        child: SkeletonBox(
          height: AppSizes.roomTileMin,
          radius: AppRadius.r20,
          animate: animate,
        ),
      );
}

class MemberRowSkeleton extends StatelessWidget {
  const MemberRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          SkeletonBox(
              height: AppSizes.touchTarget,
              width: AppSizes.touchTarget,
              radius: AppRadius.r28),
          SizedBox(width: AppSpacing.s16),
          Expanded(child: SkeletonBox(height: AppSizes.touchTarget)),
        ],
      );
}
