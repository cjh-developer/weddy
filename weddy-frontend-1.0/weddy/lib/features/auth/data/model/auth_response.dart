/// 서버 /auth/signup, /auth/login, /auth/refresh 공통 응답 DTO.
///
/// ApiResponse<AuthResponse> 의 data 필드로 전달된다.
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userOid;
  final String userId;
  final String name;
  final String role;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userOid,
    required this.userId,
    required this.name,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userOid: json['userOid'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  @override
  String toString() {
    return 'AuthResponse('
        'userOid: $userOid, '
        'userId: $userId, '
        'name: $name, '
        'role: $role'
        ')';
  }
}
