import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/motion/app_motion.dart';
import '../../core/motion/ocean_power_service.dart';
import '../../core/motion/ocean_quality.dart';

class OceanRuntime extends ChangeNotifier {
  OceanRuntime(this.controller, this.settings, this._visibilityChanged);

  final AnimationController controller;
  final OceanSettings settings;
  final VoidCallback _visibilityChanged;
  final Set<Object> _visibleClients = <Object>{};
  OceanQuality effectiveQuality = OceanQuality.off;
  bool forcedOff = true;
  OceanOffReason? qualityReason = OceanOffReason.routeNotVisible;

  bool get isAnimating => controller.isAnimating;
  bool get hasVisibleClients => _visibleClients.isNotEmpty;
  OceanQuality qualityFor(OceanQuality? preview) =>
      forcedOff ? OceanQuality.off : preview ?? effectiveQuality;

  void setClientVisible(Object client, bool visible) {
    final changed =
        visible ? _visibleClients.add(client) : _visibleClients.remove(client);
    if (changed) _visibilityChanged();
  }

  void updateQuality(OceanQuality quality,
      {required bool forceOff, OceanOffReason? reason}) {
    if (effectiveQuality == quality &&
        forcedOff == forceOff &&
        qualityReason == reason) {
      return;
    }
    effectiveQuality = quality;
    forcedOff = forceOff;
    qualityReason = reason;
    notifyListeners();
  }
}

class OceanScope extends InheritedWidget {
  const OceanScope({super.key, required this.runtime, required super.child});

  final OceanRuntime runtime;

  static OceanRuntime? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OceanScope>()?.runtime;

  @override
  bool updateShouldNotify(OceanScope oldWidget) => runtime != oldWidget.runtime;
}

class OceanHost extends StatefulWidget {
  const OceanHost({super.key, required this.child, this.settings});

  final Widget child;
  final OceanSettings? settings;

  @override
  State<OceanHost> createState() => _OceanHostState();
}

class _OceanHostState extends State<OceanHost>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: OceanMotionTokens.loop,
  );
  late final OceanRuntime _runtime =
      OceanRuntime(_clock, widget.settings ?? Ocean.settings, _scheduleSync);
  bool _foreground = true;
  bool _disableAnimations = false;
  bool _batterySaver = false;
  bool _syncPending = false;
  Timer? _recoveryTimer;
  DateTime? _warmupUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _runtime.settings.addListener(_scheduleSync);
    Motion.settings.addListener(_scheduleSync);
    _refreshBatterySaver();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _scheduleSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refreshBatterySaver();
    _scheduleSync();
  }

  Future<void> _refreshBatterySaver() async {
    final saver = await OceanPowerService.isBatterySaverOn();
    if (!mounted || _batterySaver == saver) return;
    _batterySaver = saver;
    _scheduleSync();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_clock.isAnimating &&
        (_warmupUntil == null || DateTime.now().isAfter(_warmupUntil!))) {
      _runtime.settings.recordTimings(timings);
    }
  }

  void _scheduleSync() {
    if (!mounted || _syncPending) return;
    _syncPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPending = false;
      if (mounted) _syncClock();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  void _syncClock() {
    final forcedReason = !_foreground
        ? OceanOffReason.appInBackground
        : !_runtime.hasVisibleClients
            ? OceanOffReason.routeNotVisible
            : _disableAnimations
                ? OceanOffReason.systemReducedMotion
                : Motion.settings.reduced
                    ? OceanOffReason.userSetting
                    : _batterySaver
                        ? OceanOffReason.batterySaver
                        : _runtime.settings.mode == OceanEffectsMode.off
                            ? OceanOffReason.userSetting
                            : null;
    final reason = forcedReason ??
        (_runtime.settings.mode == OceanEffectsMode.auto &&
                _runtime.settings.chosenQuality != OceanQuality.high
            ? OceanOffReason.governorStepDown
            : null);
    final forced = forcedReason != null;
    final quality = forced ? OceanQuality.off : _runtime.settings.chosenQuality;
    _runtime.updateQuality(quality, forceOff: forced, reason: reason);
    if (quality == OceanQuality.off) {
      _clock.stop();
      if (forced || _runtime.settings.mode != OceanEffectsMode.auto) {
        _recoveryTimer?.cancel();
        _recoveryTimer = null;
      } else {
        _recoveryTimer ??= Timer(OceanMotionTokens.upshiftCooldown, () {
          _recoveryTimer = null;
          _runtime.settings.probeRecovery();
          _scheduleSync();
        });
      }
      return;
    }
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    final duration = quality == OceanQuality.low
        ? OceanMotionTokens.lowLoop
        : OceanMotionTokens.loop;
    if (_clock.duration != duration) _clock.duration = duration;
    if (!_clock.isAnimating) {
      _warmupUntil = DateTime.now().add(OceanMotionTokens.startupWarmup);
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _recoveryTimer?.cancel();
    Motion.settings.removeListener(_scheduleSync);
    _runtime.settings.removeListener(_scheduleSync);
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    WidgetsBinding.instance.removeObserver(this);
    _runtime.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      OceanScope(runtime: _runtime, child: widget.child);
}
