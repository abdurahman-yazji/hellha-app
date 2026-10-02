import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/data/services/push_notification_service.dart';
import '../../data/services/user_service.dart';
import '../../domain/models/user_profile.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final user = await ref.watch(authStateProvider.future);

  if (user == null) {
    throw StateError('User is not authenticated');
  }

  var disposed = false;

  ref.onDispose(() {
    disposed = true;
  });

  final userService = ref.read(userServiceProvider);

  await userService.syncUser();

  final data = await userService.getProfile();
  final profile = UserProfile.fromJson(data);

  if (!disposed) {
    unawaited(PushNotificationService.instance.activateForUser(user));
  }

  return profile;
});
