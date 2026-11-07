import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/notifications/notification_runtime.dart';
import '../../../firebase_options.dart';
import '../../../shared/widgets/error_notice.dart';
import '../../crash_demo/data/firebase_crash_demo.dart';
import '../../crash_demo/device_info.dart';
import '../../crash_demo/domain/crash_demo_event.dart';

class DebugFirebaseScreen extends StatefulWidget {
  const DebugFirebaseScreen({super.key, this.isWeb = false});

  final bool isWeb;

  @override
  State<DebugFirebaseScreen> createState() => _DebugFirebaseScreenState();
}

class _DebugFirebaseScreenState extends State<DebugFirebaseScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roomIdController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _logs = <String>[];
  final _results = <_SmokeResult>[];
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  bool _busy = false;
  String? _lastError;
  String? _retryAction;
  Future<String> Function()? _retryOperation;
  String? _fcmToken;

  @override
  void dispose() {
    _subscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _roomIdController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _log(String value) {
    if (!mounted) return;
    setState(() => _logs.add('${DateTime.now().toIso8601String()}  $value'));
  }

  void _recordStreamError(Object error, StackTrace stackTrace) {
    if (!mounted) return;
    setState(() {
      _results.add(
          _SmokeResult(AppStrings.firebaseListen, false, error.toString()));
      _lastError = error.toString();
      _retryAction = AppStrings.firebaseListen;
      _retryOperation = _listen;
      _logs.add(
          '${DateTime.now().toIso8601String()}  ${AppStrings.firebaseStatusFailed} · '
          '${AppStrings.firebaseListen} · $error\n$stackTrace');
    });
  }

  Future<void> _execute(
      String action, Future<String> Function() operation) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final detail = await operation();
      if (!mounted) return;
      setState(() {
        _results.add(_SmokeResult(action, true, AppStrings.firebaseNoError));
        _lastError = null;
        _retryAction = null;
        _retryOperation = null;
        _logs.add(
            '${DateTime.now().toIso8601String()}  ${AppStrings.firebaseStatusOk} · '
            '$action · $detail');
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _results.add(_SmokeResult(action, false, error.toString()));
        _lastError = error.toString();
        _retryAction = action;
        _retryOperation = operation;
        _logs.add(
            '${DateTime.now().toIso8601String()}  ${AppStrings.firebaseStatusFailed} · '
            '$action · $error\n$stackTrace');
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _requireFirebase() {
    if (Firebase.apps.isEmpty) {
      throw StateError(AppStrings.firebaseNotInitialized);
    }
  }

  String _requireUid() {
    _requireFirebase();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError(AppStrings.firebaseNotSignedIn);
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _smokeDocument() {
    final uid = _requireUid();
    return FirebaseFirestore.instance.collection('_smoke').doc(uid);
  }

  Future<String> _initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    return AppStrings.firebaseProject(Firebase.app().options.projectId);
  }

  Future<String> _register() async {
    _requireFirebase();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) throw StateError(AppStrings.firebaseEmailRequired);
    if (password.isEmpty) throw StateError(AppStrings.firebasePasswordRequired);
    final credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _afterAuth(credential.user);
  }

  Future<String> _sendVerification() async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError(AppStrings.firebaseNotSignedIn);
    await user.sendEmailVerification();
    return AppStrings.firebaseSendVerification;
  }

  Future<String> _reloadVerification() async {
    _requireFirebase();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError(AppStrings.firebaseNotSignedIn);
    await user.reload();
    return AppStrings.firebaseVerified(
        FirebaseAuth.instance.currentUser?.emailVerified ?? false);
  }

  Future<String> _signIn() async {
    _requireFirebase();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) throw StateError(AppStrings.firebaseEmailRequired);
    if (password.isEmpty) throw StateError(AppStrings.firebasePasswordRequired);
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _afterAuth(credential.user);
  }

  Future<String> _afterAuth(User? user) async {
    if (user == null) throw StateError(AppStrings.firebaseSignInFailed);
    if (!widget.isWeb) {
      await NotificationRuntime.instance.service.startForUser(user.uid);
    }
    return AppStrings.firebaseUser(user.uid);
  }

  Future<String> _signOut() async {
    _requireFirebase();
    await _subscription?.cancel();
    _subscription = null;
    if (!widget.isWeb) await NotificationRuntime.instance.beforeSignOut();
    await FirebaseAuth.instance.signOut();
    return AppStrings.firebaseSignOut;
  }

  Future<String> _write() async {
    final document = _smokeDocument();
    await document.set({
      'uid': _requireUid(),
      'counter': 0,
      'probe': 'phase0-write',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.path;
  }

  Future<String> _read() async {
    final snapshot = await _smokeDocument().get();
    if (!snapshot.exists) throw StateError(AppStrings.firebaseDocumentMissing);
    return snapshot.data().toString();
  }

  Future<String> _update() async {
    final document = _smokeDocument();
    await document.update({
      'probe': 'phase0-update',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.path;
  }

  Future<String> _delete() async {
    final document = _smokeDocument();
    await document.delete();
    return document.path;
  }

  Future<String> _listen() async {
    final document = _smokeDocument();
    await _subscription?.cancel();
    _subscription = document.snapshots().listen(
          (snapshot) => _log(snapshot.exists
              ? '${AppStrings.firebaseDocumentExists}: ${snapshot.data()}'
              : AppStrings.firebaseDocumentAbsent),
          onError: _recordStreamError,
        );
    return AppStrings.firebaseListening;
  }

  Future<String> _stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    return AppStrings.firebaseListeningStopped;
  }

  Future<String> _transaction() async {
    final document = _smokeDocument();
    final counter = await FirebaseFirestore.instance
        .runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(document);
      final current = (snapshot.data()?['counter'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      transaction.set(document, {'counter': next}, SetOptions(merge: true));
      return next;
    });
    return AppStrings.firebaseCounter(counter);
  }

  Future<String> _batchWrite() async {
    final uid = _requireUid();
    final collection = FirebaseFirestore.instance
        .collection('_smoke')
        .doc(uid)
        .collection('batch');
    final batch = FirebaseFirestore.instance.batch();
    for (var index = 1; index <= 3; index++) {
      batch.set(collection.doc('$index'), {
        'index': index,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return AppStrings.firebaseCount(3);
  }

  Future<String> _query() async {
    _requireFirebase();
    final snapshot = await FirebaseFirestore.instance
        .collection('admins')
        .where('addedAt', isGreaterThan: Timestamp(0, 0))
        .orderBy('addedAt')
        .get();
    return AppStrings.firebaseCount(snapshot.docs.length);
  }

  Future<String> _requestNotificationPermission() async {
    if (widget.isWeb) throw UnsupportedError(AppStrings.androidOnly);
    final allowed =
        await NotificationRuntime.instance.service.requestPermission();
    return allowed
        ? AppStrings.notificationPermissionGranted
        : AppStrings.notificationPermissionDenied;
  }

  Future<String> _showToken() async {
    if (widget.isWeb) throw UnsupportedError(AppStrings.androidOnly);
    final service = NotificationRuntime.instance.service;
    final token = service.token ?? await service.gateway.getToken();
    if (token == null || token.isEmpty) throw StateError(AppStrings.noFcmToken);
    if (mounted) setState(() => _fcmToken = token);
    return token;
  }

  Future<String> _subscribeToRoom() async {
    await NotificationRuntime.instance.service
        .subscribeToRoom(_roomIdController.text);
    return AppStrings.topicDone;
  }

  Future<String> _unsubscribeFromRoom() async {
    await NotificationRuntime.instance.service
        .unsubscribeFromRoom(_roomIdController.text);
    return AppStrings.topicDone;
  }

  Future<String> _causeCrash() async {
    if (widget.isWeb) throw UnsupportedError(AppStrings.androidOnly);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError(AppStrings.crashNeedsSignIn);
    await const FirebaseCrashDemo().causeCrash(CrashDemoEvent(
      timestamp: DateTime.now().toUtc(),
      uid: uid,
      deviceInfo: currentDeviceInfo(),
      appVersion: AppStrings.appVersion,
    ));
    return AppStrings.crashSaved;
  }

  Future<String> _recordNonFatal() async {
    if (widget.isWeb) throw UnsupportedError(AppStrings.androidOnly);
    await const FirebaseCrashDemo()
        .recordNonFatal(Exception(AppStrings.crashTestException));
    return AppStrings.nonFatalSaved;
  }

  Widget _actionButton(
      String label, IconData icon, Future<String> Function() operation) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : () => _execute(label, operation),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _DebugPageShell(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back),
              label: const Text(AppStrings.firebaseBackToLogin),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(AppStrings.firebaseDebug, style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.s8),
            Text(AppStrings.firebaseDebugIntro, style: textTheme.bodyLarge),
            if (_lastError != null) ...[
              const SizedBox(height: AppSpacing.s16),
              ErrorNotice(message: _lastError!),
              const SizedBox(height: AppSpacing.s8),
              FilledButton.icon(
                onPressed:
                    _busy || _retryAction == null || _retryOperation == null
                        ? null
                        : () => _execute(_retryAction!, _retryOperation!),
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            _actionButton(AppStrings.firebaseInitialize,
                Icons.power_settings_new, _initialize),
            const SizedBox(height: AppSpacing.s24),
            Text(AppStrings.firebaseAuthSection, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: AppStrings.email),
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.s16),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: AppStrings.password),
              onSubmitted: (_) => _execute(AppStrings.firebaseSignIn, _signIn),
            ),
            const SizedBox(height: AppSpacing.s16),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                _actionButton(AppStrings.firebaseRegister,
                    Icons.person_add_outlined, _register),
                _actionButton(AppStrings.firebaseSendVerification,
                    Icons.mark_email_unread_outlined, _sendVerification),
                _actionButton(AppStrings.firebaseReloadVerification,
                    Icons.refresh, _reloadVerification),
                _actionButton(AppStrings.firebaseSignIn, Icons.login, _signIn),
                _actionButton(
                    AppStrings.firebaseSignOut, Icons.logout, _signOut),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(AppStrings.firebaseDataSection, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s16),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                _actionButton(
                    AppStrings.firebaseWrite, Icons.save_outlined, _write),
                _actionButton(
                    AppStrings.firebaseRead, Icons.menu_book_outlined, _read),
                _actionButton(
                    AppStrings.firebaseUpdate, Icons.edit_outlined, _update),
                _actionButton(
                    AppStrings.firebaseDelete, Icons.delete_outline, _delete),
                _actionButton(
                    AppStrings.firebaseListen, Icons.wifi_tethering, _listen),
                _actionButton(AppStrings.firebaseStopListen,
                    Icons.stop_circle_outlined, _stopListening),
                _actionButton(
                    AppStrings.firebaseTransaction, Icons.sync, _transaction),
                _actionButton(AppStrings.firebaseBatch, Icons.layers_outlined,
                    _batchWrite),
                _actionButton(AppStrings.firebaseQuery, Icons.search, _query),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            if (!widget.isWeb) ...[
              Text(AppStrings.notifications, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s16),
              TextField(
                controller: _roomIdController,
                decoration: const InputDecoration(labelText: AppStrings.roomId),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) =>
                    _execute(AppStrings.subscribeTopic, _subscribeToRoom),
              ),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  _actionButton(
                      AppStrings.requestNotificationPermission,
                      Icons.notifications_active_outlined,
                      _requestNotificationPermission),
                  _actionButton(
                      AppStrings.showFcmToken, Icons.key_outlined, _showToken),
                  _actionButton(AppStrings.subscribeTopic,
                      Icons.add_alert_outlined, _subscribeToRoom),
                  _actionButton(AppStrings.unsubscribeTopic,
                      Icons.notifications_off_outlined, _unsubscribeFromRoom),
                ],
              ),
              if (_fcmToken != null) ...[
                const SizedBox(height: AppSpacing.s16),
                SelectableText(_fcmToken!, style: textTheme.bodyMedium),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _fcmToken!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(AppStrings.copied)),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text(AppStrings.copy),
                ),
              ],
              const SizedBox(height: AppSpacing.s24),
              Text(AppStrings.crashDemo, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s8),
              Text(AppStrings.crashExplanation, style: textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  _actionButton(AppStrings.causeCrash,
                      Icons.warning_amber_outlined, _causeCrash),
                  _actionButton(AppStrings.recordNonFatal,
                      Icons.bug_report_outlined, _recordNonFatal),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),
            ] else ...[
              Text(AppStrings.androidOnly, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.s24),
            ],
            Text(AppStrings.firebaseLog, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: _logs.isEmpty
                    ? const Text(AppStrings.firebaseNoLog)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in _logs) ...[
                            SelectableText(line, style: textTheme.bodyMedium),
                            const SizedBox(height: AppSpacing.s8),
                          ],
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(AppStrings.firebaseResults, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s8),
            if (_results.isEmpty)
              const Text(AppStrings.firebaseNoResults)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text(AppStrings.firebaseActionColumn)),
                    DataColumn(label: Text(AppStrings.firebaseResultColumn)),
                    DataColumn(label: Text(AppStrings.firebaseErrorColumn)),
                  ],
                  rows: [
                    for (final result in _results)
                      DataRow(cells: [
                        DataCell(Text(result.action)),
                        DataCell(Text(result.passed
                            ? AppStrings.firebaseStatusOk
                            : AppStrings.firebaseStatusFailed)),
                        DataCell(SelectableText(result.error)),
                      ]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmokeResult {
  const _SmokeResult(this.action, this.passed, this.error);

  final String action;
  final bool passed;
  final String error;
}

class _DebugPageShell extends StatelessWidget {
  const _DebugPageShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.firebaseDebug)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: child,
          ),
        ),
      ),
    );
  }
}
