/// 전체 예산 설정 모델.
/// 서버 BudgetSettingsResponse DTO와 1:1 대응한다.
class BudgetSettingsModel {
  final int? totalBudget;

  const BudgetSettingsModel({this.totalBudget});

  /// totalBudget이 null이 아니고 0보다 크면 설정된 상태로 간주한다.
  bool get isConfigured => totalBudget != null && totalBudget! > 0;

  factory BudgetSettingsModel.fromJson(Map<String, dynamic> json) =>
      BudgetSettingsModel(
        totalBudget: json['totalBudget'] == null
            ? null
            : (json['totalBudget'] as num).toInt(),
      );
}
