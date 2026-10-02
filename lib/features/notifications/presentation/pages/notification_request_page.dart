import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../maintenance_requests/data/services/maintenance_request_service.dart';
import '../../../maintenance_requests/domain/models/maintenance_request.dart';
import '../../../maintenance_requests/presentation/pages/maintenance_request_details_page.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/services/notification_service.dart';

typedef NotificationRequestDetails = ({
  MaintenanceRequest request,
  bool isTechnicianView,
});

class NotificationRequestPage extends ConsumerStatefulWidget {
  const NotificationRequestPage({
    required this.requestId,
    required this.notificationId,
    required this.recipientUserId,
    super.key,
  });

  final String requestId;
  final String notificationId;
  final String recipientUserId;

  @override
  ConsumerState<NotificationRequestPage> createState() =>
      _NotificationRequestPageState();
}

class _NotificationRequestPageState
    extends ConsumerState<NotificationRequestPage> {
  final _requestService = MaintenanceRequestService();
  final _notificationService = NotificationService();

  late Future<NotificationRequestDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _load();
  }

  Future<NotificationRequestDetails> _load() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('سجّل الدخول لعرض الطلب.');
    }

    final profile = await ref.read(userProfileProvider.future);

    if (!mounted ||
        FirebaseAuth.instance.currentUser?.uid != user.uid ||
        profile.firebaseUid != user.uid) {
      throw StateError('تغير الحساب. أعد فتح الإشعار.');
    }

    if (profile.id != widget.recipientUserId) {
      throw StateError('هذا الإشعار يخص حسابًا آخر.');
    }

    if (!profile.isActive) {
      throw StateError('هذا الحساب غير نشط.');
    }

    final details = await _requestService.getRequestDetails(widget.requestId);

    if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
      throw StateError('تغير الحساب. أعد فتح الإشعار.');
    }

    unawaited(_markAsRead(user.uid));

    return details;
  }

  Future<void> _markAsRead(String firebaseUid) async {
    if (FirebaseAuth.instance.currentUser?.uid != firebaseUid) return;

    try {
      await _notificationService.markAsRead(widget.notificationId);
    } catch (_) {
      // Failure to mark as read must not prevent viewing the request.
      debugPrint('PUSH: could not mark notification as read');
    }
  }

  void _retry() {
    setState(() {
      _detailsFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<NotificationRequestDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              !snapshot.hasError &&
              snapshot.hasData) {
            final details = snapshot.data!;

            return MaintenanceRequestDetailsPage(
              request: details.request,
              isTechnicianView: details.isTechnicianView,
            );
          }

          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل الطلب')),
            body: SafeArea(
              child: snapshot.hasError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 44),
                            const SizedBox(height: 16),
                            Text(
                              snapshot.error is StateError
                                  ? (snapshot.error! as StateError).message
                                  : 'تعذر تحميل الطلب. تحقق من الاتصال '
                                        'وحاول مجددًا.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          );
        },
      ),
    );
  }
}
