import 'checklist_item_model.dart';

/// 체크리스트 모델.
/// 서버 ChecklistResponse DTO와 1:1 대응한다.
class ChecklistModel {
  final String oid;
  final String ownerOid;
  final String title;
  final String? category;
  final DateTime createdAt;
  final List<ChecklistItemModel> items;

  const ChecklistModel({
    required this.oid,
    required this.ownerOid,
    required this.title,
    this.category,
    required this.createdAt,
    required this.items,
  });

  factory ChecklistModel.fromJson(Map<String, dynamic> json) => ChecklistModel(
        oid: json['oid'] as String,
        ownerOid: json['ownerOid'] as String,
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
        ownerOid: ownerOid,
        title: title,
        category: category,
        createdAt: createdAt,
        items: newItems,
      );
}
