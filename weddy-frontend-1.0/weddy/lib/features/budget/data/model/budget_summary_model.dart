/// 홈 화면용 예산 요약 모델.
/// 서버 BudgetSummaryResponse DTO와 1:1 대응한다.
class BudgetSummaryModel {
  final int totalPlanned;
  final int totalSpent;

  /// 예산 사용률 (서버 계산값, 0~100 범위의 퍼센트).
  final double usageRate;

  const BudgetSummaryModel({
    required this.totalPlanned,
    required this.totalSpent,
    required this.usageRate,
  });

  /// 0.0 ~ 1.0 범위의 진행률 (ProgressBar용).
  double get usageRatio => (usageRate / 100).clamp(0.0, 1.0);

  factory BudgetSummaryModel.fromJson(Map<String, dynamic> json) =>
      BudgetSummaryModel(
        totalPlanned: (json['totalPlanned'] as num).toInt(),
        totalSpent: (json['totalSpent'] as num).toInt(),
        usageRate: (json['usageRate'] as num).toDouble(),
      );
}
