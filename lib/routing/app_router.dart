import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';

import '../features/diagnosis/domain/models/diagnosis_result.dart';
import '../features/diagnosis/presentation/pages/diagnosis_history_page.dart';
import '../features/diagnosis/presentation/pages/diagnosis_page.dart';
import '../features/diagnosis/presentation/pages/diagnosis_result_page.dart';

import '../features/home/presentation/pages/home_page.dart';
import '../features/home/presentation/pages/user_navigation_shell.dart';
import '../features/technician/presentation/pages/technician_profile_page.dart';
import '../features/maintenance_requests/presentation/pages/create_maintenance_request_page.dart';
import '../features/maintenance_requests/presentation/pages/my_maintenance_requests_page.dart';
import '../features/maintenance_requests/presentation/pages/technician_maintenance_requests_page.dart';
import '../features/technician/presentation/pages/technician_specializations_page.dart';
import '../features/notifications/presentation/pages/notification_request_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';

import '../features/technician/presentation/pages/available_technicians_page.dart';
import '../features/technician/presentation/pages/edit_technician_profile_page.dart';
import '../features/technician/presentation/pages/edit_technician_specializations_page.dart';
import '../features/technician/presentation/pages/join_technician_page.dart';
import '../features/technician/presentation/pages/technician_certificates_page.dart';

import 'auth_state_notifier.dart';

final AuthStateNotifier authStateNotifier = AuthStateNotifier();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: authStateNotifier,
  redirect: (BuildContext context, GoRouterState state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;

    final isAuthPage =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/forgot-password';

    if (!isLoggedIn && !isAuthPage) {
      return '/login';
    }

    if (isLoggedIn && isAuthPage) {
      final isCompletingRegistration =
          state.matchedLocation == '/register' &&
          authStateNotifier.registrationInProgress;

      if (!isCompletingRegistration) {
        return '/';
      }
    }

    return null;
  },
  routes: [
    // الأقسام التي تشترك في شريط التنقل السفلي.
    ShellRoute(
      builder: (context, state, child) {
        return UserNavigationShell(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              child: const HomePage(),
            );
          },
        ),
        GoRoute(
          path: '/maintenance-requests',
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              child: const MyMaintenanceRequestsPage(),
            );
          },
        ),
        GoRoute(
          path: '/diagnosis/history',
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              child: const DiagnosisHistoryPage(),
            );
          },
        ),
        GoRoute(
          path: '/technicians',
          pageBuilder: (context, state) {
            return NoTransitionPage<void>(
              key: state.pageKey,
              child: const AvailableTechniciansPage(),
            );
          },
        ),
        GoRoute(
  path: '/technician/maintenance-requests',
  pageBuilder: (context, state) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: const TechnicianMaintenanceRequestsPage(),
    );
  },
),
GoRoute(
  path: '/notifications',
  pageBuilder: (context, state) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: const NotificationsPage(),
    );
  },
),
      ],
    ),

    GoRoute(
      path: '/technician/join',
      builder: (context, state) => const JoinTechnicianPage(),
    ),
    GoRoute(
      path: '/diagnosis',
      builder: (context, state) => const DiagnosisPage(),
    ),
    GoRoute(
      path: '/diagnosis/result',
      redirect: (context, state) {
        if (state.extra is! DiagnosisResult) {
          return '/diagnosis';
        }

        return null;
      },
      builder: (context, state) {
        final result = state.extra! as DiagnosisResult;

        return DiagnosisResultPage(result: result);
      },
    ),

    
    GoRoute(
      path: '/notifications/:notificationId/request/:requestId',
      redirect: (context, state) {
        final notificationId = state.pathParameters['notificationId'];
        final requestId = state.pathParameters['requestId'];
        final recipientId = state.uri.queryParameters['recipient'];

        final validId = RegExp(r'^[1-9]\d{0,18}$');

        if (notificationId == null ||
            requestId == null ||
            recipientId == null ||
            !validId.hasMatch(notificationId) ||
            !validId.hasMatch(requestId) ||
            !validId.hasMatch(recipientId)) {
          return '/notifications';
        }

        return null;
      },
      builder: (context, state) {
        return NotificationRequestPage(
          key: ValueKey(state.uri.toString()),
          requestId: state.pathParameters['requestId']!,
          notificationId: state.pathParameters['notificationId']!,
          recipientUserId: state.uri.queryParameters['recipient']!,
        );
      },
    ),

    GoRoute(
      path: '/maintenance-requests/create',
      redirect: (context, state) {
        final diagnosis = state.extra;

        if (diagnosis is! DiagnosisResult || diagnosis.id == null) {
          return '/diagnosis';
        }

        return null;
      },
      builder: (context, state) {
        final diagnosis = state.extra! as DiagnosisResult;

        return CreateMaintenanceRequestPage(diagnosis: diagnosis);
      },
    ),

    GoRoute(
  path: '/technician/specializations',
  builder: (context, state) => const TechnicianSpecializationsPage(),
),
GoRoute(
  path: '/technician/specializations/edit',
  builder: (context, state) => const EditTechnicianSpecializationsPage(),
),
    GoRoute(
      path: '/technician/certificates',
      builder: (context, state) => const TechnicianCertificatesPage(),
    ),
    GoRoute(
  path: '/technician/profile',
  builder: (context, state) => const TechnicianProfilePage(),
),
    GoRoute(
      path: '/technician/profile/edit',
      builder: (context, state) => const EditTechnicianProfilePage(),
    ),
    

    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
  ],
);
