// VendorModel — BE VendorResponse / VendorDetailResponse 매핑
//
// BE JSON 키 (Lombok @Getter + Jackson 기본 직렬화):
//   oid, name, category, address, phone, description,
//   homepageUrl, favorite (bool — isFavorite getter → "favorite"),
//   favoriteOid (상세 조회 전용, null 가능)

class VendorModel {
  final String oid;
  final String name;
  final String category;
  final String? address;
  final String? phone;
  final String? description;
  final String? homepageUrl;
  final bool isFavorite;

  /// 즐겨찾기 OID — 상세 조회(VendorDetailResponse)에서만 포함.
  /// 즐겨찾기 삭제 API 호출 시 사용.
  final String? favoriteOid;

  const VendorModel({
    required this.oid,
    required this.name,
    required this.category,
    this.address,
    this.phone,
    this.description,
    this.homepageUrl,
    this.isFavorite = false,
    this.favoriteOid,
  });

  /// BE VendorResponse / VendorDetailResponse JSON → VendorModel
  ///
  /// Lombok @Builder + boolean isFavorite 필드는 Jackson이 "favorite"로 직렬화한다.
  /// (Lombok의 boolean getter isFavorite() → jackson은 "favorite" 키로 매핑)
  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      oid: json['oid'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      homepageUrl: json['homepageUrl'] as String?,
      // Jackson은 boolean isFavorite → "favorite" 키로 직렬화 (is 접두사 제거)
      isFavorite: json['favorite'] as bool? ?? false,
      favoriteOid: json['favoriteOid'] as String?,
    );
  }

  VendorModel copyWith({bool? isFavorite, String? favoriteOid}) {
    return VendorModel(
      oid: oid,
      name: name,
      category: category,
      address: address,
      phone: phone,
      description: description,
      homepageUrl: homepageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      favoriteOid: favoriteOid ?? this.favoriteOid,
    );
  }

  /// 카테고리 한국어 레이블
  String get categoryLabel => switch (category) {
        'HALL' => '예식장',
        'STUDIO' => '스튜디오',
        'DRESS' => '드레스',
        'MAKEUP' => '메이크업',
        'HONEYMOON' => '허니문',
        'ETC' => '기타',
        _ => category,
      };

  /// 카테고리별 아이콘 코드포인트 (Material Icons)
  int get categoryIconCodePoint => switch (category) {
        'HALL' => 0xe546,     // Icons.account_balance
        'STUDIO' => 0xe412,   // Icons.camera_alt
        'DRESS' => 0xe40d,    // Icons.checkroom
        'MAKEUP' => 0xe3d2,   // Icons.brush
        'HONEYMOON' => 0xe55e, // Icons.flight
        _ => 0xe8b0,          // Icons.store
      };
}
