import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admin/presentation/pages/edit_admin_profile_page.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../../core/widgets/app_settings_drawer.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../technician/presentation/widgets/certificate_image_thumbnail.dart';
import '../../../admin/presentation/pages/verified_technicians_page.dart';
import '../../../admin/presentation/pages/specialization_change_requests_page.dart';
class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage> {
  final Set<String> _processingIds = {};

  Future<void> _approveTechnician(Map<String, dynamic> technician) async {
    final profileId = technician['technician_profile_id'].toString();
    final name = technician['name']?.toString() ?? 'الفني';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تأكيد توثيق الفني'),
          content: Text(
            'هل تريد توثيق حساب $name والسماح له باستقبال طلبات الصيانة؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('تأكيد التوثيق'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _processingIds.add(profileId);
    });

    try {
      await ref
          .read(adminServiceProvider)
          .updateVerification(technicianProfileId: profileId, isVerified: true);

      ref.invalidate(pendingTechniciansProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم توثيق حساب $name بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تعذر توثيق حساب الفني'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(profileId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingState = ref.watch(pendingTechniciansProvider);

    final adminName = widget.profile.name?.trim().isNotEmpty == true
        ? widget.profile.name!.trim()
        : 'المسؤول';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        endDrawer: const AppSettingsDrawer(),
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: [
            IconButton(
              tooltip: 'تعديل بياناتي',
              icon: const Icon(Icons.manage_accounts_outlined),
              onPressed: () {
                Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        EditAdminProfilePage(profile: widget.profile),
                  ),
                );
              },
            ),
            const AppMenuButton(),
          ],
        ),
        body: pendingState.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return _AdminErrorView(
              onRetry: () {
                ref.invalidate(pendingTechniciansProvider);
              },
            );
          },
          data: (technicians) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(pendingTechniciansProvider);
                await ref.read(pendingTechniciansProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    'مرحبًا، $adminName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'راجع حسابات الفنيين وأدر صلاحيات المنصة.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _AdminSummaryCard(pendingCount: technicians.length),

                  const SizedBox(height: 14),

                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const VerifiedTechniciansPage(),
                        ),
                      );

                      if (!mounted) return;

                      ref.invalidate(pendingTechniciansProvider);
                    },
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('إدارة الفنيين الموثّقين'),
                  ),

                  const SizedBox(height: 12),
OutlinedButton.icon(
  onPressed: () {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const SpecializationChangeRequestsPage(),
      ),
    );
  },
  icon: const Icon(Icons.rule_folder_outlined),
  label: const Text('طلبات تعديل التخصصات'),
),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'طلبات توثيق الفنيين',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${technicians.length} طلب',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (technicians.isEmpty)
                    const _EmptyPendingTechnicians()
                  else
                    ...technicians.map((technician) {
                      final profileId = technician['technician_profile_id']
                          .toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _TechnicianApprovalCard(
                          technician: technician,
                          isProcessing: _processingIds.contains(profileId),
                          onApprove: () {
                            _approveTechnician(technician);
                          },
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminSummaryCard extends StatelessWidget {
  const _AdminSummaryCard({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F3A), Color(0xFF163A63)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'لوحة تحكم المسؤول',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  pendingCount == 0
                      ? 'لا توجد طلبات توثيق جديدة'
                      : 'لديك $pendingCount طلب توثيق يحتاج إلى المراجعة',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.80)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianApprovalCard extends StatelessWidget {
  const _TechnicianApprovalCard({
    required this.technician,
    required this.isProcessing,
    required this.onApprove,
  });

  final Map<String, dynamic> technician;
  final bool isProcessing;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final name = technician['name']?.toString() ?? 'فني دون اسم';
    final email = technician['email']?.toString() ?? '';
    final phone = technician['phone']?.toString() ?? 'غير محدد';
    final workArea = technician['work_area']?.toString() ?? 'غير محددة';
    final experience = technician['years_of_experience']?.toString() ?? '0';

    final specializations =
        technician['specializations'] as List<dynamic>? ?? [];

    final certificates = technician['certificates'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.engineering_outlined,
                  color: colorScheme.primary,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'قيد المراجعة',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _InformationRow(
            icon: Icons.phone_outlined,
            label: 'الهاتف',
            value: phone,
          ),
          const SizedBox(height: 10),
          _InformationRow(
            icon: Icons.location_on_outlined,
            label: 'منطقة العمل',
            value: workArea,
          ),
          const SizedBox(height: 10),
          _InformationRow(
            icon: Icons.history_edu_outlined,
            label: 'سنوات الخبرة',
            value: '$experience سنوات',
          ),

          const SizedBox(height: 18),

          Text(
            'التخصصات',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 9),

          if (specializations.isEmpty)
            Text(
              'لم تتم إضافة تخصصات',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: specializations.map((item) {
                final specialization = Map<String, dynamic>.from(item as Map);

                return Chip(
                  avatar: Icon(
                    Icons.handyman_outlined,
                    size: 17,
                    color: colorScheme.primary,
                  ),
                  label: Text(specialization['name_ar']?.toString() ?? 'تخصص'),
                );
              }).toList(),
            ),

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                'عدد الشهادات: ${certificates.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (certificates.isEmpty)
            Text(
              'لم يرفق الفني شهادات.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else
            ...certificates.map((item) {
              final certificate = Map<String, dynamic>.from(item as Map);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CertificateReviewCard(
                  key: ValueKey('review-certificate-${certificate['id']}'),
                  certificate: certificate,
                ),
              );
            }),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : onApprove,
              icon: isProcessing
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.verified_outlined),
              label: Text(isProcessing ? 'جارٍ التوثيق...' : 'توثيق الفني'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 9),
        Text('$label:', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _EmptyPendingTechnicians extends StatelessWidget {
  const _EmptyPendingTechnicians();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 58, color: Colors.green.shade600),
          const SizedBox(height: 14),
          const Text(
            'تمت مراجعة جميع الطلبات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'لا توجد حسابات فنيين بانتظار التوثيق حاليًا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AdminErrorView extends StatelessWidget {
  const _AdminErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 58,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'تعذر تحميل طلبات الفنيين',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'تحقق من اتصال الخادم ثم حاول مرة أخرى.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateReviewCard extends StatelessWidget {
  const _CertificateReviewCard({required this.certificate, super.key});

  final Map<String, dynamic> certificate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final certificateId = certificate['id']?.toString();
    final hasImage = certificate['has_image'] == true;

    final name = certificate['certificate_name']?.toString() ?? 'شهادة';

    final organization =
        certificate['issuing_organization']?.toString().trim() ?? '';

    final issueDate = certificate['issue_date']?.toString();
    final expiryDate = certificate['expiry_date']?.toString();

    final documentUrl = certificate['document_url']?.toString().trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage && certificateId != null)
                CertificateImageThumbnail(
                  key: ValueKey('admin-image-$certificateId'),
                  certificateId: certificateId,
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    color: colors.primary,
                    size: 30,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (organization.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        organization,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      hasImage
                          ? 'اضغط على الصورة لتكبيرها'
                          : 'لا توجد صورة مرفقة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (issueDate != null) ...[
            const SizedBox(height: 12),
            Text('تاريخ الإصدار: $issueDate'),
          ],
          if (expiryDate != null) ...[
            const SizedBox(height: 6),
            Text('تاريخ الانتهاء: $expiryDate'),
          ],
          if (documentUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('رابط المستند', style: theme.textTheme.labelLarge),
            const SizedBox(height: 5),
            SelectableText(
              documentUrl,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: colors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
