import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/notification_service.dart';
import '../../domain/models/app_notification.dart';
import '../../../maintenance_requests/data/services/maintenance_request_service.dart';
import '../../../maintenance_requests/presentation/pages/maintenance_request_details_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationService();
  final _requestService = MaintenanceRequestService();
  late Future<List<AppNotification>> _notificationsFuture;

  final Set<String> _processingIds = {};
  bool _markingAll = false;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _service.getMyNotifications();
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    final future = _service.getMyNotifications();

    setState(() {
      _notificationsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (_markingAll || _processingIds.isNotEmpty) return;
    final openingUserUid = FirebaseAuth.instance.currentUser?.uid;
if (openingUserUid == null) return;
    setState(() {
      _processingIds.add(notification.id);
    });

    try {
      if (!notification.isRead) {
        try {
          await _service.markAsRead(notification.id);
        } catch (_) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر تأكيد قراءة الإشعار، سنحاول فتح الصفحة.'),
            ),
          );
        }
      }

      if (!mounted) return;
if (FirebaseAuth.instance.currentUser?.uid != openingUserUid) {
  return;
}

final isSpecializationNotification =
    notification.type == 'specialization_change_approved' ||
    notification.type == 'specialization_change_rejected';

if (isSpecializationNotification) {
  await context.push<void>('/technician/specializations');
  return;
}
      final requestId = notification.maintenanceRequestId;

      if (requestId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد طلب مرتبط بهذا الإشعار حاليًا.'),
          ),
        );
        return;
      }

      final details = await _requestService.getRequestDetails(requestId);

      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => MaintenanceRequestDetailsPage(
            request: details.request,
            isTechnicianView: details.isTechnicianView,
          ),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الإشعار. تحقق من الاتصال وحاول مجددًا.'),
        ),
      );
    } finally {
      if (mounted) {
        await _refresh();
      }

      if (mounted) {
        setState(() {
          _processingIds.remove(notification.id);
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || _processingIds.isNotEmpty) return;

    setState(() {
      _markingAll = true;
    });

    try {
      await _service.markAllAsRead();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديد جميع الإشعارات كمقروءة')),
      );

      await _refresh();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تأكيد العملية. حدّث القائمة وحاول مجددًا.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _markingAll = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _markingAll || _processingIds.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإشعارات'),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: isBusy ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'تحديد جميع الإشعارات كمقروءة',
              onPressed: isBusy ? null : _markAllRead,
              icon: _markingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<AppNotification>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                debugPrint('NOTIFICATIONS ERROR: ${snapshot.error}');

                return Center(
                  child: OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تعذر تحميل الإشعارات — إعادة المحاولة'),
                  ),
                );
              }

              final notifications = snapshot.data ?? const [];

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    if (notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 70),
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 64),
                            SizedBox(height: 16),
                            Text('لا توجد إشعارات حاليًا'),
                          ],
                        ),
                      )
                    else ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'اضغط على الإشعار لعرض التفاصيل وتحديده كمقروء.',
                        ),
                      ),
                      ...notifications.map(
                        (notification) => _NotificationCard(
                          key: ValueKey(notification.id),
                          notification: notification,
                          isProcessing: _processingIds.contains(
                            notification.id,
                          ),
                          onTap: isBusy
                              ? null
                              : () => _openNotification(notification),
                        ),
                      ),
                      if (notifications.length == 50)
                        const Text(
                          'تُعرض أحدث 50 رسالة. '
                          'تحديد الجميع كمقروء يشمل الإشعارات الأقدم أيضًا.',
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isProcessing,
    required this.onTap,
    super.key,
  });

  final AppNotification notification;
  final bool isProcessing;
  final VoidCallback? onTap;

  IconData _icon() {
    switch (notification.type) {
      case 'request_assigned':
      case 'request_reassigned':
        return Icons.assignment_ind_outlined;
      case 'request_started':
        return Icons.build_outlined;
      case 'request_completed':
        return Icons.task_alt_rounded;
      case 'request_declined':
        return Icons.person_off_outlined;
      case 'request_cancelled':
        return Icons.cancel_outlined;
      case 'request_reviewed':
        return Icons.star_outline_rounded;
        case 'specialization_change_approved':
  return Icons.verified_outlined;

case 'specialization_change_rejected':
  return Icons.rule_folder_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} - $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: unread ? colors.primary.withValues(alpha: 0.08) : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: unread ? colors.primary : colors.outlineVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon(), color: colors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: unread
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _formatDate(notification.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        unread ? 'غير مقروء' : 'مقروء',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: unread
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isProcessing) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
