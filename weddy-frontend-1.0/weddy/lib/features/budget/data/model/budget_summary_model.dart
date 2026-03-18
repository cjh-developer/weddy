/// 홈 화면용 예산 요약 모델.
/// 서버 BudgetSummaryResponse DTO와 1:1 대응한다.
class BudgetSummaryModel {
  final int totalPlanned;
  final int totalSpent;

  /// 예산 사용률 (서버 계산값, 0~100+ 범위의 퍼센트).
  final double usageRate;

  /// 전체 예산 설정값 (설정하지 않은 경우 null).
  final int? totalBudget;

  const BudgetSummaryModel({
    required this.totalPlanned,
    required this.totalSpent,
    required this.usageRate,
    this.totalBudget,
  });

  /// 0.0 ~ 1.0 범위의 진행률 (ProgressBar용).
  double get usageRatio => (usageRate / 100).clamp(0.0, 1.0);

  /// 예산 초과 여부 (usageRate > 100).
  bool get isOver => usageRate > 100;

  /// 초과율 (초과 시 초과된 퍼센트, 정상 시 0.0).
  double get overRate => isOver ? usageRate - 100.0 : 0.0;

  factory BudgetSummaryModel.fromJson(Map<String, dynamic> json) =>
      BudgetSummaryModel(
        totalPlanned: (json['totalPlanned'] as num).toInt(),
        totalSpent: (json['totalSpent'] as num).toInt(),
        usageRate: (json['usageRate'] as num).toDouble(),
        totalBudget: json['totalBudget'] == null
            ? null
            : (json['totalBudget'] as num).toInt(),
      );
}
