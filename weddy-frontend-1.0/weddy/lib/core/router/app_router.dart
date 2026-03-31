import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';
import 'package:weddy/features/auth/presentation/screen/login_screen.dart';
import 'package:weddy/features/auth/presentation/screen/sign_up_screen.dart';
import 'package:weddy/features/budget/presentation/screen/budget_screen.dart';
import 'package:weddy/features/checklist/presentation/screen/checklist_screen.dart';
import 'package:weddy/features/home/presentation/screen/home_screen.dart';
import 'package:weddy/features/roadmap/presentation/screen/roadmap_screen.dart';
import 'package:weddy/features/schedule/presentation/screen/schedule_screen.dart';
import 'package:weddy/features/guest/presentation/screen/guest_form_screen.dart';
import 'package:weddy/features/guest/presentation/screen/guest_screen.dart';
import 'package:weddy/features/vendor/presentation/screen/vendor_detail_screen.dart';
import 'package:weddy/features/vendor/presentation/screen/vendor_screen.dart';
import 'package:weddy/features/wedding_setup/presentation/screen/wedding_date_setup_screen.dart';

// ---------------------------------------------------------------------------
// Route 경로 상수
// ---------------------------------------------------------------------------

abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String weddingDateSetup = '/setup/wedding-date';
  static const String checklist = '/checklist';
  static const String budget = '/budget';
  static const String schedule = '/schedule';
  static const String roadmap = '/roadmap';
  static const String vendor = '/vendor';
  static const String vendorDetail = '/vendor/:oid';
  static const String guest = '/guest';
  static const String guestForm = '/guest/form';
}

// ---------------------------------------------------------------------------
// 결혼 예정일 설정 건너뛰기 플래그
// ---------------------------------------------------------------------------

/// 사용자가 "나중에 설정하기"를 선택했을 때 true로 설정된다.
/// 앱 재시작 시 초기화(로그인할 때마다 다시 설정 유도).
final weddingSetupSkippedProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Router Provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authStateListenable = _AuthStateListenable(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authStateListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      final isOnAuthPage =
          location == AppRoutes.login || location == AppRoutes.signUp;

      if (authState is AuthUnauthenticated || authState is AuthError) {
        return isOnAuthPage ? null : AppRoutes.login;
      }

      if (authState is AuthAuthenticated) {
        if (isOnAuthPage) return AppRoutes.home;

        // 결혼 예정일 미설정 + 설정 화면이 아닌 경우 → 설정 화면으로
        final isOnSetupPage = location == AppRoutes.weddingDateSetup;
        final skipped = ref.read(weddingSetupSkippedProvider);

        if (authState.user.weddingDate == null && !isOnSetupPage && !skipped) {
          return AppRoutes.weddingDateSetup;
        }

        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.weddingDateSetup,
        builder: (context, state) => const WeddingDateSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.checklist,
        builder: (context, state) {
          final targetOid = state.uri.queryParameters['target'];
          return ChecklistScreen(targetOid: targetOid);
        },
      ),
      GoRoute(
        path: AppRoutes.budget,
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        path: AppRoutes.schedule,
        builder: (context, state) => const ScheduleScreen(),
      ),
      GoRoute(
        path: AppRoutes.roadmap,
        builder: (context, state) => const RoadmapScreen(showBackButton: true),
      ),
      GoRoute(
        path: AppRoutes.vendor,
        builder: (context, state) => const VendorScreen(),
      ),
      GoRoute(
        path: AppRoutes.vendorDetail,
        builder: (context, state) => VendorDetailScreen(
          vendorOid: state.pathParameters['oid']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.guest,
        builder: (context, state) => const GuestScreen(),
      ),
      GoRoute(
        path: AppRoutes.guestForm,
        builder: (context, state) => GuestFormScreen(
          guestOid: state.uri.queryParameters['oid'],
        ),
      ),
    ],
    errorBuilder: (context, state) => const HomeScreen(),
  );

  ref.onDispose(() {
    authStateListenable.dispose();
    router.dispose();
  });

  return router;
});

// ---------------------------------------------------------------------------
// GoRouter refreshListenable 어댑터
// ---------------------------------------------------------------------------

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen<AuthState>(
      authNotifierProvider,
      (previous, next) {
        notifyListeners();
      },
    );
  }
}
