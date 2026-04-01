import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/core/router/app_router.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';

Future<void> main() async {
  // flutter_secure_storage 등 네이티브 플러그인이 runApp 이전에 초기화된
  // Flutter 엔진 바인딩을 필요로 하므로 반드시 먼저 호출해야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  // FLAVOR에 따라 환경 파일을 선택하여 dotenv를 로드한다.
  // 빌드 시: flutter run --dart-define=FLAVOR=production
  // 기본값은 dev (.env 파일 사용).
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  const envFile = flavor == 'production' ? '.env.production' : '.env';
  await dotenv.load(fileName: envFile);

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
      title: 'Weddly',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          // 핑크 테마로 전환 — login_screen.dart / home_screen.dart 와 통일
          seedColor: const Color(0xFFEC4899),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A19),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFFFDF2F8),
          foregroundColor: Color(0xFFDB2777),
          titleTextStyle: TextStyle(
            color: Color(0xFFDB2777),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEC4899),
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFFCE7F3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFFCE7F3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFEC4899), width: 2),
          ),
          prefixIconColor: Color(0xFFEC4899),
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xFFFCE7F3)),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
