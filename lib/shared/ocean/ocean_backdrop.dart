import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/motion/ocean_painters.dart';
import '../../core/motion/ocean_quality.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';
import 'ocean_host.dart';

class OceanBackdrop extends StatefulWidget {
  const OceanBackdrop({
    super.key,
    this.qualityOverride,
    this.showDebugOverlay = true,
  });

  final OceanQuality? qualityOverride;
  final bool showDebugOverlay;

  @override
  State<OceanBackdrop> createState() => _OceanBackdropState();
}

class _OceanBackdropState extends State<OceanBackdrop> {
  OceanRuntime? _runtime;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = OceanScope.maybeOf(context);
    if (_runtime != next) {
      _runtime?.setClientVisible(this, false);
      _runtime = next;
    }
    final visible = (ModalRoute.of(context)?.isCurrent ?? true) &&
        TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runtime?.setClientVisible(this, visible);
    });
  }

  @override
  void dispose() {
    _runtime?.setClientVisible(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = _runtime ?? OceanScope.maybeOf(context);
    final colors =
        Theme.of(context).extension<OceanColors>() ?? OceanColors.light;
    if (runtime == null) {
      return ExcludeSemantics(
        child: IgnorePointer(
          child: CustomPaint(
            painter: OceanLayerPainter(
              layer: OceanLayer.depth,
              colors: colors,
              phase: const AlwaysStoppedAnimation<double>(0),
              settings: Ocean.settings,
              quality: () => OceanQuality.off,
              repaint: Ocean.settings,
            ),
          ),
        ),
      );
    }
    final active = runtime;
    final animated = Listenable.merge(
      [active.controller, active.settings, active],
    );
    final staticRepaint = Listenable.merge([active.settings, active]);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final layer in OceanLayer.values)
              RepaintBoundary(
                child: CustomPaint(
                  painter: OceanLayerPainter(
                    layer: layer,
                    colors: colors,
                    phase: active.controller,
                    settings: active.settings,
                    quality: () => active.qualityFor(widget.qualityOverride),
                    repaint:
                        layer == OceanLayer.depth ? staticRepaint : animated,
                  ),
                ),
              ),
            if (kDebugMode && widget.showDebugOverlay)
              Positioned(
                bottom: AppSpacing.s8,
                right: AppSpacing.s8,
                child: AnimatedBuilder(
                  animation: active,
                  builder: (context, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.deepNavy,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s4,
                      ),
                      child: Text(
                        AppStrings.oceanDebugStatus(
                          active.qualityFor(widget.qualityOverride).name,
                          active.qualityReason?.name,
                        ),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.foam,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OceanDebugBadge extends StatelessWidget {
  const OceanDebugBadge({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    final runtime = OceanScope.maybeOf(context);
    if (runtime == null) return const SizedBox.shrink();
    final colors =
        Theme.of(context).extension<OceanColors>() ?? OceanColors.light;
    return AnimatedBuilder(
      animation: runtime,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: colors.deepNavy,
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s4,
          ),
          child: Text(
            AppStrings.oceanDebugStatus(
              runtime.effectiveQuality.name,
              runtime.qualityReason?.name,
            ),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: colors.foam),
          ),
        ),
      ),
    );
  }
}
