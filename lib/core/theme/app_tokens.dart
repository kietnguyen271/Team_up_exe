import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;
}

abstract final class AppRadius {
  static const double r12 = 12;
  static const double r20 = 20;
  static const double r28 = 28;
}

abstract final class AppElevation {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level3 = 3;
}

abstract final class AppSizes {
  static const double touchTarget = 48;
  static const double icon = 24;
  static const double desktopBreakpoint = 900;
  static const double mobileBreakpoint = 600;
  static const double minWindowWidth = 1000;
  static const double minWindowHeight = 700;
  static const double defaultWindowWidth = 1280;
  static const double defaultWindowHeight = 800;
  static const double maxContentWidth = 1200;
  static const double authFormWidth = 500;
  static const double serverCardWidth = 320;
  static const double studentRoomTileMaxWidth = 220;
  static const double adminRoomTileMaxWidth = 320;
  static const double roomTableScale = 0.46;
  static const double roomSeatOrbitScale = 0.38;
  static const double roomSeatWidthScale = 0.16;
  static const double roomSeatHeightRatio = 0.8;
  static const double roomSeatBackHeightRatio = 0.3;
  static const double roomSeatSpacingRatio = 0.72;
  static const double pushJobsHeight = 160;
  static const double masterShare = 0.4;
  static const double outlineWidth = 1;
  static const double focusOutlineWidth = 2;
  static const double railWidth = 80;
  static const double railExtendedWidth = 192;
  static const double roomTileMin = 164;
  static const double heroHeight = 188;
  static const double oceanPreviewHeight = 240;
  static const double oceanPreviewMaxWidth = 440;
  static const double oceanGalleryMaxWidth = 920;
  static const double reefHeroFraction = 0.30;
  static const double reefHeroMinHeight = 88;
  static const double reefHeroMinExpandedHeight = 200;
  static const double reefHeroMaxExpandedHeight = 320;
  static const double reefCardAspectRatio = 1;
  static const double navHeight = 96;
  static const double seatMin = 20;
  static const double seatMax = 34;
  static const double avatarBadge = 16;
  static const double glowBlur = 20;
  static const double glowSpread = 2;
  static const double shimmerStripe = 0.3;
  static const double roomOrbit = 0.4;
  static const double roomTable = 0.6;
  static const double seatSpacing = 0.82;
  static const double seatOwnRing = 2.5;
  static const double statusDot = 8;
  static const double parallax = 16;
  static const double floatingDistance = 2;
  static const double lockedOpacity = 0.82;
  static const double glassBlur = 8;
  static const double heroShift = 0.25;
  static const double overlayOpacity = 0.55;
  static const double glassOpacity = 0.92;
  static const double glowOpacity = 0.15;
  static const double reefBorderOpacity = 0.28;
  static const double glassHighlightOpacity = 0.94;
  static const double glassShadowOpacity = 0.12;
  static const double panelAccentWidth = 4;
  static const double sectionIconSize = 40;
  static const int emptySeatDashes = 12;
  static const int confettiParticles = 12;
  static const double characterWarnFraction = 0.85;
}

abstract final class AppTextSizes {
  static const double hero = 32;
  static const double heroLine = 40;
  static const double headline = 24;
  static const double headlineLine = 32;
  static const double title = 20;
  static const double titleLine = 28;
  static const double body = 16;
  static const double bodyLine = 24;
  static const double small = 14;
  static const double smallLine = 20;
}

abstract final class AppLimits {
  static const int bioMax = 280;
}

abstract final class AppPalette {
  static const transparent = Color(0x00000000);
  static const primary = Color(0xFF1A3A6B);
  static const onPrimary = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFE8EEF7);
  static const onSurface = Color(0xFF1F2933);
  static const onSurfaceVariant = Color(0xFF4B5563);
  static const error = Color(0xFFB3261B);
  static const errorContainer = Color(0xFFFDECEA);
  static const outline = Color(0xFF8A94A6);
  static const outlineVariant = Color(0xFFD0D5DD);
  static const accent = Color(0xFFF27124);
  static const success = Color(0xFF1E6B3A);
  static const successContainer = Color(0xFFE3F4E8);
  static const warning = Color(0xFF8A5300);
  static const warningContainer = Color(0xFFFFF3D6);
  static const indigo = Color(0xFF4338CA);
  static const violet = Color(0xFF6D28D9);
  static const mint = Color(0xFF2DD4BF);
  static const lilac = Color(0xFFEEF0FF);
  static const peach = Color(0xFFFFF1E8);
  static const avatarFills = <Color>[
    primary,
    indigo,
    violet,
    success,
    warningContainer,
    surfaceContainer,
  ];
  static const avatarInk = <Color>[
    onPrimary,
    onPrimary,
    onPrimary,
    onPrimary,
    onSurface,
    onSurface,
  ];
}
