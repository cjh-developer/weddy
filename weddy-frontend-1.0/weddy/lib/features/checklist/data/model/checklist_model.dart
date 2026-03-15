import 'checklist_item_model.dart';

/// 체크리스트 모델.
/// 서버 ChecklistResponse DTO와 1:1 대응한다.
class ChecklistModel {
  final String oid;
  final String coupleOid;
  final String title;
  final String? category;
  final DateTime createdAt;
  final List<ChecklistItemModel> items;

  const ChecklistModel({
    required this.oid,
    required this.coupleOid,
    required this.title,
    this.category,
    required this.createdAt,
    required this.items,
  });

  factory ChecklistModel.fromJson(Map<String, dynamic> json) => ChecklistModel(
        oid: json['oid'] as String,
        coupleOid: json['coupleOid'] as String,
        title: json['title'] as String,
        category: json['category'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        items: (json['items'] as List<dynamic>)
            .map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ChecklistModel copyWithItems(List<ChecklistItemModel> newItems) =>
      ChecklistModel(
        oid: oid,
        coupleOid: coupleOid,
        title: title,
        category: category,
        createdAt: createdAt,
        items: newItems,
      );
}
