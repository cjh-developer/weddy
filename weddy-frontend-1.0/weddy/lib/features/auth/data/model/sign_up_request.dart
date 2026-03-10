/// POST /auth/signup 요청 바디 모델.
///
/// role 값은 서버 enum과 동일해야 한다: "GROOM" 또는 "BRIDE".
class SignUpRequest {
  final String userId;
  final String password;
  final String name;
  final String handPhone;
  final String email;
  final String role;

  const SignUpRequest({
    required this.userId,
    required this.password,
    required this.name,
    required this.handPhone,
    required this.email,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'password': password,
      'name': name,
      'handPhone': handPhone,
      'email': email,
      'role': role,
    };
  }
}
