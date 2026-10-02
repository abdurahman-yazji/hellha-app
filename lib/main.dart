import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/notifications/data/services/push_notification_service.dart';
import 'app.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Do not navigate or update widgets from this background handler.
}

Future<void> requestNotificationPermission() async {
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('NOTIFICATION PERMISSION: ${settings.authorizationStatus.name}');
    await PushNotificationService.instance.refresh();
  } catch (_) {
    debugPrint('NOTIFICATION PERMISSION: request failed');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  if (isAndroid) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(const ProviderScope(child: HellhaApp()));

  if (isAndroid) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestNotificationPermission();
    });
  }
}
