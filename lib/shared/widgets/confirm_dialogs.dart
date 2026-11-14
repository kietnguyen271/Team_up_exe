import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';

Future<bool> _showMotionDialog(BuildContext context, Widget child) async {
  final motion = Motion.of(context);
  return await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: AppStrings.cancel,
        barrierColor: Theme.of(context)
            .colorScheme
            .onSurface
            .withValues(alpha: AppSizes.overlayOpacity),
        transitionDuration: motion.use(MotionTokens.standard),
        pageBuilder: (context, _, __) => child,
        transitionBuilder: (context, animation, _, child) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: MotionTokens.dialogStartScale, end: 1)
                .chain(CurveTween(curve: MotionTokens.pop))
                .animate(animation),
            child: child,
          ),
        ),
      ) ??
      false;
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({super.key, required this.title, required this.message});
  final String title;
  final String message;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
  }) =>
      _showMotionDialog(
        context,
        ConfirmDialog(title: title, message: message),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop(true);
            },
            child: const Text(AppStrings.confirm),
          ),
        ],
      );
}

class TypedConfirmDialog extends StatefulWidget {
  const TypedConfirmDialog({
    super.key,
    required this.title,
    required this.instruction,
    required this.expected,
  });
  final String title;
  final String instruction;
  final String expected;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String instruction,
    required String expected,
  }) =>
      _showMotionDialog(
        context,
        TypedConfirmDialog(
          title: title,
          instruction: instruction,
          expected: expected,
        ),
      );

  @override
  State<TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<TypedConfirmDialog> {
  final _controller = TextEditingController();
  bool _invalid = false;
  bool _shake = false;
  Timer? _shakeTimer;

  bool get _matches => _controller.text.trim() == widget.expected;

  void _showInvalid() {
    if (_matches) return;
    setState(() {
      _invalid = true;
      _shake = true;
    });
    _shakeTimer?.cancel();
    _shakeTimer = Timer(MotionTokens.micro, () {
      if (mounted) setState(() => _shake = false);
    });
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.instruction),
              const SizedBox(height: AppSpacing.s16),
              AnimatedSlide(
                offset: _shake && !Motion.of(context).reduced
                    ? const Offset(MotionTokens.invalidShake, 0)
                    : Offset.zero,
                duration: Motion.of(context).use(MotionTokens.micro),
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() => _invalid = false),
                  onSubmitted: (_) => _showInvalid(),
                  decoration: InputDecoration(
                    labelText: widget.expected,
                    errorText: _invalid ? AppStrings.wrongConfirmation : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          AnimatedScale(
            scale: _matches ? 1 : MotionTokens.pressedScale,
            duration: Motion.of(context).use(MotionTokens.micro),
            curve: MotionTokens.pop,
            child: FilledButton(
              onPressed: _matches
                  ? () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(true);
                    }
                  : null,
              child: const Text(AppStrings.confirm),
            ),
          ),
        ],
      );
}
