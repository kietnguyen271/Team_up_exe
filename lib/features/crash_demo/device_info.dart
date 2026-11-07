import 'device_info_stub.dart' if (dart.library.io) 'device_info_io.dart'
    as platform;

String currentDeviceInfo() => platform.currentDeviceInfo();
