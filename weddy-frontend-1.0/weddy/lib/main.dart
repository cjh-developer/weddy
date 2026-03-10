import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/core/router/app_router.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';

void main() {
  // flutter_secure_storage 등 네이티브 플러그인이 runApp 이전에 초기화된
  // Flutter 엔진 바인딩을 필요로 하므로 반드시 먼저 호출해야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope는 앱의 최상단에서 모든 Riverpod Provider를 감싸야 한다.
    //
    // unauthorizedCallbackProvider를 override하여 401 Unauthorized 수신 시
    // AuthNotifier.logout()이 호출되도록 연결한다.
    // 이를 통해 go_router의 refreshListenable이 트리거되고 로그인 화면으로 전환된다.
    ProviderScope(
      overrides: [
        unauthorizedCallbackProvider.overrideWith(authLogoutCallbackProvider),
      ],
      child: const WeddyApp(),
    ),
  );
}

/// 앱 루트 위젯.
///
/// [ConsumerStatefulWidget]을 사용하는 이유:
/// initState에서 checkAuthStatus()를 단 한 번 호출하기 위함이다.
/// ConsumerWidget(build 전용)으로는 initState 훅을 사용할 수 없다.
class WeddyApp extends ConsumerStatefulWidget {
  const WeddyApp({super.key});

  @override
  ConsumerState<WeddyApp> createState() => _WeddyAppState();
}

class _WeddyAppState extends ConsumerState<WeddyApp> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 저장된 토큰을 확인하여 인증 상태를 복원한다.
    // addPostFrameCallback을 사용하여 위젯 트리가 완전히 빌드된 후 호출한다.
    // initState에서 직접 ref.read를 호출하면 일부 환경에서 Provider 초기화
    // 타이밍 이슈가 발생할 수 있으므로 이 패턴을 사용한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Weddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8A0BF), // 웨딩 핑크 톤
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // 입력 필드 기본 테마: 모든 화면에서 일관된 스타일
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
      ),
      routerConfig: router,
    );
  }
}
