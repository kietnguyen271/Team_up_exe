import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/core/motion/app_motion.dart';
import 'package:teamup_exe/core/motion/ocean_quality.dart';
import 'package:teamup_exe/core/theme/app_theme.dart';
import 'package:teamup_exe/shared/ocean/ocean_backdrop.dart';
import 'package:teamup_exe/shared/ocean/ocean_host.dart';

void main() {
  test('quality governor steps down after slow frame window', () {
    final governor = OceanQualityGovernor();
    expect(governor.quality, OceanQuality.high);
    final start = DateTime.utc(2026);
    for (var index = 0; index < OceanMotionTokens.sampleWindow; index++) {
      governor.record(const Duration(milliseconds: 20), Duration.zero, start);
    }
    expect(governor.quality, OceanQuality.medium);
    expect(governor.sampleCount, 0);
    expect(governor.slowFraction, 0);
    for (var index = 0; index < OceanMotionTokens.sampleWindow; index++) {
      governor.record(const Duration(milliseconds: 20), Duration.zero,
          start.add(OceanMotionTokens.downshiftCooldown));
    }
    expect(governor.quality, OceanQuality.low);
    expect(governor.sampleCount, 0);
  });

  test('quality governor recovers at most one level per minute', () {
    final governor = OceanQualityGovernor(quality: OceanQuality.low);
    final start = DateTime.utc(2026);
    for (var index = 0; index < OceanMotionTokens.sampleWindow; index++) {
      governor.record(Duration.zero, Duration.zero, start);
    }
    expect(governor.quality, OceanQuality.medium);
    for (var index = 0; index < OceanMotionTokens.sampleWindow; index++) {
      governor.record(
          Duration.zero, Duration.zero, start.add(const Duration(seconds: 30)));
    }
    expect(governor.quality, OceanQuality.medium);
    governor.record(Duration.zero, Duration.zero,
        start.add(OceanMotionTokens.upshiftCooldown));
    expect(governor.quality, OceanQuality.high);
  });

  test('auto Off probes Low after one minute', () {
    final governor = OceanQualityGovernor(quality: OceanQuality.off);
    final start = DateTime.utc(2026);
    expect(governor.probeRecovery(start), isFalse);
    // Off only follows a slow-frame downshift from Low.
    governor.quality = OceanQuality.low;
    for (var index = 0; index < OceanMotionTokens.sampleWindow; index++) {
      governor.record(const Duration(milliseconds: 20), Duration.zero, start);
    }
    expect(governor.quality, OceanQuality.off);
    expect(governor.probeRecovery(start.add(const Duration(seconds: 30))),
        isFalse);
    expect(governor.probeRecovery(start.add(OceanMotionTokens.upshiftCooldown)),
        isTrue);
    expect(governor.quality, OceanQuality.low);
    expect(governor.sampleCount, 0);
  });

  testWidgets('effects Off and reduced motion stop the shared ticker',
      (tester) async {
    final settings = OceanSettings();
    expect(settings.mode, OceanEffectsMode.auto);
    OceanRuntime? runtime;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: OceanHost(
        settings: settings,
        child: Builder(builder: (context) {
          runtime = OceanScope.maybeOf(context);
          return const Scaffold(body: OceanBackdrop());
        }),
      ),
    ));
    await tester.pump();
    expect(runtime, isNotNull);
    expect(runtime!.isAnimating, isTrue);
    expect(runtime!.effectiveQuality, OceanQuality.high);
    expect(runtime!.qualityReason, isNull);

    settings.setMode(OceanEffectsMode.off);
    await tester.pump();
    expect(runtime!.isAnimating, isFalse);
    expect(runtime!.qualityReason, OceanOffReason.userSetting);

    settings.setMode(OceanEffectsMode.high);
    await tester.pump();
    expect(runtime!.isAnimating, isTrue);
    Motion.settings.setReduced(true);
    await tester.pump();
    expect(runtime!.isAnimating, isFalse);
    expect(runtime!.qualityReason, OceanOffReason.userSetting);
    Motion.settings.setReduced(false);
    settings.dispose();
  });
}
