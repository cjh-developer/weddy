import 'package:weddy/features/auth/data/model/user_model.dart';

/// 앱 전체 인증 상태를 표현하는 sealed class.
///
/// Dart 3.0+ sealed class 를 사용하여 exhaustive switch 를 컴파일 타임에 강제한다.
/// 모든 상태는 불변(immutable)이며 const 생성자를 가진다.
sealed class AuthState {
  const AuthState();
}

/// 앱 시작 직후 인증 상태 확인 전의 초기 상태.
/// checkAuthStatus() 호출 전까지 유지된다.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// 로그인/회원가입/인증 확인 중인 로딩 상태.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// 인증 완료 상태. 로그인된 사용자 정보를 포함한다.
final class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  String toString() => 'AuthAuthenticated(user: $user)';
}

/// 미인증 상태. 로그인/회원가입 화면으로 안내해야 한다.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// 인증 처리 중 오류가 발생한 상태.
/// 사용자에게 표시할 메시지를 포함한다.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  String toString() => 'AuthError(message: $message)';
}
