import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/ocean_colors.dart';

/// Original vector shell used by both live room cards and the UI gallery.
class ReefPlatformPainter extends CustomPainter {
  const ReefPlatformPainter({
    required this.ocean,
    this.isMine = false,
    this.locked = false,
  });

  final OceanColors ocean;
  final bool isMine;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final shell = Path()
      ..moveTo(width * 0.5, height * 0.92)
      ..cubicTo(width * 0.23, height * 0.81, width * 0.11, height * 0.49,
          width * 0.17, height * 0.31)
      ..quadraticBezierTo(
          width * 0.20, height * 0.18, width * 0.29, height * 0.22)
      ..quadraticBezierTo(
          width * 0.35, height * 0.09, width * 0.43, height * 0.18)
      ..quadraticBezierTo(
          width * 0.5, height * 0.06, width * 0.57, height * 0.18)
      ..quadraticBezierTo(
          width * 0.65, height * 0.09, width * 0.71, height * 0.22)
      ..quadraticBezierTo(
          width * 0.80, height * 0.18, width * 0.83, height * 0.31)
      ..cubicTo(width * 0.89, height * 0.49, width * 0.77, height * 0.81,
          width * 0.5, height * 0.92)
      ..close();

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.5, height * 0.77),
        width: width * 0.69,
        height: height * 0.22,
      ),
      Paint()..color = ocean.deepWater.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      shell,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: locked
              ? [ocean.foam, ocean.lagoon]
              : [ocean.pearl, ocean.sand, ocean.lagoon],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      shell,
      Paint()
        ..color = isMine ? ocean.teal : ocean.midWater
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMine ? 2.8 : 1.6,
    );

    final ridgePaint = Paint()
      ..color = ocean.deepWater.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var index = -2; index <= 2; index++) {
      final ridge = Path()
        ..moveTo(width * 0.5, height * 0.84)
        ..quadraticBezierTo(width * (0.5 + index * 0.11), height * 0.46,
            width * (0.5 + index * 0.12), height * 0.22);
      canvas.drawPath(ridge, ridgePaint);
    }
    if (isMine) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(width * 0.5, height * 0.52),
          width: width * 0.94,
          height: height * 0.91,
        ),
        Paint()
          ..color = ocean.aqua.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ReefPlatformPainter oldDelegate) =>
      ocean != oldDelegate.ocean ||
      isMine != oldDelegate.isMine ||
      locked != oldDelegate.locked;
}

/// Count-only room preview. Member identity is deliberately not inferred from IDs.
class ReefRoomPainter extends CustomPainter {
  const ReefRoomPainter({
    required this.ocean,
    required this.capacity,
    required this.members,
    required this.isMine,
    required this.locked,
  });

  final OceanColors ocean;
  final int capacity;
  final int members;
  final bool isMine;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = size.center(Offset.zero);
    final platformSide = side * 0.62;
    canvas.save();
    canvas.translate(
        center.dx - platformSide / 2, center.dy - platformSide / 2);
    ReefPlatformPainter(ocean: ocean, isMine: isMine, locked: locked)
        .paint(canvas, Size.square(platformSide));
    canvas.restore();

    if (capacity <= 0) return;
    final orbit = side * 0.40;
    final radius =
        math.min(side * 0.095, (2 * math.pi * orbit / capacity) * 0.34);
    final filled = members.clamp(0, capacity);
    for (var index = 0; index < capacity; index++) {
      final angle = -math.pi / 2 + index * 2 * math.pi / capacity;
      final seat = Offset(center.dx + math.cos(angle) * orbit,
          center.dy + math.sin(angle) * orbit);
      final rect = Rect.fromCircle(center: seat, radius: radius);
      if (index < filled) {
        canvas.drawCircle(
          seat,
          radius + 1.4,
          Paint()..color = ocean.foam,
        );
        canvas.drawCircle(
          seat,
          radius,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.45),
              colors: [ocean.aqua, ocean.teal],
            ).createShader(rect),
        );
        canvas.drawCircle(
          Offset(seat.dx - radius * 0.34, seat.dy - radius * 0.34),
          radius * 0.20,
          Paint()..color = ocean.foam.withValues(alpha: 0.86),
        );
      } else {
        canvas.drawCircle(
          seat,
          radius,
          Paint()..color = ocean.foam.withValues(alpha: 0.58),
        );
        final dashPaint = Paint()
          ..color = ocean.teal
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        for (var dash = 0; dash < 8; dash++) {
          canvas.drawArc(
              rect, dash * math.pi / 4, math.pi / 7, false, dashPaint);
        }
      }
    }

    final coral = Path()
      ..moveTo(center.dx - side * 0.31, center.dy + side * 0.34)
      ..quadraticBezierTo(center.dx - side * 0.33, center.dy + side * 0.23,
          center.dx - side * 0.39, center.dy + side * 0.18)
      ..moveTo(center.dx - side * 0.33, center.dy + side * 0.27)
      ..lineTo(center.dx - side * 0.25, center.dy + side * 0.19);
    canvas.drawPath(
      coral,
      Paint()
        ..color = ocean.coral.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant ReefRoomPainter oldDelegate) =>
      ocean != oldDelegate.ocean ||
      capacity != oldDelegate.capacity ||
      members != oldDelegate.members ||
      isMine != oldDelegate.isMine ||
      locked != oldDelegate.locked;
}
