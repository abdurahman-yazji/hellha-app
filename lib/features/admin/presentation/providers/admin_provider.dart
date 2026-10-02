import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

final pendingTechniciansProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final user = await ref.watch(authStateProvider.future);

      if (user == null) {
        throw StateError('User is not authenticated');
      }

      final adminService = ref.read(adminServiceProvider);

      return adminService.getPendingTechnicians();
    });
