import 'package:flutter/material.dart';
import 'maintenance_request_details_page.dart';
import '../../data/services/maintenance_request_service.dart';
import '../../domain/models/maintenance_request.dart';

class TechnicianMaintenanceRequestsPage extends StatefulWidget {
  const TechnicianMaintenanceRequestsPage({super.key});

  @override
  State<TechnicianMaintenanceRequestsPage> createState() =>
      _TechnicianMaintenanceRequestsPageState();
}

class _TechnicianMaintenanceRequestsPageState
    extends State<TechnicianMaintenanceRequestsPage> {
  final _service = MaintenanceRequestService();
  final Set<String> _updatingRequestIds = {};

  late Future<List<MaintenanceRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture = _service.getTechnicianRequests();
  }

  Future<void> _refresh() async {
    setState(_loadRequests);
    await _requestsFuture;
  }

  Future<void> _updateStatus({
    required MaintenanceRequest request,
    required String status,
  }) async {
    setState(() {
      _updatingRequestIds.add(request.id);
    });

    try {
      await _service.updateTechnicianRequestStatus(
        requestId: request.id,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        _updatingRequestIds.remove(request.id);
        _loadRequests();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'in_progress'
                ? 'تم بدء العمل على الطلب'
                : 'تم إكمال الطلب بنجاح',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _updatingRequestIds.remove(request.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _declineRequest(MaintenanceRequest request) async {
    if (_updatingRequestIds.contains(request.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('الاعتذار عن الطلب'),
            content: const Text(
              'هل تريد الاعتذار عن هذا الطلب؟ '
              'سيعود للمستخدم لاختيار فني آخر.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('رجوع'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('تأكيد الاعتذار'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || confirmed != true) return;
    if (_updatingRequestIds.contains(request.id)) return;

    setState(() {
      _updatingRequestIds.add(request.id);
    });

    try {
      await _service.declineTechnicianRequest(requestId: request.id);

      if (!mounted) return;

      setState(() {
        _updatingRequestIds.remove(request.id);
        _loadRequests();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم الاعتذار عن الطلب')));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _updatingRequestIds.remove(request.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _retry() {
    setState(_loadRequests);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلبات الصيانة')),
        body: SafeArea(
          child: FutureBuilder<List<MaintenanceRequest>>(
            future: _requestsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _RequestsError(onRetry: _retry);
              }

              final requests = snapshot.data ?? const [];

              if (requests.isEmpty) {
                return const _EmptyRequests();
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final request = requests[index];

                    return _TechnicianRequestCard(
                      request: request,
                      isUpdating: _updatingRequestIds.contains(request.id),
                      onStart: () {
                        _updateStatus(request: request, status: 'in_progress');
                      },
                      onComplete: () {
                        _updateStatus(request: request, status: 'completed');
                      },
                      onDecline: () {
                        _declineRequest(request);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TechnicianRequestCard extends StatelessWidget {
  const _TechnicianRequestCard({
    required this.request,
    required this.isUpdating,
    required this.onStart,
    required this.onComplete,
    required this.onDecline,
  });

  final MaintenanceRequest request;
  final bool isUpdating;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onDecline;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _statusColor(request.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.specializationName ?? 'طلب صيانة',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(request.status),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            request.problemTitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (request.diagnosisDescription != null) ...[
            const SizedBox(height: 7),
            Text(
              request.diagnosisDescription!,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.45),
            ),
          ],
          const Divider(height: 28),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            text:
                'العميل: '
                '${request.customerName ?? 'غير محدد'}',
          ),
          const SizedBox(height: 9),
          _InfoRow(
            icon: Icons.phone_outlined,
            text:
                'رقم التواصل: '
                '${request.contactPhone}',
          ),
          const SizedBox(height: 9),
          _InfoRow(
            icon: Icons.location_on_outlined,
            text:
                '${request.workArea} - '
                '${request.addressDetails}',
          ),
          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 9),
            _InfoRow(icon: Icons.notes_rounded, text: request.notes!),
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUpdating
                  ? null
                  : () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => MaintenanceRequestDetailsPage(
                            request: request,
                            isTechnicianView: true,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.description_outlined),
              label: const Text('عرض تفاصيل الطلب'),
            ),
          ),

          const SizedBox(height: 12),

          if (request.status == 'assigned')
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: isUpdating ? null : onStart,
                  icon: isUpdating
                      ? const _ButtonLoader()
                      : const Icon(Icons.play_arrow_rounded),
                  label: const Text('بدء العمل'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isUpdating ? null : onDecline,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('الاعتذار عن الطلب'),
                ),
              ],
            )
          else if (request.status == 'in_progress')
            FilledButton.icon(
              onPressed: isUpdating ? null : onComplete,
              icon: isUpdating
                  ? const _ButtonLoader()
                  : const Icon(Icons.task_alt_rounded),
              label: const Text('إكمال الطلب'),
            )
          else if (request.status == 'completed')
            const _CompletedMessage(),
        ],
      ),
    );
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'طلب جديد';
      case 'in_progress':
        return 'قيد التنفيذ';
      case 'completed':
        return 'مكتمل';
      case 'closed':
        return 'مغلق';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'assigned':
        return const Color(0xFF2563EB);
      case 'in_progress':
        return const Color(0xFFD97706);
      case 'completed':
        return const Color(0xFF15803D);
      case 'closed':
        return const Color(0xFF475569);
      case 'cancelled':
        return const Color(0xFFD92D20);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _ButtonLoader extends StatelessWidget {
  const _ButtonLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 19,
      height: 19,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}

class _CompletedMessage extends StatelessWidget {
  const _CompletedMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green),
          SizedBox(width: 8),
          Text(
            'تم إكمال هذا الطلب',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'لا توجد طلبات صيانة مسندة إليك حاليًا.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _RequestsError extends StatelessWidget {
  const _RequestsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('تعذر تحميل الطلبات - إعادة المحاولة'),
      ),
    );
  }
}
