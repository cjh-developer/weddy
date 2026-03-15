import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Dio HTTP 클라이언트 팩토리 및 설정.
///
/// 인터셉터 구성:
/// - [_AuthInterceptor]    : 요청 헤더에 Bearer 토큰 자동 주입
/// - [_ResponseInterceptor]: 응답 success=false 케이스 로깅
/// - [_ErrorInterceptor]  : 401 처리 및 DioException → ApiException 변환
class DioClient {
  DioClient._();

  // dotenv 로부터 API_BASE_URL 을 읽는다.
  // main()에서 dotenv.load() 가 먼저 실행되어야 한다.
  // fallback 값은 Android 에뮬레이터 → 호스트 머신 8080 포트.
  // iOS 시뮬레이터는 .env의 API_BASE_URL 을 'http://localhost:8080/api/v1' 로 변경하여 사용한다.
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api/v1';

  static int get _connectTimeoutSec =>
      int.tryParse(dotenv.env['CONNECT_TIMEOUT_SEC'] ?? '30') ?? 30;

  static int get _receiveTimeoutSec =>
      int.tryParse(dotenv.env['RECEIVE_TIMEOUT_SEC'] ?? '30') ?? 30;

  static int get _sendTimeoutSec =>
      int.tryParse(dotenv.env['SEND_TIMEOUT_SEC'] ?? '30') ?? 30;

  /// [onUnauthorized]: 401 응답 시 호출되는 콜백.
  /// AuthNotifier.logout()을 주입하여 상태 전환 및 go_router redirect를 트리거한다.
  /// null 전달 시 토큰 삭제만 수행한다(테스트 환경 등).
  static Dio create(
    TokenStorage tokenStorage, {
    Future<void> Function()? onUnauthorized,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: Duration(seconds: _connectTimeoutSec),
        receiveTimeout: Duration(seconds: _receiveTimeoutSec),
        // Web에서는 sendTimeout이 request body 없는 요청에 적용 불가 → 경고 방지.
        sendTimeout: kIsWeb ? null : Duration(seconds: _sendTimeoutSec),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      _AuthInterceptor(tokenStorage),
      _ResponseInterceptor(),
      _ErrorInterceptor(tokenStorage, onUnauthorized: onUnauthorized),
    ]);

    return dio;
  }
}

/// 요청 헤더에 JWT Access Token을 자동으로 추가하는 인터셉터.
///
/// 토큰이 없으면 Authorization 헤더를 추가하지 않아,
/// 인증이 필요 없는 공개 엔드포인트도 그대로 호출된다.
class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  _AuthInterceptor(this._tokenStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.getAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
      developer.log(
        '[Auth] Bearer token attached to ${options.method} ${options.path}',
        name: 'DioClient',
      );
    } else {
      developer.log(
        '[Auth] No token for ${options.method} ${options.path}',
        name: 'DioClient',
      );
    }

    handler.next(options);
  }
}

/// 응답을 수신할 때 success=false인 경우 경고 로그를 출력하는 인터셉터.
///
/// HTTP 상태 코드가 2xx이더라도 비즈니스 레이어에서 실패로 처리되는
/// 케이스를 개발 중에 쉽게 파악할 수 있도록 돕는다.
class _ResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final success = data['success'] as bool?;

      if (success == false) {
        final message = data['message'] as String? ?? '';
        final errorCode = data['errorCode'] as String? ?? '';

        developer.log(
          '[Response] Business failure: '
          'status=${response.statusCode}, '
          'errorCode=$errorCode, '
          'message=$message',
          name: 'DioClient',
          level: 900, // WARNING
        );
      }
    }

    handler.next(response);
  }
}

