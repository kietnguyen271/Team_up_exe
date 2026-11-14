import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'ocean_colors.dart';

abstract final class AppTheme {
  static const oceanSystemBars = SystemUiOverlayStyle(
    statusBarColor: AppPalette.transparent,
    systemNavigationBarColor: AppPalette.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.light,
  );

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
      displaySmall: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: AppTextSizes.hero,
        height: AppTextSizes.heroLine / AppTextSizes.hero,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: AppTextSizes.headline,
        height: AppTextSizes.headlineLine / AppTextSizes.headline,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: AppTextSizes.title,
        height: AppTextSizes.titleLine / AppTextSizes.title,
        fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(AppRadius.r20),
        ),
      ),
      textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: OceanColors.light.foam,
      fontFamily: 'Inter',
      textTheme: textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      extensions: const [
        OceanColors.light,
        AppColors(
          accent: AppPalette.accent,
          success: AppPalette.success,
          successContainer: AppPalette.successContainer,
          warning: AppPalette.warning,
          warningContainer: AppPalette.warningContainer,
          indigo: AppPalette.indigo,
          violet: AppPalette.violet,
          mint: AppPalette.mint,
          lilac: AppPalette.lilac,
          peach: AppPalette.peach,
        ),
      ],
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(AppSizes.touchTarget, AppSizes.touchTarget),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: commonButton.copyWith(
          elevation: const WidgetStatePropertyAll(AppElevation.level1),
          shadowColor: WidgetStatePropertyAll(
            OceanColors.light.deepWater.withValues(
              alpha: AppSizes.glassShadowOpacity,
            ),
          ),
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
        fillColor: OceanColors.light.foam,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
          borderSide: BorderSide(color: OceanColors.light.teal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
          borderSide: BorderSide(color: OceanColors.light.teal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
          borderSide: BorderSide(
            color: scheme.primary,
            width: AppSizes.focusOutlineWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
          borderSide: BorderSide(
            color: scheme.error,
            width: AppSizes.focusOutlineWidth,
          ),
        ),
        errorStyle: textTheme.bodyMedium?.copyWith(color: scheme.error),
      ),
      cardTheme: CardThemeData(
        color: OceanColors.light.seaGlass,
        elevation: AppElevation.level1,
        surfaceTintColor: AppPalette.transparent,
        shadowColor: OceanColors.light.deepWater.withValues(
          alpha: AppSizes.glassShadowOpacity,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
          side: BorderSide(color: OceanColors.light.foam),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: OceanColors.light.foam,
        elevation: AppElevation.level3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r28),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: OceanColors.light.foam,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.r28),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: OceanColors.light.foam,
        selectedColor: OceanColors.light.lagoon,
        labelStyle: textTheme.labelLarge!.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelLarge!.copyWith(
          color: OceanColors.light.deepNavy,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: OceanColors.light.seaGlass,
        indicatorColor: OceanColors.light.lagoon,
        selectedIconTheme: IconThemeData(
          color: OceanColors.light.deepNavy,
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
        backgroundColor: OceanColors.light.seaGlass,
        indicatorColor: OceanColors.light.lagoon,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: OceanColors.light.seaGlass,
        foregroundColor: scheme.onSurface,
        elevation: AppElevation.level0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
    );
  }
}
