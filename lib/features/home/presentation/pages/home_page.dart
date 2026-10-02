import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_settings_drawer.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'admin_home_page.dart';
import 'technician_home_page.dart';
import 'user_home_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);

    return profileState.when(
      loading: () {
        return const _LoadingHomePage();
      },
      error: (error, stackTrace) {
        return _ProfileErrorPage(
          onRetry: () {
            ref.invalidate(userProfileProvider);
          },
        );
      },
      data: (profile) {
        if (!profile.isActive) {
          return const _InactiveAccountPage();
        }

        return _buildRoleHomePage(profile);
      },
    );
  }

  Widget _buildRoleHomePage(UserProfile profile) {
    switch (profile.role) {
      case 'user':
        return UserHomePage(profile: profile);

      case 'technician':
        return TechnicianHomePage(profile: profile);

      case 'admin':
        return AdminHomePage(profile: profile);

      default:
        return _UnsupportedRolePage(role: profile.role);
    }
  }
}

class _LoadingHomePage extends StatelessWidget {
  const _LoadingHomePage();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 18),
              Text('جارٍ تحميل بيانات الحساب...'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileErrorPage extends StatelessWidget {
  const _ProfileErrorPage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        endDrawer: const AppSettingsDrawer(),
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: const [AppMenuButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 64,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 18),
                Text(
                  'تعذر تحميل بيانات الحساب',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'تأكد من تشغيل الخادم والاتصال بالإنترنت، ثم حاول مرة أخرى.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InactiveAccountPage extends StatelessWidget {
  const _InactiveAccountPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        endDrawer: const AppSettingsDrawer(),
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: const [AppMenuButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded, size: 68, color: colorScheme.error),
                const SizedBox(height: 18),
                Text(
                  'الحساب غير نشط',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تم تعطيل هذا الحساب. تواصل مع إدارة التطبيق للحصول على المساعدة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService().signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnsupportedRolePage extends StatelessWidget {
  const _UnsupportedRolePage({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        endDrawer: const AppSettingsDrawer(),
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: const [AppMenuButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.manage_accounts_outlined,
                  size: 68,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'دور الحساب غير مدعوم',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تعذر فتح واجهة مناسبة للدور: $role',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService().signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
