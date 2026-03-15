/// 커플 정보 모델 (서버 CoupleResponse 매핑).
///
/// groomOid / brideOid 는 서버가 IDOR 방지를 위해 응답에서 제거하였으므로
/// 이 모델에도 포함하지 않는다.
class CoupleModel {
  final String coupleOid;
  final String groomName;
  final String? brideName;
  final DateTime? weddingDate;
  final int? totalBudget;

  const CoupleModel({
    required this.coupleOid,
    required this.groomName,
    this.brideName,
    this.weddingDate,
    this.totalBudget,
  });

  factory CoupleModel.fromJson(Map<String, dynamic> json) {
    return CoupleModel(
      coupleOid: json['coupleOid'] as String,
      groomName: json['groomName'] as String,
      brideName: json['brideName'] as String?,
      weddingDate: json['weddingDate'] != null
          ? DateTime.parse(json['weddingDate'] as String)
          : null,
      totalBudget: (json['totalBudget'] as num?)?.toInt(),
    );
  }
}
