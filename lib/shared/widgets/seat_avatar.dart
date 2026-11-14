import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';

class SeatMember {
  const SeatMember({
    required this.id,
    required this.name,
    this.isLeader = false,
    this.isSelf = false,
  });

  final String id;
  final String name;
  final bool isLeader;
  final bool isSelf;
}

class SeatAvatar extends StatelessWidget {
  const SeatAvatar({super.key, required this.size, this.member});

  final double size;
  final SeatMember? member;

  int _paletteIndex(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash % AppPalette.avatarFills.length;
  }

  @override
  Widget build(BuildContext context) {
    final member = this.member;
    final ocean = Theme.of(context).extension<OceanColors>()!;
    if (member == null) {
      return RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _DashedCirclePainter(
            ocean.teal,
            ocean.foam.withValues(alpha: AppSizes.glassOpacity),
          ),
        ),
      );
    }
    final index = _paletteIndex(member.id);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppPalette.avatarFills[index],
            shape: BoxShape.circle,
            border: Border.all(
              color: member.isSelf ? ocean.teal : ocean.foam,
              width:
                  member.isSelf ? AppSizes.seatOwnRing : AppSizes.outlineWidth,
            ),
            boxShadow: member.isSelf
                ? [
                    BoxShadow(
                      color: ocean.aqua.withValues(alpha: AppSizes.glowOpacity),
                      blurRadius: AppSizes.glowBlur,
                    ),
                  ]
                : null,
          ),
          child: Text(
            member.name.trim().isEmpty
                ? '?'
                : member.name.trim().characters.first.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppPalette.avatarInk[index],
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (member.isLeader)
          Positioned(
            right: -AppSpacing.s4,
            top: -AppSpacing.s4,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: AppSizes.avatarBadge,
              color: ocean.deepNavy,
            ),
          ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter(this.color, this.fill);

  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.outlineWidth;
    final center = size.center(Offset.zero);
    final radius =
        math.min(size.width, size.height) / 2 - AppSizes.outlineWidth;
    canvas.drawCircle(center, radius, Paint()..color = fill);
    const dashCount = AppSizes.emptySeatDashes;
    for (var i = 0; i < dashCount; i++) {
      final start = 2 * math.pi * i / dashCount;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.pi / dashCount,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fill != fill;
}
