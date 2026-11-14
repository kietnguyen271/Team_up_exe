import 'package:flutter/material.dart';

/// The only timing and curve values used by the UI layer.
abstract final class MotionTokens {
  static const micro = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 280);
  static const page = Duration(milliseconds: 420);
  static const celebration = Duration(milliseconds: 1100);
  static const stagger = Duration(milliseconds: 40);
  static const maxStagger = Duration(milliseconds: 400);
  static const heroLoop = Duration(seconds: 10);
  static const floatLoop = Duration(seconds: 3);
  static const toastDisplay = Duration(seconds: 3);
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const pop = Curves.easeOutBack;
  static const elastic = Curves.elasticOut;
  static const pressedScale = 0.96;
  static const navSelectedScale = 1.12;
  static const slideUpStart = 0.12;
  static const checkStartScale = 0.65;
  static const dialogStartScale = 0.94;
  static const invalidShake = 0.04;
  static const seatRippleStart = 0.7;
  static const seatRippleEnd = 1.5;
  static const pulseMinOpacity = 0.5;
  static const shimmerStart = -2.0;
  static const shimmerTravel = 4.0;
}

class MotionSettings extends ChangeNotifier {
  bool _reduced = false;
  bool get reduced => _reduced;

  void setReduced(bool value) {
    if (_reduced == value) return;
    _reduced = value;
    notifyListeners();
  }
}

class MotionScope extends InheritedNotifier<MotionSettings> {
  const MotionScope(
      {super.key, required MotionSettings settings, required super.child})
      : super(notifier: settings);

  static MotionSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MotionScope>()?.notifier;
}

class Motion {
  const Motion(this.reduced);

  final bool reduced;
  static final MotionSettings settings = MotionSettings();

  static Motion of(BuildContext context) => Motion(
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
            (MotionScope.maybeOf(context)?.reduced ?? settings.reduced),
      );

  Duration use(Duration duration) => reduced ? Duration.zero : duration;

  Duration stagger(int index) => reduced
      ? Duration.zero
      : Duration(
          milliseconds: (index * MotionTokens.stagger.inMilliseconds)
              .clamp(0, MotionTokens.maxStagger.inMilliseconds),
        );
}
