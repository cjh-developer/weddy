import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';
import 'package:weddy/features/auth/presentation/screen/login_screen.dart';
import 'package:weddy/features/auth/presentation/screen/sign_up_screen.dart';

// ---------------------------------------------------------------------------
// Route 경로 상수
// ---------------------------------------------------------------------------

/// 경로 문자열을 한 곳에서 관리하여 오타와 하드코딩을 방지한다.
abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String signUp = '/signup';
}

// ---------------------------------------------------------------------------
// Router Provider
// ---------------------------------------------------------------------------

/// go_router 인스턴스 Provider.
///
/// [authNotifierProvider]의 상태 변화를 감지하여 자동으로 redirect를 재평가한다.
/// GoRouter의 refreshListenable에 상태 변화를 알리기 위해
/// [_AuthStateListenable] 어댑터를 사용한다.
///
/// [ref.onDispose]를 통해 Provider가 해제될 때 GoRouter와 _AuthStateListenable을
/// 함께 dispose하여 메모리 누수를 방지한다.
final routerProvider = Provider<GoRouter>((ref) {
  final authStateListenable = _AuthStateListenable(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: authStateListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      // 인증 상태가 확정되지 않은 동안(Initial/Loading)은 리다이렉트하지 않는다.
      // Splash 또는 로딩 인디케이터가 표시되는 동안 화면 전환이 발생하지 않도록 한다.
      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      final isOnAuthPage =
          location == AppRoutes.login || location == AppRoutes.signUp;

      if (authState is AuthUnauthenticated || authState is AuthError) {
        // 미인증 → 로그인/회원가입 페이지가 아니면 로그인으로 보낸다.
        return isOnAuthPage ? null : AppRoutes.login;
      }

      if (authState is AuthAuthenticated) {
        // 인증 완료 → 로그인/회원가입 페이지에 있으면 홈으로 보낸다.
        return isOnAuthPage ? AppRoutes.home : null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
    ],
    // 정의되지 않은 경로로 접근 시 홈으로 리다이렉트
    errorBuilder: (context, state) => const _HomeScreen(),
  );

  // Provider가 dispose될 때 GoRouter와 _AuthStateListenable을 함께 해제한다.
  // GoRouter는 내부적으로 RouteInformationProvider 등 리소스를 보유하므로
  // dispose를 호출하지 않으면 메모리 누수가 발생한다.
  ref.onDispose(() {
    authStateListenable.dispose();
    router.dispose();
  });

  return router;
});

// ---------------------------------------------------------------------------
// GoRouter refreshListenable 어댑터
// ---------------------------------------------------------------------------

/// Riverpod의 [AuthState] 변화를 [Listenable]로 변환하는 어댑터.
///
/// go_router의 refreshListenable은 [Listenable]을 받기 때문에,
/// Riverpod Provider의 상태 변화를 ChangeNotifier를 통해 브리지한다.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    // authNotifierProvider가 변화할 때마다 notifyListeners()를 호출한다.
    // ref.listen은 Provider dispose 시 자동으로 구독이 해제된다.
    ref.listen<AuthState>(
      authNotifierProvider,
      (previous, next) {
        // 동일 상태 타입으로의 전환(예: 에러 메시지만 바뀜)도 리다이렉트
        // 재평가가 필요할 수 있으므로 항상 notify한다.
        notifyListeners();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 임시 홈 화면 (Placeholder)
// ---------------------------------------------------------------------------

/// 향후 홈 피처로 교체될 임시 홈 화면.
///
/// 인증된 사용자만 접근 가능하며, 로그아웃 버튼을 제공한다.
class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState is AuthAuthenticated
        ? authState.user.name
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weddy'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '환영합니다, $userName님!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '홈 화면은 추후 구현될 예정입니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
