import 'dart:ui';

import 'package:flutter/foundation.dart';

enum OceanQuality { high, medium, low, off }

enum OceanEffectsMode { auto, high, medium, low, off }

enum OceanOffReason {
  systemReducedMotion,
  batterySaver,
  userSetting,
  governorStepDown,
  appInBackground,
  routeNotVisible,
}

abstract final class OceanMotionTokens {
  static const frameBudget = Duration(microseconds: 16600);
  static const sampleWindow = 120;
  static const slowThreshold = 0.20;
  static const recoveryThreshold = 0.05;
  static const downshiftCooldown = Duration(seconds: 10);
  static const upshiftCooldown = Duration(minutes: 1);
  static const startupWarmup = Duration(seconds: 3);
  static const loop = Duration(seconds: 12);
  static const lowLoop = Duration(seconds: 24);
  static const scrollDepth = 520.0;
  static const tabDepth = 0.17;
  static const parallaxEpsilon = 1.0;
}

class OceanQualityGovernor {
  OceanQualityGovernor({this.quality = OceanQuality.high});

  OceanQuality quality;
  final List<bool> _recent =
      List<bool>.filled(OceanMotionTokens.sampleWindow, false);
  int _next = 0;
  int _count = 0;
  int _slowCount = 0;
  DateTime? _lastDownshift;
  DateTime? _lastUpshift;

  int get sampleCount => _count;
  double get slowFraction => _count == 0 ? 0 : _slowCount / _count;

  bool record(Duration build, Duration raster, DateTime now) {
    final slow = build + raster > OceanMotionTokens.frameBudget;
    if (_count == _recent.length) {
      if (_recent[_next]) _slowCount--;
    } else {
      _count++;
    }
    _recent[_next] = slow;
    if (slow) _slowCount++;
    _next = (_next + 1) % _recent.length;
    if (_count < _recent.length) return false;

    if (slowFraction > OceanMotionTokens.slowThreshold &&
        (_lastDownshift == null ||
            now.difference(_lastDownshift!) >=
                OceanMotionTokens.downshiftCooldown)) {
      final next = switch (quality) {
        OceanQuality.high => OceanQuality.medium,
        OceanQuality.medium => OceanQuality.low,
        OceanQuality.low => OceanQuality.off,
        OceanQuality.off => OceanQuality.off,
      };
      if (next != quality) {
        quality = next;
        _lastDownshift = now;
        _resetSamples();
        return true;
      }
    }
    if (slowFraction < OceanMotionTokens.recoveryThreshold &&
        (_lastUpshift == null ||
            now.difference(_lastUpshift!) >=
                OceanMotionTokens.upshiftCooldown)) {
      final next = switch (quality) {
        OceanQuality.off => OceanQuality.low,
        OceanQuality.low => OceanQuality.medium,
        OceanQuality.medium => OceanQuality.high,
        OceanQuality.high => OceanQuality.high,
      };
      if (next != quality) {
        quality = next;
        _lastUpshift = now;
        _resetSamples();
        return true;
      }
    }
    return false;
  }

  bool probeRecovery(DateTime now) {
    if (quality != OceanQuality.off ||
        _lastDownshift == null ||
        now.difference(_lastDownshift!) < OceanMotionTokens.upshiftCooldown ||
        (_lastUpshift != null &&
            now.difference(_lastUpshift!) <
                OceanMotionTokens.upshiftCooldown)) {
      return false;
    }
    quality = OceanQuality.low;
    _lastUpshift = now;
    _resetSamples();
    return true;
  }

  void _resetSamples() {
    _recent.fillRange(0, _recent.length, false);
    _next = 0;
    _count = 0;
    _slowCount = 0;
  }
}

class OceanSettings extends ChangeNotifier {
  OceanSettings({OceanQualityGovernor? governor})
      : _governor = governor ?? OceanQualityGovernor();

  final OceanQualityGovernor _governor;
  OceanEffectsMode _mode = OceanEffectsMode.auto;
  double _scrollOffset = 0;
  int _tabIndex = 0;

  OceanEffectsMode get mode => _mode;
  double get scrollOffset => _scrollOffset;
  int get tabIndex => _tabIndex;
  double get slowFraction => _governor.slowFraction;
  int get sampledFrames => _governor.sampleCount;

  OceanQuality get chosenQuality => switch (_mode) {
        OceanEffectsMode.auto => _governor.quality,
        OceanEffectsMode.high => OceanQuality.high,
        OceanEffectsMode.medium => OceanQuality.medium,
        OceanEffectsMode.low => OceanQuality.low,
        OceanEffectsMode.off => OceanQuality.off,
      };

  double get depth => (_scrollOffset / OceanMotionTokens.scrollDepth +
          _tabIndex * OceanMotionTokens.tabDepth)
      .clamp(0.0, 1.0)
      .toDouble();

  void setMode(OceanEffectsMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  void setParallax({double? scrollOffset, int? tabIndex}) {
    final scroll =
        (scrollOffset ?? _scrollOffset).clamp(0.0, double.infinity).toDouble();
    final tab = tabIndex ?? _tabIndex;
    if ((scroll - _scrollOffset).abs() < OceanMotionTokens.parallaxEpsilon &&
        tab == _tabIndex) return;
    _scrollOffset = scroll;
    _tabIndex = tab;
    notifyListeners();
  }

  void recordTimings(List<FrameTiming> timings) {
    if (_mode != OceanEffectsMode.auto) return;
    var changed = false;
    final now = DateTime.now();
    for (final timing in timings) {
      changed = _governor.record(
            timing.buildDuration,
            timing.rasterDuration,
            now,
          ) ||
          changed;
    }
    if (changed) notifyListeners();
  }

  void probeRecovery() {
    if (_mode == OceanEffectsMode.auto &&
        _governor.probeRecovery(DateTime.now())) {
      notifyListeners();
    }
  }
}

abstract final class Ocean {
  static final settings = OceanSettings();
}
