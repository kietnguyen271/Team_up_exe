import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../domain/crash_demo_event.dart';

class FirebaseCrashDemo {
  const FirebaseCrashDemo();

  Future<void> causeCrash(CrashDemoEvent event) async {
    final data = event.toMap();
    await FirebaseFirestore.instance.collection('crashDemoEvents').add({
      ...data,
      'timestamp': Timestamp.fromDate(event.timestamp),
    });
    FirebaseCrashlytics.instance.crash();
  }

  Future<void> recordNonFatal(Object error) async {
    await FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
  }
}