/// HTTP 에러를 처리하는 인터셉터.
///
/// - 401 응답 시: [onUnauthorized] 콜백을 호출하여 상위 레이어에 알린다.
///   상위 레이어(AuthNotifier)는 토큰 삭제 및 상태 전환을 수행하여
///   go_router의 refreshListenable을 트리거하고 로그인 화면으로 전환한다.
/// - 모든 [DioException]을 [ApiException]으로 변환하여 reject한다.
///
/// [주의] handler.reject() 에 새 DioException 을 생성해서 error 필드에
/// ApiException 을 넣는 패턴은 호출부에서 `catch (e)` 시
/// `e is ApiException` 조건이 false 가 되어 에러 처리가 무력화된다.
/// 대신 [ApiException] 을 직접 [handler.reject] 의 error 로 전달하고,
/// 호출부는 `(e as DioException).error` 를 통해 꺼내거나,
/// 또는 Repository 레이어에서 일관된 변환 처리를 수행해야 한다.
///
/// 현재 구현에서는 [DioException.error] 에 [ApiException] 을 담아 전달하며,
/// Repository 계층의 공통 try-catch 에서 반드시 아래와 같이 처리해야 한다:
/// ```dart
/// } on DioException catch (e) {
///   if (e.error is ApiException) throw e.error as ApiException;
///   throw ApiException.fromDioException(e);
/// }
/// ```
class _ErrorInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  /// 401 Unauthorized 응답 수신 시 호출되는 콜백.
  ///
  /// Dio 인터셉터 레이어에서 Riverpod을 직접 참조하면 레이어 역전이 발생한다.
  /// 콜백을 통해 상위 레이어(authNotifierProvider)가 상태 전환을 처리하도록 위임한다.
  /// [dioClientProvider]에서 이 콜백에 AuthNotifier.logout()을 주입한다.
  final Future<void> Function()? onUnauthorized;

  _ErrorInterceptor(this._tokenStorage, {this.onUnauthorized});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    developer.log(
      '[Error] ${err.type.name}: '
      'status=$statusCode, '
      'url=${err.requestOptions.uri}, '
      'message=${err.message}',
      name: 'DioClient',
      error: err,
      level: 1000, // SEVERE
    );

    if (statusCode == 401) {
      developer.log(
        '[Auth] 401 Unauthorized - invoking onUnauthorized callback.',
        name: 'DioClient',
      );
      // onUnauthorized 콜백이 주입된 경우 상위 레이어에 위임한다.
      // 미주입 시(테스트 등)에는 직접 토큰만 삭제한다.
      if (onUnauthorized != null) {
        await onUnauthorized!();
      } else {
        await _tokenStorage.clearTokens();
      }
    }

    // DioException 을 앱 도메인 예외(ApiException)로 변환한다.
    // DioException.error 필드에 ApiException 을 담아 전달하므로,
    // Repository 계층에서 반드시 `(e as DioException).error` 로 꺼내야 한다.
    // 호출부 공통 처리 예시는 클래스 주석 참고.
    final apiException = ApiException.fromDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: apiException,
        type: err.type,
        response: err.response,
        message: apiException.message,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

/// [TokenStorage] 인스턴스 Provider.
/// 다른 Provider들이 토큰 저장소를 주입받기 위해 사용한다.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// 401 Unauthorized 수신 시 실행할 콜백 Provider.
///
/// 기본값은 토큰 삭제만 수행한다.
/// auth_notifier.dart의 [authAwareDioClientProvider]를 사용하면
/// AuthNotifier.logout()이 주입되어 상태 전환까지 처리된다.
///
/// 직접 이 Provider를 override하여 테스트 환경에서 콜백을 교체할 수 있다.
final unauthorizedCallbackProvider =
    Provider<Future<void> Function()>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  // 기본 구현: 토큰만 삭제 (화면 전환 없음).
  // 앱에서는 auth_notifier.dart의 authAwareDioClientProvider를 사용해야 한다.
  return () async => tokenStorage.clearTokens();
});

/// [Dio] 인스턴스 Provider.
///
/// 앱 전역에서 단일 Dio 인스턴스를 사용하여 인터셉터 설정을 공유한다.
/// [unauthorizedCallbackProvider]로 주입된 콜백을 401 처리에 사용한다.
final dioClientProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final onUnauthorized = ref.watch(unauthorizedCallbackProvider);
  return DioClient.create(tokenStorage, onUnauthorized: onUnauthorized);
});
