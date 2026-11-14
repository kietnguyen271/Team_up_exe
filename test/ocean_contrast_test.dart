import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/core/theme/app_tokens.dart';
import 'package:teamup_exe/core/theme/ocean_colors.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('Ocean text and controls meet WCAG contrast', () {
    const ocean = OceanColors.light;
    final pairs = <(String, Color, Color, double)>[
      ('body on white', AppPalette.onSurface, AppPalette.surface, 4.5),
      ('body on foam', AppPalette.onSurface, ocean.foam, 4.5),
      ('body on glass', AppPalette.onSurface, ocean.seaGlass, 4.5),
      (
        'body on glass over deep navy',
        AppPalette.onSurface,
        Color.alphaBlend(ocean.seaGlass, ocean.deepNavy),
        4.5
      ),
      (
        'body on glass over deep water',
        AppPalette.onSurface,
        Color.alphaBlend(ocean.seaGlass, ocean.deepWater),
        4.5
      ),
      (
        'secondary on white',
        AppPalette.onSurfaceVariant,
        AppPalette.surface,
        4.5
      ),
      ('secondary on foam', AppPalette.onSurfaceVariant, ocean.foam, 4.5),
      (
        'secondary on glass over deep water',
        AppPalette.onSurfaceVariant,
        Color.alphaBlend(ocean.seaGlass, ocean.deepWater),
        4.5
      ),
      ('white on navy', AppPalette.onPrimary, AppPalette.primary, 4.5),
      ('white on deep navy', ocean.foam, ocean.deepNavy, 4.5),
      ('navy on white', AppPalette.primary, AppPalette.surface, 4.5),
      ('navy on foam', AppPalette.primary, ocean.foam, 4.5),
      ('navy on lagoon', AppPalette.primary, ocean.lagoon, 4.5),
      (
        'deep navy hero glass on surface water',
        ocean.deepNavy,
        Color.alphaBlend(ocean.seaGlass, ocean.lagoon),
        4.5
      ),
      (
        'deep navy hero glass on deep water',
        ocean.deepNavy,
        Color.alphaBlend(ocean.seaGlass, ocean.deepWater),
        4.5
      ),
      ('deep navy on shallow water', ocean.deepNavy, ocean.lagoon, 4.5),
      ('deep navy on bright mid water', ocean.deepNavy, ocean.brightTeal, 4.5),
      ('foam on deep water', ocean.foam, ocean.deepWater, 4.5),
      ('white on teal button end', AppPalette.onPrimary, ocean.teal, 4.5),
      ('navy control on white', AppPalette.primary, AppPalette.surface, 3),
      ('navy control on foam', AppPalette.primary, ocean.foam, 3),
    ];
    for (final (name, foreground, background, minimum) in pairs) {
      expect(contrast(foreground, background), greaterThanOrEqualTo(minimum),
          reason: name);
    }
  });
}
