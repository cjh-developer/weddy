import 'dart:developer' as developer;

import 'package:weddy/core/storage/token_storage.dart';
import 'package:weddy/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:weddy/features/auth/data/model/auth_response.dart';
import 'package:weddy/features/auth/data/model/sign_up_request.dart';
import 'package:weddy/features/auth/data/model/user_model.dart';
import 'package:weddy/features/auth/domain/repository/auth_repository.dart';

/// [AuthRepository] 구현체.
///
/// - 로그인/회원가입 성공 시 [TokenStorage]에 토큰을 즉시 저장한다.
/// - 로그아웃 시 [TokenStorage.clearTokens]를 호출하여 모든 토큰을 삭제한다.
/// - ApiException은 DataSource에서 이미 변환되어 올라오므로 여기서 재변환하지 않는다.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final TokenStorage _tokenStorage;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource dataSource,
    required TokenStorage tokenStorage,
  }) : _dataSource = dataSource,
       _tokenStorage = tokenStorage;

  @override
  Future<AuthResponse> signup(SignUpRequest request) async {
    final authResponse = await _dataSource.signup(request);
    await _saveTokens(authResponse);
    developer.log(
      '[AuthRepository] signup success: userId=${authResponse.userId}',
      name: 'AuthRepository',
    );
    return authResponse;
  }

  @override
  Future<AuthResponse> login(String userId, String password) async {
    final authResponse = await _dataSource.login(userId, password);
    await _saveTokens(authResponse);
    developer.log(
      '[AuthRepository] login success: userId=${authResponse.userId}',
      name: 'AuthRepository',
    );
    return authResponse;
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    developer.log('[AuthRepository] logout: tokens cleared', name: 'AuthRepository');
  }

  @override
  Future<AuthResponse> refreshToken(String token) async {
    final authResponse = await _dataSource.refreshToken(token);
    await _saveTokens(authResponse);
    developer.log('[AuthRepository] token refreshed', name: 'AuthRepository');
    return authResponse;
  }

  @override
  Future<UserModel> getMyInfo() async {
    return _dataSource.getMyInfo();
  }

  /// 로그인/회원가입/토큰 갱신 후 공통 토큰 저장 처리.
  Future<void> _saveTokens(AuthResponse authResponse) async {
    await _tokenStorage.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
  }
}
