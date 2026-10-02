import 'dart:async';
import 'features/notifications/data/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'routing/app_router.dart';

class HellhaApp extends ConsumerStatefulWidget {
  const HellhaApp({super.key});

  @override
  ConsumerState<HellhaApp> createState() => _HellhaAppState();
}

class _HellhaAppState extends ConsumerState<HellhaApp>
    with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final Set<String> _shownNotifications = {};

  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<User?>? _authSubscription;

  RemoteMessage? _pendingMessage;

  bool _opening = false;
  bool _frameScheduled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    authStateNotifier.addListener(_scheduleOpen);

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      _shownNotifications.clear();
      _messengerKey.currentState?.clearSnackBars();
      _scheduleOpen();
    });

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (isAndroid) {
      _messageSubscription = FirebaseMessaging.onMessage.listen(
        (message) {
          unawaited(_showForegroundMessage(message));
        },
        onError: (Object _) {
          debugPrint('PUSH: foreground listener failed');
        },
      );

      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _queueOpen,
        onError: (Object _) {
          debugPrint('PUSH: notification tap listener failed');
        },
      );

      unawaited(_loadInitialMessage());
    }
  }

  Future<void> _loadInitialMessage() async {
    try {
      final message = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 20));

      if (mounted && message != null) {
        _queueOpen(message);
      }
    } catch (_) {
      debugPrint('PUSH: could not load initial notification');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleOpen();
    }
  }

  void _queueOpen(RemoteMessage message) {
    if (!mounted) return;

    // If several taps arrive during loading, keep the latest one.
    _pendingMessage = message;
    _scheduleOpen();
  }

  void _scheduleOpen() {
    if (!mounted || _frameScheduled || _pendingMessage == null) {
      return;
    }

    _frameScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameScheduled = false;

      if (mounted) {
        unawaited(_openPendingMessage());
      }
    });

    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool _validId(String? value) {
    return value != null && RegExp(r'^[1-9]\d{0,18}$').hasMatch(value);
  }

  void _showMessage(String text) {
    if (!mounted) return;

    _messengerKey.currentState?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openPendingMessage() async {
    if (!mounted ||
        _opening ||
        _pendingMessage == null ||
        authStateNotifier.registrationInProgress ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    // Keep the tapped notification until sign-in finishes.
    if (user == null) return;

    final message = _pendingMessage!;
    final recipientId = message.data['recipient_user_id']?.toString();
    final notificationId = message.data['notification_id']?.toString();
    final requestId = message.data['maintenance_request_id']?.toString();

    if (!_validId(recipientId) || !_validId(notificationId)) {
      _pendingMessage = null;
      _showMessage('تعذر فتح الإشعار لأن بياناته غير مكتملة.');
      return;
    }

    _opening = true;

    try {
      final profile = await ref
          .read(userProfileProvider.future)
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      // Another notification may have been tapped while loading.
      if (!identical(_pendingMessage, message)) return;

      if (FirebaseAuth.instance.currentUser?.uid != user.uid ||
          profile.firebaseUid != user.uid) {
        _pendingMessage = null;
        _showMessage('تغير الحساب. أعد فتح الإشعار.');
        return;
      }

      if (profile.id != recipientId) {
        _pendingMessage = null;
        _showMessage('هذا الإشعار يخص حسابًا آخر.');
        return;
      }

      if (!profile.isActive) {
        _pendingMessage = null;
        _showMessage('هذا الحساب غير نشط.');
        return;
      }

      // Wait if registration or app backgrounding happened during loading.
      if (authStateNotifier.registrationInProgress ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }

      final type = message.data['type']?.toString();

final isSpecializationNotification =
    type == 'specialization_change_approved' ||
    type == 'specialization_change_rejected';

String location;

if (isSpecializationNotification) {
  if (profile.role != 'technician') {
    _pendingMessage = null;
    _showMessage('هذا الإشعار مخصص لحساب فني.');
    return;
  }

  var readFailed = false;

  try {
    await NotificationService()
        .markAsRead(notificationId!)
        .timeout(const Duration(seconds: 20));
  } catch (_) {
    readFailed = true;
  }

  if (!mounted || !identical(_pendingMessage, message)) return;

  // إعادة التحقق بعد انتظار طلب الشبكة.
  if (FirebaseAuth.instance.currentUser?.uid != user.uid) {
    _pendingMessage = null;
    _showMessage('تغير الحساب. أعد فتح الإشعار.');
    return;
  }

  if (authStateNotifier.registrationInProgress ||
      WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
    return;
  }

  if (readFailed) {
    debugPrint('PUSH: could not mark specialization notification as read');
  }

  location = '/technician/specializations';
} else {
  location = _validId(requestId)
      ? Uri(
          path: '/notifications/$notificationId/request/$requestId',
          queryParameters: {'recipient': recipientId!},
        ).toString()
      : '/notifications';
}

      _pendingMessage = null;
      _messengerKey.currentState?.clearSnackBars();

      final currentLocation = appRouter.routeInformationProvider.value.uri;

      if (currentLocation.toString() == location) return;

      unawaited(_navigate(location));
    } catch (_) {
      if (!mounted || !identical(_pendingMessage, message)) return;

      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: const Text(
            'تعذر فتح الإشعار. تحقق من الاتصال وحاول مجددًا.',
          ),
          action: SnackBarAction(
            label: 'إعادة المحاولة',
            onPressed: () {
              ref.invalidate(userProfileProvider);
              _scheduleOpen();
            },
          ),
        ),
      );
    } finally {
      _opening = false;

      if (mounted &&
          _pendingMessage != null &&
          !identical(_pendingMessage, message)) {
        _scheduleOpen();
      }
    }
  }

  Future<void> _navigate(String location) async {
    try {
      await appRouter.push<void>(location);
    } catch (_) {
      _showMessage('تعذر فتح الصفحة. افتحها من قائمة الإشعارات.');
    }
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final recipientId = message.data['recipient_user_id']?.toString();
    final notificationId = message.data['notification_id']?.toString();

    if (!_validId(recipientId) || !_validId(notificationId)) return;

    try {
      final profile = await ref
          .read(userProfileProvider.future)
          .timeout(const Duration(seconds: 30));

      if (!mounted ||
          FirebaseAuth.instance.currentUser?.uid != user.uid ||
          profile.firebaseUid != user.uid ||
          profile.id != recipientId ||
          !profile.isActive ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }

      final key = '$recipientId:$notificationId';

      if (_shownNotifications.contains(key)) return;

      final messenger = _messengerKey.currentState;

      if (messenger == null) return;

      _shownNotifications.add(key);

      if (_shownNotifications.length > 100) {
        _shownNotifications.remove(_shownNotifications.first);
      }

      final title = message.notification?.title ?? 'إشعار جديد';
      final body = message.notification?.body ?? '';

      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 7),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          action: SnackBarAction(
            label: 'عرض',
            onPressed: () {
              if (FirebaseAuth.instance.currentUser?.uid == user.uid) {
                _queueOpen(message);
              }
            },
          ),
        ),
      );
    } catch (_) {
      debugPrint('PUSH: unable to show foreground notification');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    authStateNotifier.removeListener(_scheduleOpen);

    _messageSubscription?.cancel();
    _openedSubscription?.cancel();
    _authSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTheme =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'Hellha',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: selectedTheme,
      themeAnimationDuration: Duration.zero,
      routerConfig: appRouter,
    );
  }
}
