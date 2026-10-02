import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';
import '../../../../core/widgets/app_settings_drawer.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userName = profile.name?.trim().isNotEmpty == true
        ? profile.name!.trim()
        : 'مستخدم حلّها';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        endDrawer: const AppSettingsDrawer(showJoinTechnician: true),
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: [
            NotificationBell(key: ValueKey(profile.id)),
            const AppMenuButton(),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                'مرحبًا، $userName',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'اشرح المشكلة وسنساعدك في الوصول إلى الحل المناسب.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.secondary,
                      colorScheme.secondary.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'ابدأ تشخيص المشكلة',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'صف العطل بوضوح ليحلله مساعد حلّها الذكي ويقترح الخطوات المناسبة.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        context.push('/diagnosis');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('اشرح المشكلة الآن'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'الوصول السريع',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'فتح طلبات الصيانة',
                      child: GestureDetector(
                        onTap: () {
                          context.go('/maintenance-requests');
                        },
                        child: _HomeActionCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'طلباتي',
                          subtitle: 'تابع طلبات الصيانة',
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'تصفح الفنيين المتاحين',
                      child: GestureDetector(
                        onTap: () {
                          context.go('/technicians');
                        },
                        child: _HomeActionCard(
                          icon: Icons.handyman_outlined,
                          title: 'الفنيون',
                          subtitle: 'ابحث عن فني مناسب',
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'فتح سجل التشخيصات',
                child: GestureDetector(
                  onTap: () {
                    context.go('/diagnosis/history');
                  },
                  child: _HomeActionCard(
                    icon: Icons.history_rounded,
                    title: 'سجل التشخيصات',
                    subtitle: 'راجع نتائج التشخيصات السابقة',
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'خدمات الصيانة',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _ServiceChip(
                    icon: Icons.electrical_services_outlined,
                    label: 'الكهرباء',
                  ),
                  _ServiceChip(icon: Icons.plumbing_outlined, label: 'السباكة'),
                  _ServiceChip(icon: Icons.ac_unit_outlined, label: 'التكييف'),
                  _ServiceChip(
                    icon: Icons.kitchen_outlined,
                    label: 'الأجهزة المنزلية',
                  ),
                  _ServiceChip(
                    icon: Icons.foundation_outlined,
                    label: 'البناء والتشققات',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
