import 'package:dio/dio.dart';

/// API 통신 중 발생하는 에러를 표현하는 예외 클래스.
///
/// [DioException]을 앱 도메인 예외로 변환하여, 호출부에서
/// HTTP 레이어 상세를 알 필요 없이 에러를 처리할 수 있게 한다.
class ApiException implements Exception {
  /// 서버가 내려준 비즈니스 에러 코드 (예: "USER_NOT_FOUND").
  /// 서버 에러가 아닌 경우 [ErrorCode] 상수로 정의된 값을 사용한다.
  final String errorCode;

  /// 사용자에게 표시하거나 로그에 기록할 메시지.
  final String message;

  /// 원본 HTTP 상태 코드. 서버 응답이 없는 경우 null.
  final int? statusCode;

  const ApiException({
    required this.errorCode,
    required this.message,
    this.statusCode,
  });

  /// [DioException]으로부터 [ApiException]을 생성하는 팩토리 메서드.
  ///
  /// 우선순위:
  /// 1. 서버 응답 body의 errorCode / message 사용
  /// 2. HTTP 상태 코드에 따른 기본 메시지
  /// 3. DioException 타입에 따른 연결 에러 메시지
  factory ApiException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    // 서버가 ApiResponse 형식으로 에러를 내려준 경우 우선 사용
    if (e.response?.data is Map<String, dynamic>) {
      final body = e.response!.data as Map<String, dynamic>;
      final serverErrorCode = body['errorCode'] as String?;
      final serverMessage = body['message'] as String?;

      if (serverErrorCode != null || serverMessage != null) {
        return ApiException(
          errorCode: serverErrorCode ?? ErrorCode.unknown,
          message: serverMessage ?? '알 수 없는 오류가 발생했습니다.',
          statusCode: statusCode,
        );
      }
    }

    // HTTP 상태 코드 기반 에러 분류
    if (statusCode != null) {
      return _fromStatusCode(statusCode, e);
    }

    // 연결 에러 등 네트워크 레벨 에러
    return _fromDioType(e);
  }

  // ignore: unused_element
  // [e]는 향후 서버 응답 body 추가 파싱이 필요할 때를 대비해 유지한다.
  // 현재는 statusCode 기반 분류만 사용하므로 직접 참조하지 않는다.
  static ApiException _fromStatusCode(int statusCode, DioException e) {
    switch (statusCode) {
      case 400:
        return const ApiException(
          errorCode: ErrorCode.badRequest,
          message: '잘못된 요청입니다.',
          statusCode: 400,
        );
      case 401:
        return const ApiException(
          errorCode: ErrorCode.unauthorized,
          message: '인증이 필요합니다. 다시 로그인해주세요.',
          statusCode: 401,
        );
      case 403:
        return const ApiException(
          errorCode: ErrorCode.forbidden,
          message: '접근 권한이 없습니다.',
          statusCode: 403,
        );
      case 404:
        return const ApiException(
          errorCode: ErrorCode.notFound,
          message: '요청한 리소스를 찾을 수 없습니다.',
          statusCode: 404,
        );
      case 409:
        return const ApiException(
          errorCode: ErrorCode.conflict,
          message: '이미 존재하는 데이터입니다.',
          statusCode: 409,
        );
      case 422:
        return const ApiException(
          errorCode: ErrorCode.unprocessableEntity,
          message: '입력값이 올바르지 않습니다.',
          statusCode: 422,
        );
      case 500:
        return const ApiException(
          errorCode: ErrorCode.internalServerError,
          message: '서버 내부 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          statusCode: 500,
        );
      default:
        return ApiException(
          errorCode: ErrorCode.unknown,
          message: '오류가 발생했습니다. (HTTP $statusCode)',
          statusCode: statusCode,
        );
    }
  }

  static ApiException _fromDioType(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          errorCode: ErrorCode.timeout,
          message: '요청 시간이 초과되었습니다. 네트워크 상태를 확인해주세요.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          errorCode: ErrorCode.networkError,
          message: '네트워크에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          errorCode: ErrorCode.requestCancelled,
          message: '요청이 취소되었습니다.',
        );
      default:
        return ApiException(
          errorCode: ErrorCode.unknown,
          message: '알 수 없는 오류가 발생했습니다: ${e.message}',
        );
    }
  }

  @override
  String toString() {
    return 'ApiException('
        'errorCode: $errorCode, '
        'message: $message, '
        'statusCode: $statusCode'
        ')';
  }
}

/// 서버 및 클라이언트 에러 코드 상수 모음.
///
/// 서버에서 내려오는 errorCode 문자열과 동일한 값으로 유지해야 한다.
abstract final class ErrorCode {
  // HTTP 표준 에러
  static const String badRequest = 'BAD_REQUEST';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String conflict = 'CONFLICT';
  static const String unprocessableEntity = 'UNPROCESSABLE_ENTITY';
  static const String internalServerError = 'INTERNAL_SERVER_ERROR';

  // 네트워크 / 클라이언트 에러
  static const String timeout = 'TIMEOUT';
  static const String networkError = 'NETWORK_ERROR';
  static const String requestCancelled = 'REQUEST_CANCELLED';
  static const String unknown = 'UNKNOWN';

  // 비즈니스 도메인 에러 (서버와 동일한 코드 사용)
  static const String userNotFound = 'USER_NOT_FOUND';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String invalidToken = 'INVALID_TOKEN';
  static const String duplicateEmail = 'DUPLICATE_EMAIL';
}
