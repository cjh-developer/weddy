import 'budget_item_model.dart';

/// 예산 카테고리 모델.
/// 서버 BudgetResponse DTO와 1:1 대응한다.
///
/// spentAmount / remainingAmount / usageRatio는 서버에서 계산된 값을 그대로 사용한다.
class BudgetModel {
  final String oid;
  final String category;
  final int plannedAmount;
  final int spentAmount;
  final int remainingAmount;
  final DateTime createdAt;
  final List<BudgetItemModel> items;

  const BudgetModel({
    required this.oid,
    required this.category,
    required this.plannedAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.createdAt,
    required this.items,
  });

  /// 예산 사용률 (0.0 ~ 1.0).
  /// plannedAmount가 0이면 0.0을 반환한다.
  double get usageRatio =>
      plannedAmount == 0 ? 0.0 : (spentAmount / plannedAmount).clamp(0.0, double.infinity);

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        oid: json['oid'] as String,
        category: json['category'] as String,
        plannedAmount: (json['plannedAmount'] as num).toInt(),
        spentAmount: (json['spentAmount'] as num).toInt(),
        remainingAmount: (json['remainingAmount'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        items: (json['items'] as List<dynamic>)
            .map((e) => BudgetItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  BudgetModel copyWithItems(List<BudgetItemModel> newItems) {
    final newSpent = newItems.fold(0, (sum, item) => sum + item.amount);
    return BudgetModel(
      oid: oid,
      category: category,
      plannedAmount: plannedAmount,
      spentAmount: newSpent,
      remainingAmount: plannedAmount - newSpent,
      createdAt: createdAt,
      items: newItems,
    );
  }
}
