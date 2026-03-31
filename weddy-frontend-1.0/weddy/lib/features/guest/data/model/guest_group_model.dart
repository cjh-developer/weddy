// GuestGroupModel — BE GuestGroupResponse 매핑
//
// BE JSON 키:
//   oid, name, isDefault (boolean — @JsonProperty("isDefault") 명시),
//   sortOrder, guestCount

class GuestGroupModel {
  final String oid;
  final String name;
  final bool isDefault;
  final int sortOrder;
  final int guestCount;

  const GuestGroupModel({
    required this.oid,
    required this.name,
    required this.isDefault,
    required this.sortOrder,
    required this.guestCount,
  });

  factory GuestGroupModel.fromJson(Map<String, dynamic> json) {
    return GuestGroupModel(
      oid: json['oid'] as String,
      name: json['name'] as String,
      // BE에서 @JsonProperty("isDefault") 명시로 boolean이 "isDefault" 키로 직렬화됨
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      guestCount: json['guestCount'] as int? ?? 0,
    );
  }

  GuestGroupModel copyWith({String? name, int? guestCount}) {
    return GuestGroupModel(
      oid: oid,
      name: name ?? this.name,
      isDefault: isDefault,
      sortOrder: sortOrder,
      guestCount: guestCount ?? this.guestCount,
    );
  }
}
