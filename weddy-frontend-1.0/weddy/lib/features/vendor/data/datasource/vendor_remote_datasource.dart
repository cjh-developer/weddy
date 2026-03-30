import 'package:dio/dio.dart';

import 'package:weddy/features/vendor/data/model/vendor_model.dart';

/// 업체 및 즐겨찾기 원격 데이터 소스.
///
/// BE 엔드포인트 (base: /api/v1):
///   GET  /vendors?category=&keyword=   → VendorResponse[]
///   GET  /vendors/{vendorOid}           → VendorDetailResponse
///   GET  /vendors/favorites             → FavoriteItemResponse[]
///   POST /vendors/favorites             → AddFavoriteResponse
///   DELETE /vendors/favorites/{favOid} → 204
class VendorRemoteDatasource {
  final Dio _dio;

  const VendorRemoteDatasource(this._dio);

  /// 업체 목록 조회/검색.
  /// [category] null이면 전체. [keyword] null이거나 빈 문자열이면 전체 검색.
  Future<List<VendorModel>> getVendors({
    String? category,
    String? keyword,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParams['keyword'] = keyword.trim();
    }

    final resp = await _dio.get(
      '/vendors',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = resp.data['data'] as List<dynamic>;
    return data
        .map((e) => VendorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 업체 상세 조회. favoriteOid 포함.
  Future<VendorModel> getVendor(String vendorOid) async {
    final resp = await _dio.get('/vendors/$vendorOid');
    return VendorModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  /// 즐겨찾기 목록 조회 — FavoriteItemResponse 배열에서 vendor 필드만 추출.
  Future<List<VendorModel>> getFavoriteVendors() async {
    final resp = await _dio.get('/vendors/favorites');
    final data = resp.data['data'] as List<dynamic>;
    return data.map((e) {
      final item = e as Map<String, dynamic>;
      final vendorJson = item['vendor'] as Map<String, dynamic>;
      // FavoriteItemResponse.vendor는 isFavorite=true로 고정 (BE에서 true 반환)
      // favoriteOid는 FavoriteItemResponse 최상위에 있으므로 vendor에 병합
      vendorJson['favoriteOid'] = item['favoriteOid'] as String?;
      return VendorModel.fromJson(vendorJson);
    }).toList();
  }

  /// 즐겨찾기 추가. 반환값: {favoriteOid, vendorOid}
  Future<Map<String, dynamic>> addFavorite(String vendorOid) async {
    final resp = await _dio.post(
      '/vendors/favorites',
      data: {'vendorOid': vendorOid},
    );
    return resp.data['data'] as Map<String, dynamic>;
  }

  /// 즐겨찾기 삭제.
  Future<void> removeFavorite(String favoriteOid) async {
    await _dio.delete('/vendors/favorites/$favoriteOid');
  }
}
