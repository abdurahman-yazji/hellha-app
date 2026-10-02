import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hellha/features/notifications/presentation/widgets/notification_bell.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_settings_drawer.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../technician/presentation/providers/technician_profile_provider.dart';
import '../../../technician/data/services/technician_service.dart';

class TechnicianHomePage extends ConsumerWidget {
  const TechnicianHomePage({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final technicianState = ref.watch(technicianProfileProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        endDrawer: const AppSettingsDrawer(),
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: [
            NotificationBell(key: ValueKey(profile.id)),
            const AppMenuButton(),
          ],
        ),
        body: technicianState.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return _ErrorView(
              onRetry: () {
                ref.invalidate(technicianProfileProvider);
              },
            );
          },
          data: (technician) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(technicianProfileProvider);
                await ref.read(technicianProfileProvider.future);
              },
              child: _TechnicianDashboard(
                userProfile: profile,
                technician: technician,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TechnicianDashboard extends ConsumerWidget {
  const _TechnicianDashboard({
    required this.userProfile,
    required this.technician,
  });

  final UserProfile userProfile;
  final Map<String, dynamic> technician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final name = userProfile.name?.trim().isNotEmpty == true
        ? userProfile.name!.trim()
        : 'الفني';

    final isVerified = technician['is_verified'] == true;
    final availabilityStatus =
        technician['availability_status']?.toString() ?? 'unavailable';

    final isAvailable = availabilityStatus == 'available';
    final rating = technician['average_rating']?.toString() ?? '0.00';
    final completedJobs = technician['total_completed_jobs']?.toString() ?? '0';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
  children: [
    Flexible(
      child: Text(
        'مرحبًا، $name',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    if (isVerified) ...[
      const SizedBox(width: 8),
      const Tooltip(
        message: 'حساب موثّق',
        child: Icon(
          Icons.verified_rounded,
          color: Colors.green,
          size: 26,
          semanticLabel: 'حساب موثّق',
        ),
      ),
    ],
  ],
),
        const SizedBox(height: 6),
        Text(
          'تابع أعمالك وطلبات الصيانة من مكان واحد.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),

        if (!isVerified) ...[
  const _VerificationCard(isVerified: false),
  const SizedBox(height: 16),
],

        _AvailabilityCard(isAvailable: isAvailable, isVerified: isVerified),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _StatisticCard(
                icon: Icons.star_rounded,
                iconColor: Colors.amber.shade700,
                value: rating,
                label: 'التقييم',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatisticCard(
                icon: Icons.task_alt_rounded,
                iconColor: colorScheme.primary,
                value: completedJobs,
                label: 'مهام مكتملة',
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        Text(
          'إدارة الحساب',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),

        GridView.count(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: 1.35,
  shrinkWrap: true,
  padding: EdgeInsets.zero,
  physics: const NeverScrollableScrollPhysics(),
  children: [
    _DashboardAction(
      icon: Icons.assignment_outlined,
      title: 'طلبات الصيانة',
      subtitle: 'عرض الطلبات الجديدة والحالية',
      onTap: () {
  context.go('/technician/maintenance-requests');
},
    ),
    _DashboardAction(
      icon: Icons.person_outline_rounded,
      title: 'الملف المهني',
      subtitle: 'معلوماتك وخبراتك ومنطقة العمل',
      onTap: () {
        context.push('/technician/profile');
      },
    ),
    _DashboardAction(
      icon: Icons.handyman_outlined,
      title: 'التخصصات',
      subtitle: 'تخصصات الصيانة التي تقدمها',
      onTap: () {
        context.push('/technician/specializations');
      },
    ),
    _DashboardAction(
      icon: Icons.workspace_premium_outlined,
      title: 'الشهادات',
      subtitle: 'إدارة الشهادات المهنية',
      onTap: () {
        context.push('/technician/certificates');
      },
    ),
  ],
),
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.isVerified});

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? Colors.green : Colors.orange;
    final icon = isVerified ? Icons.verified_rounded : Icons.schedule_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'حساب موثّق' : 'بانتظار التوثيق',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isVerified
                      ? 'يمكنك استقبال طلبات الصيانة الجديدة.'
                      : 'سيتم تفعيل استقبال الطلبات بعد مراجعة الإدارة.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends ConsumerStatefulWidget {
  const _AvailabilityCard({
    required this.isAvailable,
    required this.isVerified,
  });

  final bool isAvailable;
  final bool isVerified;

  @override
  ConsumerState<_AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends ConsumerState<_AvailabilityCard> {
  final _service = TechnicianService();
  bool _isSaving = false;

  Future<void> _changeAvailability(bool available) async {
    if (_isSaving) return;
    if (available && !widget.isVerified) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.updateMyProfile(
        availabilityStatus: available ? 'available' : 'unavailable',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            available
                ? 'أصبحت متاحًا لاستقبال الطلبات'
                : 'تم إيقاف استقبال الطلبات الجديدة',
          ),
        ),
      );

      ref.invalidate(technicianProfileProvider);
      
    } on StateError catch (error) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.message)),
  );
  }catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر تأكيد تغيير الحالة. حدّث الصفحة للتحقق ثم حاول مجددًا.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            widget.isAvailable
                ? Icons.radio_button_checked_rounded
                : Icons.pause_circle_outline_rounded,
            color: widget.isAvailable ? Colors.green : colors.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة استقبال الطلبات',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.isAvailable ? 'متاح حاليًا' : 'غير متاح حاليًا',
                  style: TextStyle(
                    color: widget.isAvailable
                        ? Colors.green
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!widget.isVerified) ...[
                  const SizedBox(height: 4),
                  Text(
                    'يجب توثيق الحساب لتفعيل التوفر',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_isSaving)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: widget.isAvailable,
              onChanged: widget.isVerified || widget.isAvailable
                  ? _changeAvailability
                  : null,
            ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderRadius = BorderRadius.circular(20);

    return Tooltip(
      message: subtitle,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

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
              'تعذر تحميل بيانات الفني',
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
