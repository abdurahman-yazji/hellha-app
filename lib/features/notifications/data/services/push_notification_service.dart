import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'device_token_service.dart';

class PushNotificationService with WidgetsBindingObserver {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  final _deviceService = DeviceTokenService();

  Future<void> _queue = Future<void>.value();
  Future<void>? _logoutFuture;

  User? _readyUser;
  String? _lastToken;

  bool _initialized = false;
  bool _paused = false;
  bool _refreshQueued = false;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void initialize() {
    if (!_supported || _initialized) return;

    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    // This singleton and its listener live for the application's lifetime.
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) {
        unawaited(refresh());
      },
      onError: (Object _) {
        debugPrint('PUSH: token refresh listener failed');
      },
    );
  }

  Future<void> activateForUser(User user) async {
    if (!_supported || _paused) return;

    if (FirebaseAuth.instance.currentUser?.uid != user.uid) return;

    initialize();
    _readyUser = user;

    await refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final task = _queue.then((_) => operation());

    // Keep the queue usable even if an operation fails.
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});

    return task;
  }

  bool _canRegister(User user) {
    return !_paused &&
        _readyUser?.uid == user.uid &&
        FirebaseAuth.instance.currentUser?.uid == user.uid;
  }

  Future<void> refresh() async {
    if (!_supported || _paused || _refreshQueued) return;

    final user = _readyUser;

    if (user == null || !_canRegister(user)) return;

    _refreshQueued = true;

    try {
      await _enqueue(() async {
        if (!_canRegister(user)) return;

        final messaging = FirebaseMessaging.instance;

        final settings = await messaging.getNotificationSettings().timeout(
          const Duration(seconds: 20),
        );

        final allowed =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

        if (!allowed || !_canRegister(user)) return;

        await messaging
            .setAutoInitEnabled(true)
            .timeout(const Duration(seconds: 20));

        if (!_canRegister(user)) return;

        final token = await messaging.getToken().timeout(
          const Duration(seconds: 20),
        );

        if (token == null || token.isEmpty || !_canRegister(user)) return;

        _lastToken = token;

        await _deviceService.registerDevice(
          user: user,
          token: token,
          platform: 'android',
        );

        debugPrint('PUSH: device registered');
      });
    } catch (_) {
      // Notification registration must not prevent opening the account.
      debugPrint('PUSH: registration failed; retry on next refresh');
    } finally {
      _refreshQueued = false;
    }
  }

  Future<void> signOut(Future<void> Function() signOutAccount) {
    final pending = _logoutFuture;

    if (pending != null) return pending;

    _paused = true;

    final task = _performSignOut(signOutAccount);
    _logoutFuture = task;

    return task;
  }

  Future<void> _performSignOut(Future<void> Function() signOutAccount) async {
    try {
      await _enqueue(() async {
        final user = FirebaseAuth.instance.currentUser;

        if (_supported && user != null) {
          final messaging = FirebaseMessaging.instance;

          await messaging
              .setAutoInitEnabled(false)
              .timeout(const Duration(seconds: 20));

          String? token = _lastToken;

          if (token == null) {
            try {
              token = await messaging.getToken().timeout(
                const Duration(seconds: 20),
              );
            } catch (_) {
              debugPrint('PUSH: unable to read token during logout');
            }
          }

          if (token != null) {
            try {
              await _deviceService.unregisterDevice(
                user: user,
                token: token,
                platform: 'android',
              );
            } catch (_) {
              // Still invalidate the FCM token if the backend is unavailable.
              debugPrint('PUSH: backend token removal failed');
            }
          }

          // Required before leaving the account, even if backend removal failed.
          await messaging.deleteToken().timeout(const Duration(seconds: 20));

          _lastToken = null;
        }

        await signOutAccount();
        _readyUser = null;
      });
    } finally {
      _paused = false;
      _logoutFuture = null;

      // If logout failed and the account remains signed in, restore registration.
      final user = _readyUser;

      if (user != null && FirebaseAuth.instance.currentUser?.uid == user.uid) {
        unawaited(refresh());
      }
    }
  }
}
