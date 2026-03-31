import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/core/storage/token_storage.dart';
import 'package:weddy/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:weddy/features/auth/data/model/sign_up_request.dart';
import 'package:weddy/features/auth/data/repository/auth_repository_impl.dart';
import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/domain/repository/auth_repository.dart';
import 'package:weddy/features/couple/presentation/notifier/couple_notifier.dart';
import 'package:weddy/features/guest/presentation/notifier/guest_group_notifier.dart';
import 'package:weddy/features/guest/presentation/notifier/guest_notifier.dart';
import 'package:weddy/features/roadmap/presentation/notifier/custom_roadmap_notifier.dart';
import 'package:weddy/features/vendor/presentation/notifier/vendor_notifier.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// [AuthRepository] Provider.
///
/// 테스트 환경에서는 ProviderScope의 overrides를 통해 MockAuthRepository로 교체한다:
/// ```dart
/// ProviderScope(
///   overrides: [
///     authRepositoryProvider.overrideWithValue(MockAuthRepository()),
///   ],
///   child: MyApp(),
/// )
/// ```
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepositoryImpl(
    dataSource: AuthRemoteDataSource(dio),
    tokenStorage: tokenStorage,
  );
});

/// [AuthNotifier] StateNotifierProvider.
///
/// 앱 전역 인증 상태를 관리한다. 초기 상태는 [AuthInitial].
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(
    repository: repository,
    tokenStorage: tokenStorage,
    ref: ref,
  );
});

/// 401 Unauthorized 발생 시 AuthNotifier.logout()을 호출하는 콜백을 반환하는 Provider.
///
/// [unauthorizedCallbackProvider]의 실제 구현을 제공하여 401 수신 시
/// AuthNotifier 상태 전환(→ AuthUnauthenticated)과 go_router redirect가
/// 연쇄적으로 트리거되도록 한다.
///
/// main.dart의 ProviderScope에서 [unauthorizedCallbackProvider]를 이 Provider로
/// override한다:
/// ```dart
/// ProviderScope(
///   overrides: [
///     unauthorizedCallbackProvider.overrideWith(
///       (ref) => authLogoutCallbackProvider(ref),
///     ),
///   ],
/// )
/// ```
Future<void> Function() authLogoutCallbackProvider(Ref ref) {
  return () async {
    await ref.read(authNotifierProvider.notifier).logout();
  };
}

// ---------------------------------------------------------------------------
// AuthNotifier
// ---------------------------------------------------------------------------

