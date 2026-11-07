import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
  });

  final Color accent;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;

  @override
  AppColors copyWith({
    Color? accent,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
  }) =>
      AppColors(
        accent: accent ?? this.accent,
        success: success ?? this.success,
        successContainer: successContainer ?? this.successContainer,
        warning: warning ?? this.warning,
        warningContainer: warningContainer ?? this.warningContainer,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
    );
  }
}
