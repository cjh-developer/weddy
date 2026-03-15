/// 서버 GET /users/me 응답 DTO.
///
/// ApiResponse<UserModel> 의 data 필드로 전달된다.
/// inviteCode, weddingDate는 서버에서 null일 수 있으므로 nullable로 선언한다.
class UserModel {
  final String userOid;
  final String userId;
  final String name;
  final String handPhone;
  final String email;
  final String role;
  final String? inviteCode;
  final DateTime? weddingDate;

  const UserModel({
    required this.userOid,
    required this.userId,
    required this.name,
    required this.handPhone,
    required this.email,
    required this.role,
    this.inviteCode,
    this.weddingDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userOid: json['userOid'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      handPhone: json['handPhone'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      inviteCode: json['inviteCode'] as String?,
      weddingDate: json['weddingDate'] != null
          ? DateTime.parse(json['weddingDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userOid': userOid,
      'userId': userId,
      'name': name,
      'handPhone': handPhone,
      'email': email,
      'role': role,
      if (inviteCode != null) 'inviteCode': inviteCode,
      if (weddingDate != null)
        'weddingDate':
            '${weddingDate!.year.toString().padLeft(4, '0')}-${weddingDate!.month.toString().padLeft(2, '0')}-${weddingDate!.day.toString().padLeft(2, '0')}',
    };
  }

  /// 일부 필드만 변경한 새 인스턴스를 반환한다.
  UserModel copyWith({
    String? userOid,
    String? userId,
    String? name,
    String? handPhone,
    String? email,
    String? role,
    String? inviteCode,
    bool clearInviteCode = false,
    DateTime? weddingDate,
    bool clearWeddingDate = false,
  }) {
    return UserModel(
      userOid: userOid ?? this.userOid,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      handPhone: handPhone ?? this.handPhone,
      email: email ?? this.email,
      role: role ?? this.role,
      inviteCode: clearInviteCode ? null : (inviteCode ?? this.inviteCode),
      weddingDate: clearWeddingDate ? null : (weddingDate ?? this.weddingDate),
    );
  }

  @override
  String toString() {
    return 'UserModel('
        'userOid: $userOid, '
        'userId: $userId, '
        'name: $name, '
        'role: $role'
        ')';
  }
}
