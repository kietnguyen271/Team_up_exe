import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/motion/app_motion.dart';
import '../../core/theme/app_tokens.dart';

enum RoomStatus { empty, open, full, locked }

class StatusChip extends StatefulWidget {
  const StatusChip({super.key, required this.status, this.animate = false});

  final RoomStatus status;
  final bool animate;

  @override
  State<StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<StatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: MotionTokens.celebration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animate &&
        widget.status == RoomStatus.open &&
        !Motion.of(context).reduced &&
        TickerMode.valuesOf(context).enabled) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void didUpdateWidget(covariant StatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate || widget.status != RoomStatus.open) {
      _pulse.stop();
    } else if (!Motion.of(context).reduced &&
        TickerMode.valuesOf(context).enabled) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = switch (widget.status) {
      RoomStatus.empty => AppStrings.roomEmpty,
      RoomStatus.open => AppStrings.roomOpen,
      RoomStatus.full => AppStrings.roomFull,
      RoomStatus.locked => AppStrings.roomLocked,
    };
    final icon = switch (widget.status) {
      RoomStatus.empty => Icons.event_seat_outlined,
      RoomStatus.open => Icons.circle,
      RoomStatus.full => Icons.people_rounded,
      RoomStatus.locked => Icons.lock_rounded,
    };
    final foreground = switch (widget.status) {
      RoomStatus.empty || RoomStatus.locked => scheme.onSurfaceVariant,
      RoomStatus.open => AppPalette.success,
      RoomStatus.full => AppPalette.warning,
    };
    final background = switch (widget.status) {
      RoomStatus.empty || RoomStatus.locked => scheme.surfaceContainer,
      RoomStatus.open => AppPalette.successContainer,
      RoomStatus.full => AppPalette.warningContainer,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.r28),
        border: Border.all(
            color: foreground.withValues(alpha: AppSizes.glowOpacity)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.status == RoomStatus.open)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Opacity(
                opacity: Motion.of(context).reduced
                    ? 1
                    : MotionTokens.pulseMinOpacity +
                        _pulse.value * (1 - MotionTokens.pulseMinOpacity),
                child: Icon(icon, color: foreground, size: AppSizes.statusDot),
              ),
            )
          else
            Icon(icon, color: foreground, size: AppSizes.avatarBadge),
          const SizedBox(width: AppSpacing.s4),
          Flexible(
            child: Text(
              label,
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
    );
  }
}
