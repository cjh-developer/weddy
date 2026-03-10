import 'package:dio/dio.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/api_response.dart';
import 'package:weddy/features/auth/data/model/auth_response.dart';
import 'package:weddy/features/auth/data/model/sign_up_request.dart';
import 'package:weddy/features/auth/data/model/user_model.dart';

/// 인증 관련 원격 API 호출을 담당하는 데이터소스.
///
/// HTTP 레이어와 앱 도메인 레이어 사이에 위치하며,
/// - DioException 을 ApiException 으로 변환
/// - ApiResponse 래퍼를 벗겨내어 실제 DTO를 반환
/// 하는 책임을 가진다.
///
/// Repository 이상에서는 HTTP 세부 사항을 알 필요가 없다.
class AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSource(this._dio);

  /// POST /auth/signup
  Future<AuthResponse> signup(SignUpRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/signup',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        throw ApiException(
          errorCode: apiResponse.errorCode ?? 'UNKNOWN',
          message: apiResponse.message,
        );
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      // _ErrorInterceptor가 DioException.error에 ApiException을 담아두므로 먼저 확인.
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /auth/login
  Future<AuthResponse> login(String userId, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'userId': userId,
          'password': password,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        throw ApiException(
          errorCode: apiResponse.errorCode ?? 'UNKNOWN',
          message: apiResponse.message,
        );
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /auth/refresh
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        throw ApiException(
          errorCode: apiResponse.errorCode ?? 'UNKNOWN',
          message: apiResponse.message,
        );
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /users/me - Authorization 헤더는 _AuthInterceptor가 자동 주입한다.
  Future<UserModel> getMyInfo() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');

      final apiResponse = ApiResponse.fromJson(
        response.data!,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.isSuccess || apiResponse.data == null) {
        throw ApiException(
          errorCode: apiResponse.errorCode ?? 'UNKNOWN',
          message: apiResponse.message,
        );
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException.fromDioException(e);
    }
  }
}
