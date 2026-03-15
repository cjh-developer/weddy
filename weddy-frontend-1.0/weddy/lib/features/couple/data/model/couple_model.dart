/// 커플 정보 모델 (서버 CoupleResponse 매핑).
class CoupleModel {
  final String coupleOid;
  final String groomOid;
  final String groomName;
  final String? brideOid;
  final String? brideName;
  final DateTime? weddingDate;
  final int? totalBudget;

  const CoupleModel({
    required this.coupleOid,
    required this.groomOid,
    required this.groomName,
    this.brideOid,
    this.brideName,
    this.weddingDate,
    this.totalBudget,
  });

  factory CoupleModel.fromJson(Map<String, dynamic> json) {
    return CoupleModel(
      coupleOid: json['coupleOid'] as String,
      groomOid: json['groomOid'] as String,
      groomName: json['groomName'] as String,
      brideOid: json['brideOid'] as String?,
      brideName: json['brideName'] as String?,
      weddingDate: json['weddingDate'] != null
          ? DateTime.parse(json['weddingDate'] as String)
          : null,
      totalBudget: (json['totalBudget'] as num?)?.toInt(),
    );
  }
}
