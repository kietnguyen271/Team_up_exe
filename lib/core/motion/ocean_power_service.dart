import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class OceanPowerService {
  static const _channel = MethodChannel('teamup/ocean_power');

  static Future<bool> isBatterySaverOn() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('isBatterySaverOn') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
