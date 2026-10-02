import 'package:flutter/material.dart';

import 'package:hellha/features/admin/data/services/admin_service.dart';

class VerifiedTechniciansPage extends StatefulWidget {
  const VerifiedTechniciansPage({super.key});

  @override
  State<VerifiedTechniciansPage> createState() =>
      _VerifiedTechniciansPageState();
}

class _VerifiedTechniciansPageState extends State<VerifiedTechniciansPage> {
  final _service = AdminService();
  final Set<String> _processingIds = {};

  late Future<List<Map<String, dynamic>>> _techniciansFuture;

  @override
  void initState() {
    super.initState();
    _techniciansFuture = _service.getVerifiedTechnicians();
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    final future = _service.getVerifiedTechnicians();

    setState(() {
      _techniciansFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the loading error.
    }
  }

  Future<void> _revoke(Map<String, dynamic> technician) async {
    final id = technician['technician_profile_id'].toString();
    final name = technician['name']?.toString() ?? 'الفني';

    if (_processingIds.contains(id)) return;

    setState(() {
      _processingIds.add(id);
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('إلغاء توثيق الفني'),
              content: Text(
                'هل تريد إلغاء توثيق $name؟\n\n'
                'سيصبح غير متاح لاستقبال طلبات جديدة، '
                'وسيعود إلى قائمة انتظار التوثيق.\n\n'
                'هذا الإجراء لا يلغي طلباته الحالية.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('تراجع'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(dialogContext).colorScheme.error,
                    foregroundColor: Theme.of(
                      dialogContext,
                    ).colorScheme.onError,
                    minimumSize: const Size(0, 48),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('إلغاء التوثيق'),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted || confirmed != true) return;

      await _service.updateVerification(
        technicianProfileId: id,
        isVerified: false,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم إلغاء توثيق $name')));

      await _refresh();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر تأكيد إلغاء التوثيق. حدّث القائمة للتحقق ثم حاول مجددًا.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الفنيون الموثّقون'),
          actions: [
            IconButton(
              onPressed: _refresh,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _techniciansFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                debugPrint('VERIFIED TECHNICIANS ERROR: ${snapshot.error}');

                return Center(
                  child: OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تعذر تحميل الفنيين — إعادة المحاولة'),
                  ),
                );
              }

              final technicians = snapshot.data ?? const [];

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (technicians.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(Icons.verified_outlined, size: 60),
                            SizedBox(height: 16),
                            Text('لا يوجد فنيون موثّقون حاليًا'),
                          ],
                        ),
                      )
                    else
                      ...technicians.map((technician) {
                        final id = technician['technician_profile_id']
                            .toString();
                        final isProcessing = _processingIds.contains(id);

                        final name =
                            technician['name']?.toString() ?? 'فني دون اسم';
                        final phone =
                            technician['phone']?.toString() ?? 'غير محدد';
                        final area =
                            technician['work_area']?.toString() ?? 'غير محددة';
                        final isActive = technician['is_active'] == true;
                        final isAvailable =
                            technician['availability_status'] == 'available';

                        return Container(
                          key: ValueKey(id),
                          margin: const EdgeInsets.only(bottom: 14),
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
                                  Icon(
                                    Icons.verified_rounded,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text('الهاتف: $phone'),
                              const SizedBox(height: 7),
                              Text('منطقة العمل: $area'),
                              const SizedBox(height: 7),
                              Text(
                                !isActive
                                    ? 'الحساب غير نشط'
                                    : isAvailable
                                    ? 'متاح لاستقبال الطلبات'
                                    : 'غير متاح حاليًا',
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: isProcessing
                                      ? null
                                      : () => _revoke(technician),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.error,
                                  ),
                                  icon: isProcessing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.remove_moderator_outlined,
                                        ),
                                  label: Text(
                                    isProcessing
                                        ? 'جارٍ المعالجة...'
                                        : 'إلغاء التوثيق',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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
