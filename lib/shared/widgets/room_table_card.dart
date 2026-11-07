import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_tokens.dart';

/// A square room tile with one visible chair per place at the table.
class RoomTableCard extends StatelessWidget {
  const RoomTableCard({
    super.key,
    required this.name,
    required this.capacity,
    required this.members,
    required this.status,
    required this.onTap,
    this.isMine = false,
    this.action,
  });

  final String name;
  final int capacity;
  final int members;
  final String status;
  final VoidCallback onTap;
  final bool isMine;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: AppStrings.roomCardSummary(
        name,
        members,
        capacity,
        status,
        isMine: isMine,
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          side: BorderSide(
            color: isMine ? scheme.primary : scheme.outlineVariant,
            width: isMine ? AppSizes.focusOutlineWidth : AppSizes.outlineWidth,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s8),
            child: Column(
              children: [
                Row(
                  children: [
                    if (isMine) ...[
                      Icon(Icons.star,
                          size: AppSizes.icon, color: scheme.primary),
                      const SizedBox(width: AppSpacing.s4),
                    ],
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge,
                      ),
                    ),
                    if (action != null) action!,
                  ],
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _RoomSeatsPainter(
                      capacity: capacity,
                      members: members,
                      scheme: scheme,
                    ),
                    child: Center(
                      child: Text(
                        '$members/$capacity',
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomSeatsPainter extends CustomPainter {
  const _RoomSeatsPainter({
    required this.capacity,
    required this.members,
    required this.scheme,
  });

  final int capacity;
  final int members;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final tableSide = side * AppSizes.roomTableScale;
    final tableRect = Rect.fromCenter(
      center: center,
      width: tableSide,
      height: tableSide,
    );
    final table = RRect.fromRectAndRadius(
      tableRect,
      const Radius.circular(AppRadius.r12),
    );
    canvas.drawRRect(table, Paint()..color = scheme.surfaceContainer);
    canvas.drawRRect(
      table,
      Paint()
        ..color = scheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.outlineWidth,
    );

    if (capacity <= 0) return;
    final orbit = side * AppSizes.roomSeatOrbitScale;
    final circumference = 2 * math.pi * orbit;
    final seatWidth = math.min(
      AppSizes.icon,
      math.min(
        side * AppSizes.roomSeatWidthScale,
        circumference / capacity * AppSizes.roomSeatSpacingRatio,
      ),
    );
    final seatHeight = seatWidth * AppSizes.roomSeatHeightRatio;
    final occupiedCount = members.clamp(0, capacity);
    for (var index = 0; index < capacity; index++) {
      final angle = -math.pi / 2 + 2 * math.pi * index / capacity;
      final occupied = index < occupiedCount;
      final chairPaint = Paint()
        ..color = occupied ? scheme.primary : scheme.surface;
      final outlinePaint = Paint()
        ..color = occupied ? scheme.primary : scheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.outlineWidth;
      canvas.save();
      canvas.translate(
        center.dx + math.cos(angle) * orbit,
        center.dy + math.sin(angle) * orbit,
      );
      canvas.rotate(angle + math.pi / 2);
      final seat = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: seatWidth,
          height: seatHeight,
        ),
        const Radius.circular(AppSpacing.s4),
      );
      final back = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -seatWidth / 2,
          -seatHeight,
          seatWidth,
          seatHeight * AppSizes.roomSeatBackHeightRatio,
        ),
        const Radius.circular(AppSpacing.s4),
      );
      canvas.drawRRect(seat, chairPaint);
      canvas.drawRRect(seat, outlinePaint);
      canvas.drawRRect(back, chairPaint);
      canvas.drawRRect(back, outlinePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RoomSeatsPainter oldDelegate) =>
      capacity != oldDelegate.capacity ||
      members != oldDelegate.members ||
      scheme != oldDelegate.scheme;
}
