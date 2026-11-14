import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/motion/app_motion.dart';
import '../../core/motion/reef_room_painter.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/ocean_colors.dart';
import 'pressable_scale.dart';
import 'seat_avatar.dart';
import 'status_chip.dart';

/// The same table can be used in a grid or enlarged in a room header.
class RoomTile extends StatefulWidget {
  const RoomTile({
    super.key,
    required this.id,
    required this.name,
    required this.capacity,
    required this.members,
    required this.status,
    this.isMine = false,
    this.onTap,
    this.animateIdle = false,
    this.hero = true,
  }) : assert(capacity >= 2 && capacity <= 12);

  final String id;
  final String name;
  final int capacity;
  final List<SeatMember> members;
  final RoomStatus status;
  final bool isMine;
  final VoidCallback? onTap;
  final bool animateIdle;
  final bool hero;

  @override
  State<RoomTile> createState() => _RoomTileState();
}

class _RoomTileState extends State<RoomTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: MotionTokens.floatLoop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFloat();
  }

  @override
  void didUpdateWidget(covariant RoomTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFloat();
  }

  void _syncFloat() {
    if (widget.animateIdle &&
        !Motion.of(context).reduced &&
        TickerMode.valuesOf(context).enabled) {
      if (!_float.isAnimating) _float.repeat(reverse: true);
    } else {
      _float.stop();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ocean = Theme.of(context).extension<OceanColors>()!;
    final semantic = AppStrings.roomTileSemantics(
      widget.name,
      widget.members.length,
      widget.capacity,
      switch (widget.status) {
        RoomStatus.empty => AppStrings.roomEmpty,
        RoomStatus.open => AppStrings.roomOpen,
        RoomStatus.full => AppStrings.roomFull,
        RoomStatus.locked => AppStrings.roomLocked,
      },
      isMine: widget.isMine,
    );
    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: semantic,
      child: ExcludeSemantics(
        child: PressableScale(
          onTap: widget.onTap,
          child: Builder(builder: (context) {
            final tile = AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: ocean.seaGlass,
                  borderRadius: BorderRadius.circular(AppRadius.r20),
                  border: Border.all(
                    color: widget.isMine ? ocean.teal : ocean.foam,
                    width: widget.isMine
                        ? AppSizes.focusOutlineWidth
                        : AppSizes.outlineWidth,
                  ),
                  boxShadow: widget.isMine
                      ? [
                          BoxShadow(
                            color: ocean.aqua.withValues(
                              alpha: AppSizes.glowOpacity,
                            ),
                            blurRadius: AppSizes.glowBlur,
                            spreadRadius: AppSizes.glowSpread,
                          ),
                        ]
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  child: Column(
                    children: [
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _float,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(
                              0,
                              widget.animateIdle && !Motion.of(context).reduced
                                  ? (_float.value * 2 - 1) *
                                      AppSizes.floatingDistance
                                  : 0,
                            ),
                            child: child,
                          ),
                          child: RepaintBoundary(
                            child: Opacity(
                              opacity: widget.status == RoomStatus.locked
                                  ? AppSizes.lockedOpacity
                                  : 1,
                              child: _TableVisual(widget: widget),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: StatusChip(
                              status: widget.status,
                              animate: widget.animateIdle,
                            ),
                          ),
                          if (widget.isMine) ...[
                            const SizedBox(width: AppSpacing.s4),
                            Icon(Icons.star_rounded,
                                color: scheme.primary, size: AppSizes.icon),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            return widget.isMine
                ? Banner(
                    message: AppStrings.yourRoom,
                    location: BannerLocation.topStart,
                    color: scheme.primary,
                    textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                    child: tile,
                  )
                : tile;
          }),
        ),
      ),
    );
  }
}

class _TableVisual extends StatelessWidget {
  const _TableVisual({required this.widget});

  final RoomTile widget;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, bounds) {
      final side = math.min(bounds.maxWidth, bounds.maxHeight);
      final seatSize = math.min(
        AppSizes.seatMax,
        math.max(
          AppSizes.seatMin,
          2 *
              math.pi *
              side *
              AppSizes.roomOrbit /
              widget.capacity *
              AppSizes.seatSpacing,
        ),
      );
      final orbit = side * AppSizes.roomOrbit;
      final centerX = bounds.maxWidth / 2;
      final centerY = bounds.maxHeight / 2;
      final tableSide = side * AppSizes.roomTable;
      final scheme = Theme.of(context).colorScheme;
      final ocean = Theme.of(context).extension<OceanColors>()!;
      Widget table = SizedBox(
        width: tableSide,
        height: tableSide,
        child: CustomPaint(
          painter: ReefPlatformPainter(
            ocean: ocean,
            isMine: widget.isMine,
            locked: widget.status == RoomStatus.locked,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        widget.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: ocean.deepNavy,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Text(
                      '${widget.members.length}/${widget.capacity}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: ocean.deepNavy),
                    ),
                  ],
                ),
              ),
              if (widget.status == RoomStatus.locked)
                Positioned(
                  right: AppSpacing.s4,
                  top: AppSpacing.s4,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1, end: 0),
                    duration: Motion.of(context).use(MotionTokens.standard),
                    curve: MotionTokens.elastic,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(value * AppSpacing.s4, 0),
                      child: child,
                    ),
                    child: Icon(Icons.lock_rounded,
                        size: AppSizes.avatarBadge, color: ocean.deepNavy),
                  ),
                ),
            ],
          ),
        ),
      );
      if (widget.hero) {
        table = Hero(tag: 'room-${widget.id}', child: table);
      }
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: centerX - tableSide / 2,
            top: centerY - tableSide / 2,
            child: table,
          ),
          for (var index = 0; index < widget.capacity; index++)
            Positioned(
              left: centerX +
                  math.cos(-math.pi / 2 +
                          2 * math.pi * index / widget.capacity) *
                      orbit -
                  seatSize / 2,
              top: centerY +
                  math.sin(-math.pi / 2 +
                          2 * math.pi * index / widget.capacity) *
                      orbit -
                  seatSize / 2,
              child: AnimatedSwitcher(
                duration: Motion.of(context).use(MotionTokens.standard),
                switchInCurve: MotionTokens.elastic,
                transitionBuilder: (child, animation) {
                  final occupied = child is SeatAvatar && child.member != null;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (occupied)
                        FadeTransition(
                          opacity: ReverseAnimation(animation),
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: MotionTokens.seatRippleStart,
                              end: MotionTokens.seatRippleEnd,
                            ).animate(animation),
                            child: Container(
                              width: seatSize,
                              height: seatSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: scheme.primary),
                              ),
                            ),
                          ),
                        ),
                      ScaleTransition(scale: animation, child: child),
                    ],
                  );
                },
                child: SeatAvatar(
                  key: ValueKey(widget.members.length > index
                      ? widget.members[index].id
                      : 'empty-$index'),
                  size: seatSize,
                  member: widget.members.length > index
                      ? widget.members[index]
                      : null,
                ),
              ),
            ),
        ],
      );
    });
  }
}
