import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/motion/reef_room_painter.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';

/// Count-only room card shared by the student and admin room grids.
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
    final ocean = Theme.of(context).extension<OceanColors>()!;
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
        margin: EdgeInsets.zero,
        color: ocean.seaGlass,
        surfaceTintColor: AppPalette.transparent,
        elevation: AppElevation.level1,
        shadowColor: ocean.deepWater.withValues(alpha: AppSizes.glowOpacity),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
          side: BorderSide(
            color: isMine ? ocean.teal : ocean.foam,
            width: isMine ? AppSizes.focusOutlineWidth : AppSizes.outlineWidth,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r20),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          color: ocean.deepNavy,
                        ),
                      ),
                    ),
                    if (action != null) action!,
                  ],
                ),
                if (isMine)
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: ocean.teal, size: AppSizes.avatarBadge),
                      const SizedBox(width: AppSpacing.s4),
                      Flexible(
                        child: Text(
                          AppStrings.yourRoom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            color: ocean.deepNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: ReefRoomPainter(
                        ocean: ocean,
                        capacity: capacity,
                        members: members,
                        isMine: isMine,
                        locked: status == AppStrings.roomLocked,
                      ),
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: ocean.foam.withValues(
                              alpha: AppSizes.glassOpacity,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s4,
                            ),
                            child: Text(
                              '$members/$capacity',
                              style: textTheme.labelLarge?.copyWith(
                                color: ocean.deepNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _RoomStatusPill(status: status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomStatusPill extends StatelessWidget {
  const _RoomStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ocean = Theme.of(context).extension<OceanColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final (icon, foreground, background) = switch (status) {
      AppStrings.roomOpen => (
          Icons.circle,
          ocean.kelp,
          AppPalette.successContainer
        ),
      AppStrings.roomFull => (
          Icons.groups_rounded,
          ocean.warning,
          AppPalette.warningContainer
        ),
      AppStrings.roomLocked => (
          Icons.lock_rounded,
          scheme.onSurfaceVariant,
          AppPalette.surfaceContainer
        ),
      AppStrings.roomEmpty => (
          Icons.bubble_chart_outlined,
          ocean.teal,
          ocean.foam
        ),
      _ => (Icons.info_outline, scheme.onSurfaceVariant, ocean.foam),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.r28),
        border: Border.all(
          color: foreground.withValues(alpha: AppSizes.reefBorderOpacity),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: AppSizes.avatarBadge),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
