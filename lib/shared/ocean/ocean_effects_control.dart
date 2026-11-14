import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/motion/ocean_quality.dart';
import '../../core/theme/app_tokens.dart';

class OceanEffectsControl extends StatelessWidget {
  const OceanEffectsControl({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Ocean.settings,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.oceanEffects,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s8),
            DropdownButtonFormField<OceanEffectsMode>(
              key: ValueKey(Ocean.settings.mode),
              initialValue: Ocean.settings.mode,
              decoration: const InputDecoration(
                labelText: AppStrings.oceanEffects,
              ),
              items: [
                for (final mode in OceanEffectsMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(AppStrings.oceanModeLabel(mode.name)),
                  ),
              ],
              onChanged: (mode) {
                if (mode != null) Ocean.settings.setMode(mode);
              },
            ),
          ],
        ),
      );
}

class OceanEffectsMenu extends StatelessWidget {
  const OceanEffectsMenu({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Ocean.settings,
        builder: (context, _) => PopupMenuButton<OceanEffectsMode>(
          tooltip: AppStrings.oceanEffects,
          icon: const Icon(Icons.waves_outlined),
          onSelected: Ocean.settings.setMode,
          itemBuilder: (context) => [
            for (final mode in OceanEffectsMode.values)
              CheckedPopupMenuItem(
                value: mode,
                checked: Ocean.settings.mode == mode,
                child: Text(AppStrings.oceanModeLabel(mode.name)),
              ),
          ],
        ),
      );
}
