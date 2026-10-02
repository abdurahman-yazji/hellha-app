import 'package:flutter/material.dart';
import 'maintenance_request_details_page.dart';
import '../../data/services/maintenance_request_service.dart';
import '../../domain/models/maintenance_request.dart';
import '../../../technician/data/services/technician_service.dart';
import '../widgets/maintenance_request_review_dialog.dart';

class MyMaintenanceRequestsPage extends StatefulWidget {
  const MyMaintenanceRequestsPage({super.key});

  @override
  State<MyMaintenanceRequestsPage> createState() =>
      _MyMaintenanceRequestsPageState();
}

class _MyMaintenanceRequestsPageState extends State<MyMaintenanceRequestsPage> {
  final _service = MaintenanceRequestService();
  final _technicianService = TechnicianService();
  final Set<String> _reassigningIds = {};
  final Set<String> _reviewingIds = {};
  final Set<String> _cancellingIds = {};
  late Future<List<MaintenanceRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    _requestsFuture = _service.getMyRequests();
  }

  Future<void> _refresh() async {
    setState(_loadRequests);
    await _requestsFuture;
  }

  Future<void> _chooseTechnician(MaintenanceRequest request) async {
    if (_reassigningIds.contains(request.id) ||
        _cancellingIds.contains(request.id)) {
      return;
    }

    setState(() {
      _reassigningIds.add(request.id);
    });

    try {
      final technicians = await _technicianService
          .getAvailableTechnicians(
            specializationId: request.specializationId,
            workArea: request.workArea,
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (technicians.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يوجد فنيون متاحون لهذا التخصص حاليًا'),
          ),
        );
        return;
      }

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * 0.65,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'اختر الفني المناسب',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: technicians.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final technician = technicians[index];
                          final name = technician['name']?.toString().trim();
                          final area =
                              technician['work_area']?.toString() ??
                              'المنطقة غير محددة';
                          final experience =
                              technician['years_of_experience'] ?? 0;
                          final completed =
                              technician['total_completed_jobs'] ?? 0;
                          final rating = technician['average_rating'] ?? 0;

                          return ListTile(
                            isThreeLine: true,
                            leading: const Icon(Icons.engineering_outlined),
                            title: Text(
                              name == null || name.isEmpty ? 'فني صيانة' : name,
                            ),
                            subtitle: Text(
                              '$area • خبرة $experience سنة\n'
                              'التقييم: $rating • أعمال مكتملة: $completed',
                            ),
                            trailing: const Icon(Icons.chevron_left_rounded),
                            onTap: () {
                              Navigator.of(sheetContext).pop(technician);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (!mounted || selected == null) return;

      final technicianId = selected['id']?.toString();

      if (technicianId == null || technicianId.isEmpty) {
        throw StateError('Missing technician ID');
      }

      final technicianName = selected['name']?.toString() ?? 'الفني المختار';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد اختيار الفني'),
              content: Text('هل تريد إرسال الطلب إلى $technicianName؟'),
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
                  child: const Text('إرسال الطلب'),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted || confirmed != true) return;

      await _service.reassignMyRequest(
        requestId: request.id,
        technicianProfileId: technicianId,
      );

      if (!mounted) return;

      setState(_loadRequests);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب للفني المختار')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر إتمام العملية. حدّث الطلبات وتحقق من حالة الطلب قبل المحاولة مجددًا.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reassigningIds.remove(request.id);
        });
      }
    }
  }

  Future<void> _reviewRequest(MaintenanceRequest request) async {
    if (_reviewingIds.contains(request.id)) return;

    setState(() {
      _reviewingIds.add(request.id);
    });

    try {
      final input = await showDialog<MaintenanceRequestReviewInput>(
        context: context,
        builder: (_) => const MaintenanceRequestReviewDialog(),
      );

      if (!mounted || input == null) return;

      await _service.reviewMyRequest(
        requestId: request.id,
        rating: input.rating,
        comment: input.comment,
      );

      if (!mounted) return;

      setState(_loadRequests);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ تقييمك وإغلاق الطلب')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر تأكيد حفظ التقييم. '
            'حدّث قائمة الطلبات قبل المحاولة مجددًا.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reviewingIds.remove(request.id);
        });
      }
    }
  }

  Future<void> _cancelRequest(MaintenanceRequest request) async {
    if (_cancellingIds.contains(request.id) ||
        _reassigningIds.contains(request.id) ||
        _reviewingIds.contains(request.id)) {
      return;
    }

    if (request.status != 'created' && request.status != 'assigned') {
      return;
    }

    setState(() {
      _cancellingIds.add(request.id);
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final colors = Theme.of(dialogContext).colorScheme;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('إلغاء طلب الصيانة'),
              content: const Text(
                'هل تريد إلغاء هذا الطلب؟\n\n'
                'سيبقى ظاهرًا في سجلك بحالة «ملغي». '
                'لا يمكن إعادة إرسال طلب لنفس التشخيص حاليًا.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('الاحتفاظ بالطلب'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('إلغاء الطلب'),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted || confirmed != true) return;

      try {
        await _service.cancelMyRequest(requestId: request.id);

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب بنجاح')));
      } on StateError catch (error) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      } catch (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تأكيد الإلغاء. تحقق من حالة الطلب '
              'بعد تحديث القائمة قبل المحاولة مجددًا.',
            ),
          ),
        );
      } finally {
        // Reload even after a timeout: the server may have saved the change.
        if (mounted) {
          setState(_loadRequests);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _cancellingIds.remove(request.id);
        });
      }
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
        appBar: AppBar(title: const Text('طلباتي')),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = requests[index];

                    return _RequestCard(
                      request: request,
                      isReassigning: _reassigningIds.contains(request.id),
                      onChooseTechnician: () {
                        _chooseTechnician(request);
                      },
                      isReviewing: _reviewingIds.contains(request.id),
                      onReview: () {
                        _reviewRequest(request);
                      },
                      isCancelling: _cancellingIds.contains(request.id),
                      onCancel: () {
                        _cancelRequest(request);
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isReassigning,
    required this.onChooseTechnician,
    required this.isReviewing,
    required this.onReview,
    required this.isCancelling,
    required this.onCancel,
  });

  final MaintenanceRequest request;
  final bool isReassigning;
  final VoidCallback onChooseTechnician;
  final bool isReviewing;
  final VoidCallback onReview;
  final bool isCancelling;
  final VoidCallback onCancel;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _statusColor(request.status);

    return Container(
      padding: const EdgeInsets.all(17),
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
          const SizedBox(height: 12),
                    Text(
            request.problemTitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.engineering_outlined,
            text: request.technicianName == null
                ? 'لم يتم اختيار فني'
                : 'الفني: ${request.technicianName}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.location_on_outlined,
            text:
                '${request.workArea} - '
                '${request.addressDetails}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.schedule_rounded,
            text: _formatDate(request.createdAt),
          ),
          if (request.technicianPhone != null &&
              request.technicianPhone!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone_outlined,
              text:
                  'هاتف الفني: '
                  '${request.technicianPhone}',
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isCancelling || isReassigning || isReviewing
                  ? null
                  : () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              MaintenanceRequestDetailsPage(request: request),
                        ),
                      );
                    },
              icon: const Icon(Icons.description_outlined),
              label: const Text('عرض التفاصيل'),
            ),
          ),
          if (request.status == 'created' || request.status == 'assigned') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isCancelling || isReassigning ? null : onCancel,
                style: OutlinedButton.styleFrom(foregroundColor: colors.error),
                icon: isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: Text(
                  isCancelling ? 'جارٍ إلغاء الطلب...' : 'إلغاء الطلب',
                ),
              ),
            ),
          ],
          if (request.status == 'created' &&
              request.technicianProfileId == null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isReassigning || isCancelling
                  ? null
                  : onChooseTechnician,
              icon: isReassigning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_search_rounded),
              label: Text(
                isReassigning ? 'جارٍ تنفيذ العملية...' : 'اختيار فني',
              ),
            ),
          ],
          if (request.status == 'completed') ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isReviewing ? null : onReview,
              icon: isReviewing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.star_outline_rounded),
              label: Text(
                isReviewing
                    ? 'جارٍ تأكيد التقييم...'
                    : 'تأكيد الإنجاز والتقييم',
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} - $hour:$minute';
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'created':
        return 'تم الإنشاء';
      case 'assigned':
        return 'تم الإسناد';
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
      case 'created':
        return const Color(0xFF6B7280);
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

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              'لا توجد طلبات صيانة',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'عند إرسال طلب إلى فني سيظهر هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
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
