/// 웨딩홀 투어 항목 모델.
///
/// HALL 단계의 세부 투어 일정을 나타내며, 대관료/식대 등 비용 정보를 포함한다.
class HallTourModel {
  final String oid;
  final String stepOid;
  final String hallName;
  final DateTime? tourDate;
  final String? location;
  final int? rentalFee;
  final int? mealPrice;
  final int? minGuests;
  final String? memo;

  /// 서버에서 계산된 총 식대 (식대/1인 × 보증인원).
  final int? totalMealCost;

  const HallTourModel({
    required this.oid,
    required this.stepOid,
    required this.hallName,
    this.tourDate,
    this.location,
    this.rentalFee,
    this.mealPrice,
    this.minGuests,
    this.memo,
    this.totalMealCost,
  });

  factory HallTourModel.fromJson(Map<String, dynamic> json) {
    return HallTourModel(
      oid: json['oid'] as String,
      stepOid: json['stepOid'] as String,
      hallName: json['hallName'] as String,
      tourDate: json['tourDate'] != null
          ? DateTime.tryParse(json['tourDate'] as String)
          : null,
      location: json['location'] as String?,
      rentalFee: json['rentalFee'] as int?,
      mealPrice: json['mealPrice'] as int?,
      minGuests: json['minGuests'] as int?,
      memo: json['memo'] as String?,
      totalMealCost: json['totalMealCost'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oid': oid,
      'stepOid': stepOid,
      'hallName': hallName,
      if (tourDate != null)
        'tourDate': '${tourDate!.year.toString().padLeft(4, '0')}-'
            '${tourDate!.month.toString().padLeft(2, '0')}-'
            '${tourDate!.day.toString().padLeft(2, '0')}',
      if (location != null) 'location': location,
      if (rentalFee != null) 'rentalFee': rentalFee,
      if (mealPrice != null) 'mealPrice': mealPrice,
      if (minGuests != null) 'minGuests': minGuests,
      if (memo != null) 'memo': memo,
      if (totalMealCost != null) 'totalMealCost': totalMealCost,
    };
  }

  /// 클라이언트 측에서 계산한 총 식대 (식대 × 보증인원)
  int get calculatedTotalMealCost =>
      (mealPrice ?? 0) * (minGuests ?? 0);
}
