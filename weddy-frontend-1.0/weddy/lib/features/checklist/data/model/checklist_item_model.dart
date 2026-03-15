/// 체크리스트 항목 모델.
/// 서버 ChecklistItemResponse DTO와 1:1 대응한다.
class ChecklistItemModel {
  final String oid;
  final String checklistOid;
  final String content;
  final bool isDone;
  final DateTime? dueDate;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChecklistItemModel({
    required this.oid,
    required this.checklistOid,
    required this.content,
    required this.isDone,
    this.dueDate,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) =>
      ChecklistItemModel(
        oid: json['oid'] as String,
        checklistOid: json['checklistOid'] as String,
        content: json['content'] as String,
        isDone: json['isDone'] as bool,
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String).toLocal()
            : null,
        sortOrder: json['sortOrder'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  ChecklistItemModel copyWith({bool? isDone}) => ChecklistItemModel(
        oid: oid,
        checklistOid: checklistOid,
        content: content,
        isDone: isDone ?? this.isDone,
        dueDate: dueDate,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
