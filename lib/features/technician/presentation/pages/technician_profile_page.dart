import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/technician_profile_provider.dart';

class TechnicianProfilePage extends ConsumerWidget {
  const TechnicianProfilePage({super.key});

  String _text(dynamic value, {String fallback = 'غير محدد'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(technicianProfileProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الملف المهني'),
        ),
        body: SafeArea(
          child: profileState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text('تعذر تحميل الملف المهني'),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(technicianProfileProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
            data: (profile) => RefreshIndicator(
              onRefresh: () async {
  ref.invalidate(technicianProfileProvider);
  await ref.read(technicianProfileProvider.future);
},
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _ProfileInfoCard(
                    icon: Icons.phone_outlined,
                    title: 'رقم الهاتف',
                    value: _text(profile['phone']),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'منطقة العمل',
                    value: _text(profile['work_area']),
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoCard(
                    icon: Icons.work_outline_rounded,
                    title: 'سنوات الخبرة',
                    value: _text(profile['years_of_experience']),
                  ),
                  const SizedBox(height: 12),
                  _ProfileInfoCard(
                    icon: Icons.person_outline_rounded,
                    title: 'نبذة مهنية',
                    value: _text(
                      profile['bio'],
                      fallback: 'لم تضف نبذة مهنية بعد.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      context.push('/technician/profile/edit');
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل البيانات'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.textDirection,
  });

  final IconData icon;
  final String title;
  final String value;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 7),
                SelectableText(
                  value,
                  textDirection: textDirection,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
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