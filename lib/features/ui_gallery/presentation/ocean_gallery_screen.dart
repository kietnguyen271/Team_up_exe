import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/ocean_quality.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/ocean_colors.dart';
import '../../../shared/ocean/ocean_backdrop.dart';
import '../../../shared/ocean/ocean_effects_control.dart';

class OceanGalleryScreen extends StatelessWidget {
  const OceanGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OceanColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.oceanGallery)),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppSizes.oceanGalleryMaxWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              Text(AppStrings.oceanGalleryIntro,
                  style: Theme.of(context).textTheme.bodyLarge),
              const Align(
                alignment: Alignment.centerLeft,
                child: OceanDebugBadge(),
              ),
              const SizedBox(height: AppSpacing.s16),
              const OceanEffectsControl(),
              AnimatedBuilder(
                animation: Motion.settings,
                builder: (context, _) => SwitchListTile(
                  title: const Text(AppStrings.uiReduceMotion),
                  value: Motion.settings.reduced,
                  onChanged: Motion.settings.setReduced,
                ),
              ),
              for (final level in OceanQuality.values) ...[
                const SizedBox(height: AppSpacing.s16),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.oceanPreviewMaxWidth,
                  ),
                  child: SizedBox(
                    height: AppSizes.oceanPreviewHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.r20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          OceanBackdrop(
                            qualityOverride: level,
                            showDebugOverlay: true,
                          ),
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.s16),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.deepNavy,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.r12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.s8),
                                  child: Text(
                                    AppStrings.oceanModeLabel(level.name),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: colors.foam),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
