// GuestSummaryModel — BE GuestSummaryResponse 매핑
//
// BE JSON 키:
//   totalCount, attendCount, absentCount, undecidedCount, totalGiftAmount
// 모든 카운트: SUM(companion_count + 1) 기준

class GuestSummaryModel {
  final int totalCount;
  final int attendCount;
  final int absentCount;
  final int undecidedCount;
  final int totalGiftAmount;

  const GuestSummaryModel({
    required this.totalCount,
    required this.attendCount,
    required this.absentCount,
    required this.undecidedCount,
    required this.totalGiftAmount,
  });

  const GuestSummaryModel.empty()
      : totalCount = 0,
        attendCount = 0,
        absentCount = 0,
        undecidedCount = 0,
        totalGiftAmount = 0;

  factory GuestSummaryModel.fromJson(Map<String, dynamic> json) {
    return GuestSummaryModel(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      attendCount: (json['attendCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      undecidedCount: (json['undecidedCount'] as num?)?.toInt() ?? 0,
      totalGiftAmount: (json['totalGiftAmount'] as num?)?.toInt() ?? 0,
    );
  }
}
