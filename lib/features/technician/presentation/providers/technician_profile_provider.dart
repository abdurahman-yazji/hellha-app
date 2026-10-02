import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/technician_service.dart';

final technicianServiceProvider = Provider<TechnicianService>((ref) {
  return TechnicianService();
});

final technicianProfileProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final technicianService = ref.read(technicianServiceProvider);

  return technicianService.getMyProfile();
});
