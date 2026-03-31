// GuestModel — BE GuestResponse 매핑
//
// BE JSON 키:
//   oid, groupOid (nullable), groupName (nullable),
//   name, companionCount, giftAmount,
//   invitationStatus (PAPER|MOBILE|NONE),
//   attendStatus (ATTEND|ABSENT|UNDECIDED),
//   memo (nullable)

class GuestModel {
  final String oid;
  final String? groupOid;
  final String? groupName;
  final String name;
  final int companionCount;
  // BE GuestResponse.giftAmount는 long (최대 9,999,999원) — int로 저장 (Dart int = 64bit, 오버플로우 없음)
  final int giftAmount;

  /// PAPER | MOBILE | NONE
  final String invitationStatus;

  /// ATTEND | ABSENT | UNDECIDED
  final String attendStatus;
  final String? memo;

  const GuestModel({
    required this.oid,
    this.groupOid,
    this.groupName,
    required this.name,
    required this.companionCount,
    required this.giftAmount,
    required this.invitationStatus,
    required this.attendStatus,
    this.memo,
  });

  factory GuestModel.fromJson(Map<String, dynamic> json) {
    return GuestModel(
      oid: json['oid'] as String,
      groupOid: json['groupOid'] as String?,
      groupName: json['groupName'] as String?,
      name: json['name'] as String,
      companionCount: json['companionCount'] as int? ?? 0,
      giftAmount: (json['giftAmount'] as num?)?.toInt() ?? 0,
      invitationStatus: json['invitationStatus'] as String? ?? 'NONE',
      attendStatus: json['attendStatus'] as String? ?? 'UNDECIDED',
      memo: json['memo'] as String?,
    );
  }

  GuestModel copyWith({
    String? groupOid,
    bool clearGroup = false,
    String? groupName,
    String? name,
    int? companionCount,
    int? giftAmount,
    String? invitationStatus,
    String? attendStatus,
    String? memo,
  }) {
    return GuestModel(
      oid: oid,
      groupOid: clearGroup ? null : (groupOid ?? this.groupOid),
      groupName: clearGroup ? null : (groupName ?? this.groupName),
      name: name ?? this.name,
      companionCount: companionCount ?? this.companionCount,
      giftAmount: giftAmount ?? this.giftAmount,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      attendStatus: attendStatus ?? this.attendStatus,
      memo: memo ?? this.memo,
    );
  }

  /// 본인 포함 총 인원 (companion_count + 1)
  int get totalCount => companionCount + 1;

  /// 참석 여부 한국어 레이블
  String get attendLabel => switch (attendStatus) {
        'ATTEND' => '참석',
        'ABSENT' => '불참',
        _ => '미정',
      };

  /// 청첩장 상태 한국어 레이블
  String get inviteLabel => switch (invitationStatus) {
        'PAPER' => '종이',
        'MOBILE' => '모바일',
        _ => '미전달',
      };
}
