import 'package:flutter_test/flutter_test.dart';
import 'package:teamup_exe/features/crash_demo/domain/crash_demo_event.dart';

void main() {
  test('crash event maps required fields without Firebase', () {
    final timestamp = DateTime.utc(2026, 11, 5, 10, 30);
    final event = CrashDemoEvent(
      timestamp: timestamp,
      uid: 'student-1',
      deviceInfo: 'android 15',
      appVersion: '0.1.0+1',
    );

    expect(event.toMap(), {
      'timestamp': timestamp,
      'uid': 'student-1',
      'deviceInfo': 'android 15',
      'appVersion': '0.1.0+1',
    });
  });
}