/// 인증 흐름(로그인, 회원가입, 로그아웃, 상태 복원)을 관리하는 StateNotifier.
///
/// 모든 비동기 작업 전에 [AuthLoading]으로 전환하고,
/// 결과에 따라 [AuthAuthenticated] 또는 [AuthError]로 전환한다.
/// 에러 상태에서 사용자가 다시 시도할 수 있도록 상태를 [AuthUnauthenticated]로
/// 리셋하는 별도 처리는 UI 레이어에서 담당한다.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final Ref _ref;

  AuthNotifier({
    required AuthRepository repository,
    required TokenStorage tokenStorage,
    required Ref ref,
  })  : _repository = repository,
        _tokenStorage = tokenStorage,
        _ref = ref,
        super(const AuthInitial());

  /// 앱 시작 시 저장된 토큰을 확인하여 인증 상태를 복원한다.
  ///
  /// - 토큰 있음 → /users/me API 호출 → [AuthAuthenticated]
  /// - 토큰 없음 또는 API 실패 → [AuthUnauthenticated]
  ///
  /// [AuthInitial] 또는 이미 [AuthLoading] 중이면 중복 호출을 무시한다.
  Future<void> checkAuthStatus() async {
    if (state is AuthLoading) return;

    state = const AuthLoading();

    try {
      final accessToken = await _tokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        developer.log(
          '[AuthNotifier] No stored token → unauthenticated',
          name: 'AuthNotifier',
        );
        state = const AuthUnauthenticated();
        return;
      }

      final user = await _repository.getMyInfo();
      developer.log(
        '[AuthNotifier] Token valid, user restored: ${user.userId}',
        name: 'AuthNotifier',
      );
      state = AuthAuthenticated(user);
    } on ApiException catch (e) {
      developer.log(
        '[AuthNotifier] checkAuthStatus failed: ${e.message}',
        name: 'AuthNotifier',
      );
      // 토큰이 있지만 유효하지 않은 경우(만료, 위변조 등) 미인증으로 전환.
      state = const AuthUnauthenticated();
    } catch (e) {
      developer.log(
        '[AuthNotifier] checkAuthStatus unexpected error: $e',
        name: 'AuthNotifier',
        error: e,
      );
      state = const AuthUnauthenticated();
    }
  }

  /// 로그인을 수행하고 성공 시 사용자 정보를 포함한 [AuthAuthenticated]로 전환한다.
  ///
  /// 로그인 성공 후 /users/me를 추가 호출하여 완전한 사용자 정보를 확보한다.
  /// 이는 AuthResponse에 포함되지 않는 handPhone, email, inviteCode 등을 얻기 위함이다.
  Future<void> login(String userId, String password) async {
    state = const AuthLoading();

    try {
      // login은 토큰 저장까지 Repository에서 처리된다.
      await _repository.login(userId, password);

      // 전체 사용자 정보 조회 (저장된 토큰으로 인증됨)
      final user = await _repository.getMyInfo();
      developer.log(
        '[AuthNotifier] login success: ${user.userId}',
        name: 'AuthNotifier',
      );
      state = AuthAuthenticated(user);
    } on ApiException catch (e) {
      developer.log(
        '[AuthNotifier] login failed: ${e.message}',
        name: 'AuthNotifier',
      );
      state = AuthError(e.message);
    } catch (e) {
      developer.log(
        '[AuthNotifier] login unexpected error: $e',
        name: 'AuthNotifier',
        error: e,
      );
      state = const AuthError('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 회원가입을 수행하고 성공 시 [AuthUnauthenticated]로 전환한다.
  ///
  /// 회원가입 후 자동 로그인하지 않고 로그인 화면으로 이동시킨다.
  /// 서버가 발급한 토큰은 즉시 삭제하여 미인증 상태를 유지한다.
  Future<void> signup(SignUpRequest request) async {
    state = const AuthLoading();

    try {
      await _repository.signup(request);
      // 회원가입 성공 — 토큰을 즉시 삭제하여 자동 로그인을 방지한다.
      await _tokenStorage.clearTokens();
      developer.log('[AuthNotifier] signup success → unauthenticated', name: 'AuthNotifier');
      state = const AuthUnauthenticated();
    } on ApiException catch (e) {
      developer.log(
        '[AuthNotifier] signup failed: ${e.message}',
        name: 'AuthNotifier',
      );
      state = AuthError(e.message);
    } catch (e) {
      developer.log(
        '[AuthNotifier] signup unexpected error: $e',
        name: 'AuthNotifier',
        error: e,
      );
      state = const AuthError('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 로그아웃 처리: 토큰 삭제 후 [AuthUnauthenticated]로 전환한다.
  ///
  /// 서버 로그아웃 API가 없으므로 로컬 토큰 삭제로 처리한다.
  /// 토큰 삭제 실패는 치명적이지 않으므로 에러 상태로 전환하지 않는다.
  Future<void> logout() async {
    try {
      await _repository.logout();
      developer.log('[AuthNotifier] logout success', name: 'AuthNotifier');
    } catch (e) {
      // 토큰 삭제 실패 시에도 UI에서는 로그아웃 처리를 진행한다.
      developer.log(
        '[AuthNotifier] logout error (non-fatal): $e',
        name: 'AuthNotifier',
        error: e,
      );
    } finally {
      // 커플 상태를 초기화하여 다음 사용자 로그인 시 stale 데이터가 노출되지 않도록 한다.
      _ref.read(coupleNotifierProvider.notifier).reset();
      // 직접 로드맵 상태를 초기화하여 다음 사용자 로그인 시 이전 사용자의 데이터가 노출되지 않도록 한다.
      _ref.read(customRoadmapNotifierProvider.notifier).reset();
      // 업체/즐겨찾기 상태를 초기화하여 다음 사용자 로그인 시 이전 사용자의 즐겨찾기가 노출되지 않도록 한다.
      _ref.read(vendorNotifierProvider.notifier).reset();
      // 하객 관련 상태를 초기화하여 다음 사용자 로그인 시 이전 사용자의 하객 데이터가 노출되지 않도록 한다.
      _ref.read(guestGroupNotifierProvider.notifier).reset();
      _ref.read(guestNotifierProvider.notifier).reset();
      state = const AuthUnauthenticated();
    }
  }

  /// [AuthError] 상태를 [AuthUnauthenticated]로 리셋한다.
  ///
  /// 에러 화면에서 "다시 시도" 버튼 등을 눌렀을 때 호출한다.
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  /// 서버에서 사용자 정보를 다시 불러와 [AuthAuthenticated] 상태를 갱신한다.
  ///
  /// 결혼 예정일 설정, 프로필 수정 등 사용자 정보 변경 후 호출하여
  /// [UserModel]의 최신 데이터를 반영한다.
  /// 갱신 실패 시 기존 상태를 유지하여 사용자 경험을 보호한다.
  Future<void> refreshUser() async {
    try {
      final user = await _repository.getMyInfo();
      state = AuthAuthenticated(user);
      developer.log('[AuthNotifier] refreshUser success: ${user.userId}', name: 'AuthNotifier');
    } catch (e) {
      developer.log('[AuthNotifier] refreshUser failed (non-fatal): $e', name: 'AuthNotifier');
    }
  }
}
