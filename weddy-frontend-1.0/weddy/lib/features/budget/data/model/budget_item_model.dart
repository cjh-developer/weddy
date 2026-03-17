/// 예산 항목 모델.
/// 서버 BudgetItemResponse DTO와 1:1 대응한다.
class BudgetItemModel {
  final String oid;
  final String title;
  final int amount;
  final String? memo;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BudgetItemModel({
    required this.oid,
    required this.title,
    required this.amount,
    this.memo,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetItemModel.fromJson(Map<String, dynamic> json) => BudgetItemModel(
        oid: json['oid'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toInt(),
        memo: json['memo'] as String?,
        paidAt: json['paidAt'] != null
            ? DateTime.parse(json['paidAt'] as String).toLocal()
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
