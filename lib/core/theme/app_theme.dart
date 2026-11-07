import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppPalette.primary,
      onPrimary: AppPalette.onPrimary,
      surface: AppPalette.surface,
      surfaceContainer: AppPalette.surfaceContainer,
      onSurface: AppPalette.onSurface,
      onSurfaceVariant: AppPalette.onSurfaceVariant,
      error: AppPalette.error,
      errorContainer: AppPalette.errorContainer,
      outline: AppPalette.outline,
      outlineVariant: AppPalette.outlineVariant,
    );

    const textTheme = TextTheme(
      headlineSmall: TextStyle(
        fontSize: AppTextSizes.headline,
        height: AppTextSizes.headlineLine / AppTextSizes.headline,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: AppTextSizes.title,
        height: AppTextSizes.titleLine / AppTextSizes.title,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontSize: AppTextSizes.body,
        height: AppTextSizes.bodyLine / AppTextSizes.body,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTextSizes.small,
        height: AppTextSizes.smallLine / AppTextSizes.small,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontSize: AppTextSizes.small,
        height: AppTextSizes.smallLine / AppTextSizes.small,
        fontWeight: FontWeight.w500,
      ),
    );

    final commonButton = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size(AppSizes.touchTarget, AppSizes.touchTarget),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.s24,
          vertical: AppSpacing.s8,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
      ),
      textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Inter',
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      extensions: const [
        AppColors(
          accent: AppPalette.accent,
          success: AppPalette.success,
          successContainer: AppPalette.successContainer,
          warning: AppPalette.warning,
          warningContainer: AppPalette.warningContainer,
        ),
      ],
      filledButtonTheme: FilledButtonThemeData(
        style: commonButton.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.outlineVariant;
            }
            if (states.contains(WidgetState.hovered)) {
              return scheme.primary.withValues(alpha: 0.88);
            }
            return scheme.primary;
          }),
          foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(
                    color: scheme.onSurface,
                    width: AppSizes.focusOutlineWidth,
                  )
                : BorderSide.none,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: commonButton.copyWith(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused) ||
                      states.contains(WidgetState.hovered)
                  ? scheme.primary
                  : scheme.outline,
              width: states.contains(WidgetState.focused)
                  ? AppSizes.focusOutlineWidth
                  : AppSizes.outlineWidth,
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: commonButton.copyWith(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: 0.08),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(
                    color: scheme.primary,
                    width: AppSizes.focusOutlineWidth,
                  )
                : BorderSide.none,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: BorderSide(
            color: scheme.primary,
            width: AppSizes.focusOutlineWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          borderSide: BorderSide(
            color: scheme.error,
            width: AppSizes.focusOutlineWidth,
          ),
        ),
        errorStyle: textTheme.bodyMedium?.copyWith(color: scheme.error),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: AppElevation.level1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: AppElevation.level3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary,
        selectedIconTheme: IconThemeData(
          color: scheme.onPrimary,
          size: AppSizes.icon,
        ),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: AppSizes.icon,
        ),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        minWidth: AppSizes.railWidth,
        minExtendedWidth: AppSizes.railExtendedWidth,
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: AppElevation.level0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
    );
  }
}
