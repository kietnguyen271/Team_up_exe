import 'package:animations/animations.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';

class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
  });
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    if (motion.reduced) return child;
    return child
        .animate(delay: motion.stagger(index))
        .fadeIn(duration: MotionTokens.standard, curve: MotionTokens.enter)
        .slideY(
            begin: MotionTokens.slideUpStart,
            end: 0,
            duration: MotionTokens.standard,
            curve: MotionTokens.enter);
  }
}

class MotionPageSwitcher extends StatelessWidget {
  const MotionPageSwitcher({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    if (motion.reduced) return child;
    return PageTransitionSwitcher(
      duration: MotionTokens.page,
      transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
        animation: primary,
        secondaryAnimation: secondary,
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: Theme.of(context).colorScheme.surface,
        child: child,
      ),
      child: child,
    );
  }
}

class CountUpText extends StatelessWidget {
  const CountUpText({super.key, required this.value, this.style});
  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (Motion.of(context).reduced) return Text('$value', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: MotionTokens.standard,
      curve: MotionTokens.enter,
      builder: (context, animated, _) =>
          Text('${animated.round()}', style: style),
    );
  }
}

class AnimatedCheck extends StatelessWidget {
  const AnimatedCheck({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.check_circle_rounded,
        size: AppSizes.touchTarget,
        color: color ?? Theme.of(context).colorScheme.primary);
    if (Motion.of(context).reduced) return icon;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MotionTokens.standard,
      curve: MotionTokens.enter,
      builder: (context, progress, child) => SizedBox(
        width: AppSizes.touchTarget,
        height: AppSizes.touchTarget,
        child: ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Transform.scale(
              scale: MotionTokens.checkStartScale +
                  (1 - MotionTokens.checkStartScale) * progress,
              child: child,
            ),
          ),
        ),
      ),
      child: icon,
    );
  }
}

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst(
      {super.key, required this.celebrate, required this.child});
  final bool celebrate;
  final Widget child;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> {
  late final ConfettiController _controller =
      ConfettiController(duration: MotionTokens.celebration);

  @override
  void didUpdateWidget(covariant ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrate &&
        !oldWidget.celebrate &&
        !Motion.of(context).reduced &&
        TickerMode.valuesOf(context).enabled) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.of(context).reduced) return widget.child;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,
        IgnorePointer(
          child: RepaintBoundary(
            child: ConfettiWidget(
              confettiController: _controller,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: AppSizes.confettiParticles,
              colors: const [
                AppPalette.primary,
                AppPalette.indigo,
                AppPalette.mint,
                AppPalette.accent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
