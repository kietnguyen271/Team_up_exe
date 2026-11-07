class CrashDemoEvent {
  const CrashDemoEvent({
    required this.timestamp,
    required this.uid,
    required this.deviceInfo,
    required this.appVersion,
  });

  final DateTime timestamp;
  final String uid;
  final String deviceInfo;
  final String appVersion;

  Map<String, Object> toMap() => {
        'timestamp': timestamp,
        'uid': uid,
        'deviceInfo': deviceInfo,
        'appVersion': appVersion,
      };
}
