import 'package:weddy/features/auth/data/model/auth_response.dart';
import 'package:weddy/features/auth/data/model/sign_up_request.dart';
import 'package:weddy/features/auth/data/model/user_model.dart';

/// 인증 도메인 Repository 인터페이스.
///
/// 구체적인 데이터 출처(원격 API, 로컬 캐시 등)에 의존하지 않고
/// 도메인 로직과 Presentation 레이어가 이 추상에만 의존하도록 한다.
/// 테스트 시 MockAuthRepository로 교체할 수 있다.
abstract interface class AuthRepository {
  /// 회원가입 후 발급된 토큰 및 사용자 정보를 반환한다.
  Future<AuthResponse> signup(SignUpRequest request);

  /// 로그인 후 발급된 토큰 및 사용자 정보를 반환한다.
  Future<AuthResponse> login(String userId, String password);

  /// 저장된 토큰을 삭제하여 세션을 종료한다.
  Future<void> logout();

  /// 리프레시 토큰으로 새 액세스 토큰을 발급받는다.
  Future<AuthResponse> refreshToken(String token);

  /// 현재 로그인된 사용자 정보를 반환한다.
  Future<UserModel> getMyInfo();
}
