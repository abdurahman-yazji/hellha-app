import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../technician/presentation/providers/technician_profile_provider.dart';

class UserNavigationShell extends ConsumerWidget {
  const UserNavigationShell({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  static const _userLocations = [
    '/',
    '/maintenance-requests',
    '/diagnosis/history',
    '/technicians',
  ];

  static const _technicianLocations = [
    '/',
    '/technician/maintenance-requests',
    '/notifications',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.asData?.value;
    final colors = Theme.of(context).colorScheme;

    final isTechnician = profile?.role == 'technician';
    final locations =
        isTechnician ? _technicianLocations : _userLocations;

    final currentIndex = locations.indexOf(location);
    final selectedIndex = currentIndex < 0 ? 0 : currentIndex;

    final showNavigation =
        !profileState.isLoading &&
        !profileState.hasError &&
        profile != null &&
        profile.isActive &&
        (profile.role == 'user' || isTechnician) &&
        currentIndex >= 0;

    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: Icon(
          Icons.home_rounded,
          color: colors.primary,
        ),
        label: 'الرئيسية',
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(
          Icons.receipt_long_rounded,
          color: colors.primary,
        ),
        label: isTechnician ? 'طلبات الصيانة' : 'طلباتي',
      ),
      if (isTechnician)
        NavigationDestination(
          icon: const Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(
            Icons.notifications_rounded,
            color: colors.primary,
          ),
          label: 'الإشعارات',
        )
      else ...[
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: Icon(
            Icons.history_rounded,
            color: colors.primary,
          ),
          label: 'سجل التشخيصات',
        ),
        NavigationDestination(
          icon: const Icon(Icons.handyman_outlined),
          selectedIcon: Icon(
            Icons.handyman_rounded,
            color: colors.primary,
          ),
          label: 'الفنيون',
        ),
      ],
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: child,
        bottomNavigationBar: showNavigation
            ? DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    if (index == selectedIndex) return;

                    // تحديث الإحصائيات عند العودة لرئيسية الفني.
                    if (isTechnician && index == 0) {
                      ref.invalidate(technicianProfileProvider);
                    }

                    context.go(locations[index]);
                  },
                  backgroundColor: Color.alphaBlend(
  colors.primary.withValues(alpha: 0.06),
  colors.surface,
),
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: colors.primary.withValues(alpha: 0.16),
                  elevation: 0,
                  height: 76,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: destinations,
                ),
              )
            : null,
      ),
    );
  }
}