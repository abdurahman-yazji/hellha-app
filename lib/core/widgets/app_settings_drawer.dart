import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../constants/app_constants.dart';
import '../theme/theme_mode_provider.dart';

class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'فتح القائمة',
      icon: const Icon(Icons.menu_rounded),
      onPressed: () {
        Scaffold.of(context).openEndDrawer();
      },
    );
  }
}

class AppSettingsDrawer extends ConsumerStatefulWidget {
  const AppSettingsDrawer({
    this.showJoinTechnician = false,
    super.key,
  });

  final bool showJoinTechnician;

  @override
  ConsumerState<AppSettingsDrawer> createState() =>
      _AppSettingsDrawerState();
}

class _AppSettingsDrawerState extends ConsumerState<AppSettingsDrawer> {
  bool _savingTheme = false;
  bool _signingOut = false;

  Future<void> _changeTheme(bool enabled) async {
    if (_savingTheme || _signingOut) return;

    setState(() {
      _savingTheme = true;
    });

    try {
      await ref.read(themeModeProvider.notifier).setDarkMode(enabled);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ المظهر، حاول مجددًا.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingTheme = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_signingOut || _savingTheme) return;

    // تعطيل الزر أثناء التأكيد والتنفيذ لمنع تكرار العملية.
    setState(() {
      _signingOut = true;
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تسجيل الخروج'),
              content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
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
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          );
        },
      );

      if (confirmed != true || !mounted) return;

      await AuthService().signOut();

      // ينتقل التطبيق إلى تسجيل الدخول عبر الراوتر الحالي.
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تسجيل الخروج. تحقق من الاتصال وحاول مجددًا.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _signingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final themeState = ref.watch(themeModeProvider);
    final isDark = theme.brightness == Brightness.dark;

    final isBusy = _savingTheme || _signingOut;

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'إغلاق القائمة',
                  onPressed: () {
                    Scaffold.of(context).closeEndDrawer();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'إعدادات التطبيق',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: colors.primary,
              ),
              title: const Text('الوضع الداكن'),
              subtitle: Text(
                isDark ? 'المظهر الداكن مفعّل' : 'المظهر الفاتح مفعّل',
              ),
              value: isDark,
              onChanged: isBusy || themeState.isLoading ? null : _changeTheme,
            ),
            const Divider(),
                        if (widget.showJoinTechnician) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !isBusy,
                leading: Icon(
                  Icons.engineering_outlined,
                  color: colors.primary,
                ),
                title: const Text('الانضمام كفني'),
                subtitle: const Text('إنشاء ملف لتقديم خدمات الصيانة'),
                trailing: const Icon(
                  Icons.chevron_left_rounded,
                ),
                onTap: isBusy
                    ? null
                    : () {
                        final router = GoRouter.of(context);

                        Scaffold.of(context).closeEndDrawer();

                        router.push('/technician/join');
                      },
              ),
              const Divider(),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: !isBusy,
              leading: _signingOut
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.logout_rounded, color: colors.error),
              title: Text(
                _signingOut ? 'جارٍ تسجيل الخروج...' : 'تسجيل الخروج',
                style: TextStyle(color: colors.error),
              ),
              onTap: isBusy ? null : _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
