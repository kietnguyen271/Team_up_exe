import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ocean_colors.dart';
import 'ocean_quality.dart';

enum OceanLayer { depth, rays, caustics, waves, bubbles, life }

/// One reusable painter per layer. Paths and paints are retained between ticks.
class OceanLayerPainter extends CustomPainter {
  OceanLayerPainter({
    required this.layer,
    required this.colors,
    required this.phase,
    required this.settings,
    required this.quality,
    required Listenable repaint,
  }) : super(repaint: repaint) {
    _circle.addOval(Rect.fromCircle(center: Offset.zero, radius: 1));
    _fish
      ..moveTo(-1, 0)
      ..quadraticBezierTo(-0.35, -0.55, 0.55, 0)
      ..quadraticBezierTo(-0.35, 0.55, -1, 0)
      ..moveTo(0.55, 0)
      ..lineTo(1, -0.45)
      ..lineTo(1, 0.45)
      ..close();
    _jelly
      ..moveTo(-1, 0)
      ..quadraticBezierTo(0, -1.6, 1, 0)
      ..close()
      ..moveTo(-0.6, 0)
      ..lineTo(-0.5, 1.1)
      ..moveTo(0, 0)
      ..lineTo(0, 1.35)
      ..moveTo(0.6, 0)
      ..lineTo(0.5, 1.1);
    _rayPaint.color = colors.foam.withValues(alpha: 0.14);
    _causticPaint
      ..color = colors.foam.withValues(alpha: 0.33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    _wavePaints.addAll([
      Paint()..color = colors.foam.withValues(alpha: 0.25),
      Paint()..color = colors.aqua.withValues(alpha: 0.22),
      Paint()..color = colors.deepNavy.withValues(alpha: 0.13),
    ]);
    _bubblePaints.addAll([
      Paint()..color = colors.foam.withValues(alpha: 0.42),
      Paint()..color = colors.pearl.withValues(alpha: 0.56),
      Paint()..color = colors.foam.withValues(alpha: 0.28),
    ]);
    _fishPaint.color = colors.deepNavy.withValues(alpha: 0.22);
    _jellyPaint
      ..color = colors.pearl.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1;
    _weedPaint
      ..color = colors.deepNavy.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
  }

  final OceanLayer layer;
  final OceanColors colors;
  final Animation<double> phase;
  final OceanSettings settings;
  final OceanQuality Function() quality;
  final Path _path = Path();
  final Path _circle = Path();
  final Path _fish = Path();
  final Path _jelly = Path();
  final Paint _gradientPaint = Paint();
  final Paint _rayPaint = Paint();
  final Paint _causticPaint = Paint();
  final List<Paint> _wavePaints = [];
  final List<Paint> _bubblePaints = [];
  final Paint _fishPaint = Paint();
  final Paint _jellyPaint = Paint();
  final Paint _weedPaint = Paint();
  Size? _gradientSize;
  double? _gradientDepth;

  @override
  void paint(Canvas canvas, Size size) {
    final level = quality();
    if (layer != OceanLayer.depth && level == OceanQuality.off) return;
    switch (layer) {
      case OceanLayer.depth:
        _drawDepth(canvas, size);
      case OceanLayer.rays:
        if (level == OceanQuality.high || level == OceanQuality.medium) {
          _drawRays(canvas, size);
        }
      case OceanLayer.caustics:
        if (level == OceanQuality.high) _drawCaustics(canvas, size);
      case OceanLayer.waves:
        _drawWaves(canvas, size, level);
      case OceanLayer.bubbles:
        if (level == OceanQuality.high || level == OceanQuality.medium) {
          _drawBubbles(canvas, size, level);
        }
      case OceanLayer.life:
        if (level == OceanQuality.high || level == OceanQuality.medium) {
          _drawLife(canvas, size, level);
        }
    }
  }

  void _drawDepth(Canvas canvas, Size size) {
    final depth = settings.depth;
    if (_gradientSize != size || _gradientDepth != depth) {
      _gradientSize = size;
      _gradientDepth = depth;
      _gradientPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.lagoon,
          colors.aqua,
          colors.brightTeal,
          colors.midWater,
          colors.deepWater,
        ],
        stops: const [0, 0.25, 0.52, 0.76, 1],
      ).createShader(Rect.fromLTWH(
        0,
        -size.height * depth * 0.65,
        size.width,
        size.height * (1 - depth * 0.35) + size.height * depth * 0.65,
      ));
    }
    canvas.drawPaint(_gradientPaint);
  }

  void _drawRays(Canvas canvas, Size size) {
    if (settings.depth >= 0.43) return;
    final sway = math.sin(phase.value * math.pi * 2) * size.width * 0.018;
    for (var index = 0; index < 4; index++) {
      final top = size.width * (0.12 + index * 0.23) + sway;
      _path
        ..reset()
        ..moveTo(top, 0)
        ..lineTo(top + size.width * 0.065, 0)
        ..lineTo(top + size.width * 0.30, size.height * 0.75)
        ..lineTo(top - size.width * 0.12, size.height * 0.75)
        ..close();
      canvas.drawPath(_path, _rayPaint);
    }
  }

  void _drawCaustics(Canvas canvas, Size size) {
    if (settings.depth >= 0.40) return;
    for (var band = 0; band < 6; band++) {
      _path..reset();
      for (var step = 0; step <= 24; step++) {
        final x = size.width * step / 24;
        final y = size.height * (0.07 + band * 0.08) +
            math.sin(x / size.width * math.pi * 5 +
                    phase.value * math.pi * 2 +
                    band) *
                5;
        if (step == 0) {
          _path.moveTo(x, y);
        } else {
          _path.lineTo(x, y);
        }
      }
      canvas.drawPath(_path, _causticPaint);
    }
  }

  void _drawWaves(Canvas canvas, Size size, OceanQuality level) {
    final count = level == OceanQuality.low ? 2 : 3;
    for (var index = 0; index < count; index++) {
      final bottom = index == 2;
      final base = size.height * (bottom ? 0.87 : 0.08 + index * 0.045);
      final amplitude = size.height * (bottom ? 0.018 : 0.012);
      final speed = bottom ? 0.6 : 1 + index * 0.25;
      _path..reset();
      _path.moveTo(0, bottom ? size.height : 0);
      for (var step = 0; step <= 30; step++) {
        final x = size.width * step / 30;
        final y = base +
            math.sin(
                  x / size.width * math.pi * (3 + index) +
                      phase.value * math.pi * 2 * speed +
                      settings.depth * index,
                ) *
                amplitude;
        _path.lineTo(x, y);
      }
      _path
        ..lineTo(size.width, bottom ? size.height : 0)
        ..close();
      canvas.drawPath(_path, _wavePaints[index]);
    }
  }

  void _drawBubbles(Canvas canvas, Size size, OceanQuality level) {
    final count = level == OceanQuality.high ? 18 : 9;
    for (var index = 0; index < count; index++) {
      final progress =
          (phase.value * (0.55 + index % 4 * 0.13) + index / count) % 1;
      final x = size.width * ((index * 7 % 19 + 1) / 20) +
          math.sin(progress * math.pi * 2 + index) * size.width * 0.012;
      final y = size.height * (1 - progress) + settings.depth * index * 0.7;
      final radius = 2.5 + index % 5 * 1.8;
      canvas
        ..save()
        ..translate(x, y)
        ..scale(radius);
      canvas.drawPath(_circle, _bubblePaints[index % _bubblePaints.length]);
      canvas.restore();
    }
  }

  void _drawLife(Canvas canvas, Size size, OceanQuality level) {
    final count = level == OceanQuality.high ? 3 : 1;
    for (var index = 0; index < count; index++) {
      final progress = (phase.value * (0.32 + index * 0.08) + index * 0.37) % 1;
      final x = size.width * (progress * 1.2 - 0.1);
      final y = size.height * (0.32 + index * 0.18 + settings.depth * 0.06);
      final scale = 9 + index * 3.5;
      canvas
        ..save()
        ..translate(x, y)
        ..scale(scale);
      canvas.drawPath(_fish, _fishPaint);
      canvas.restore();
    }
    if (level == OceanQuality.high && settings.depth > 0.55) {
      canvas
        ..save()
        ..translate(
            size.width * 0.78, size.height * (0.52 + phase.value * 0.08))
        ..scale(12);
      canvas.drawPath(_jelly, _jellyPaint);
      canvas.restore();
    }
    for (var index = 0; index < 5; index++) {
      final x = size.width * (0.08 + index * 0.22);
      final sway = math.sin(phase.value * math.pi * 2 + index) * 8;
      _path
        ..reset()
        ..moveTo(x, size.height)
        ..quadraticBezierTo(
            x + sway, size.height * 0.90, x + sway * 1.5, size.height * 0.82);
      canvas.drawPath(_path, _weedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OceanLayerPainter oldDelegate) =>
      layer != oldDelegate.layer ||
      colors != oldDelegate.colors ||
      phase != oldDelegate.phase ||
      settings != oldDelegate.settings ||
      quality != oldDelegate.quality;
}
