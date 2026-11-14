import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.indigo,
    required this.violet,
    required this.mint,
    required this.lilac,
    required this.peach,
  });

  final Color accent;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color indigo;
  final Color violet;
  final Color mint;
  final Color lilac;
  final Color peach;

  @override
  AppColors copyWith({
    Color? accent,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? indigo,
    Color? violet,
    Color? mint,
    Color? lilac,
    Color? peach,
  }) =>
      AppColors(
        accent: accent ?? this.accent,
        success: success ?? this.success,
        successContainer: successContainer ?? this.successContainer,
        warning: warning ?? this.warning,
        warningContainer: warningContainer ?? this.warningContainer,
        indigo: indigo ?? this.indigo,
        violet: violet ?? this.violet,
        mint: mint ?? this.mint,
        lilac: lilac ?? this.lilac,
        peach: peach ?? this.peach,
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
      indigo: Color.lerp(indigo, other.indigo, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      lilac: Color.lerp(lilac, other.lilac, t)!,
      peach: Color.lerp(peach, other.peach, t)!,
    );
  }
}
