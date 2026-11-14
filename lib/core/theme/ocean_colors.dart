import 'package:flutter/material.dart';

@immutable
class OceanColors extends ThemeExtension<OceanColors> {
  const OceanColors({
    required this.foam,
    required this.lagoon,
    required this.aqua,
    required this.teal,
    required this.brightTeal,
    required this.midWater,
    required this.deepWater,
    required this.deepNavy,
    required this.coral,
    required this.pearl,
    required this.sand,
    required this.kelp,
    required this.warning,
    required this.error,
    required this.seaGlass,
  });

  static const light = OceanColors(
    foam: Color(0xFFF2FBFF),
    lagoon: Color(0xFF8CE8F2),
    aqua: Color(0xFF19B5D0),
    teal: Color(0xFF0E7490),
    brightTeal: Color(0xFF0FA3C4),
    midWater: Color(0xFF0A6C8C),
    deepWater: Color(0xFF073B5C),
    deepNavy: Color(0xFF0B2545),
    coral: Color(0xFFFF7A59),
    pearl: Color(0xFFFFF6EC),
    sand: Color(0xFFF4E3C1),
    kelp: Color(0xFF1E6B3A),
    warning: Color(0xFF8A5300),
    error: Color(0xFFB3261B),
    seaGlass: Color(0xEBFFFFFF),
  );

  final Color foam;
  final Color lagoon;
  final Color aqua;
  final Color teal;
  final Color brightTeal;
  final Color midWater;
  final Color deepWater;
  final Color deepNavy;
  final Color coral;
  final Color pearl;
  final Color sand;
  final Color kelp;
  final Color warning;
  final Color error;
  final Color seaGlass;

  @override
  OceanColors copyWith({
    Color? foam,
    Color? lagoon,
    Color? aqua,
    Color? teal,
    Color? brightTeal,
    Color? midWater,
    Color? deepWater,
    Color? deepNavy,
    Color? coral,
    Color? pearl,
    Color? sand,
    Color? kelp,
    Color? warning,
    Color? error,
    Color? seaGlass,
  }) =>
      OceanColors(
        foam: foam ?? this.foam,
        lagoon: lagoon ?? this.lagoon,
        aqua: aqua ?? this.aqua,
        teal: teal ?? this.teal,
        brightTeal: brightTeal ?? this.brightTeal,
        midWater: midWater ?? this.midWater,
        deepWater: deepWater ?? this.deepWater,
        deepNavy: deepNavy ?? this.deepNavy,
        coral: coral ?? this.coral,
        pearl: pearl ?? this.pearl,
        sand: sand ?? this.sand,
        kelp: kelp ?? this.kelp,
        warning: warning ?? this.warning,
        error: error ?? this.error,
        seaGlass: seaGlass ?? this.seaGlass,
      );

  @override
  OceanColors lerp(ThemeExtension<OceanColors>? other, double t) {
    if (other is! OceanColors) return this;
    return OceanColors(
      foam: Color.lerp(foam, other.foam, t)!,
      lagoon: Color.lerp(lagoon, other.lagoon, t)!,
      aqua: Color.lerp(aqua, other.aqua, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      brightTeal: Color.lerp(brightTeal, other.brightTeal, t)!,
      midWater: Color.lerp(midWater, other.midWater, t)!,
      deepWater: Color.lerp(deepWater, other.deepWater, t)!,
      deepNavy: Color.lerp(deepNavy, other.deepNavy, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      pearl: Color.lerp(pearl, other.pearl, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      kelp: Color.lerp(kelp, other.kelp, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      seaGlass: Color.lerp(seaGlass, other.seaGlass, t)!,
    );
  }
}
