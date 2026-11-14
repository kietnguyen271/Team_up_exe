import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';

class CharacterCounter extends StatelessWidget {
  const CharacterCounter({
    super.key,
    required this.current,
    required this.maximum,
  });

  final int current;
  final int maximum;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nearLimit = current / maximum >= AppSizes.characterWarnFraction;
    return Text(
      '$current/$maximum',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: nearLimit ? AppPalette.warning : scheme.onSurfaceVariant,
          ),
    );
  }
}

class FocusGlowField extends StatefulWidget {
  const FocusGlowField({
    super.key,
    required this.label,
    this.controller,
    this.maxLength,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  State<FocusGlowField> createState() => _FocusGlowFieldState();
}

class _FocusGlowFieldState extends State<FocusGlowField> {
  late final FocusNode _focus = FocusNode()..addListener(_refresh);

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: Motion.of(context).use(MotionTokens.micro),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        boxShadow: _focus.hasFocus
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: AppSizes.glowOpacity),
                  blurRadius: AppSizes.glowBlur,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        maxLength: widget.maxLength,
        onChanged: widget.onChanged,
        decoration: InputDecoration(labelText: widget.label),
        buildCounter: widget.maxLength == null
            ? null
            : (context,
                    {required currentLength, required isFocused, maxLength}) =>
                CharacterCounter(
                  current: currentLength,
                  maximum: maxLength ?? widget.maxLength!,
                ),
      ),
    );
  }
}

class SkillChoiceChip extends StatelessWidget {
  const SkillChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: selected ? MotionTokens.navSelectedScale : 1,
        duration: Motion.of(context).use(MotionTokens.micro),
        curve: MotionTokens.pop,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
          child: FilterChip(
            label: Text(label),
            selected: selected,
            showCheckmark: true,
            onSelected: (value) {
              HapticFeedback.selectionClick();
              onSelected(value);
            },
          ),
        ),
      );
}
