/// Spring Boot ApiResponse와 완전히 호환되는 Dart 모델.
///
/// 서버 응답 구조:
/// ```json
/// {
///   "success": true,
///   "message": "요청이 성공적으로 처리되었습니다.",
///   "data": { ... },
///   "errorCode": null
/// }
/// ```
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? errorCode;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
  });

  /// [isSuccess]는 [success] 필드의 별칭 getter.
  /// 호출부에서 `response.isSuccess` 형태로 읽기 좋게 제공.
  bool get isSuccess => success;

  /// 서버 응답 JSON을 [ApiResponse]로 변환한다.
  ///
  /// [fromJsonT]: data 필드를 원하는 타입 [T]로 변환하는 콜백.
  /// data가 null이거나 타입 변환이 필요 없는 경우 null을 반환해도 된다.
  ///
  /// 사용 예:
  /// ```dart
  /// ApiResponse<UserDto>.fromJson(
  ///   json,
  ///   (data) => UserDto.fromJson(data as Map<String, dynamic>),
  /// );
  /// ```
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
      errorCode: json['errorCode'] as String?,
    );
  }

  /// data 필드 없이 단순 성공/실패 응답을 파싱할 때 사용.
  ///
  /// `ApiResponse<void>.fromJsonVoid(json)` 형태로 호출.
  static ApiResponse<void> fromJsonVoid(Map<String, dynamic> json) {
    return ApiResponse<void>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      errorCode: json['errorCode'] as String?,
    );
  }

  /// [data]를 명시적으로 null로 설정하려면 [clearData]를 true로 전달한다.
  ///
  /// `data ?? this.data` 패턴은 `copyWith(data: null)` 호출 시
  /// 기존 data를 유지하므로 의도적 null 설정이 불가능하다.
  /// [clearData] flag를 통해 이를 명확히 구분한다.
  ApiResponse<T> copyWith({
    bool? success,
    String? message,
    T? data,
    bool clearData = false,
    String? errorCode,
  }) {
    return ApiResponse<T>(
      success: success ?? this.success,
      message: message ?? this.message,
      data: clearData ? null : (data ?? this.data),
      errorCode: errorCode ?? this.errorCode,
    );
  }

  @override
  String toString() {
    return 'ApiResponse('
        'success: $success, '
        'message: $message, '
        'data: $data, '
        'errorCode: $errorCode'
        ')';
  }
}
