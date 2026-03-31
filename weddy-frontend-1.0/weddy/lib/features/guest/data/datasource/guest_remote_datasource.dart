import 'package:dio/dio.dart';

import 'package:weddy/features/guest/data/model/guest_group_model.dart';
import 'package:weddy/features/guest/data/model/guest_model.dart';
import 'package:weddy/features/guest/data/model/guest_summary_model.dart';

/// 하객 관리 원격 데이터 소스.
///
/// BE 엔드포인트 (base: /api/v1):
///   GET    /guests/groups            → GuestGroupResponse[]
///   POST   /guests/groups            → GuestGroupResponse
///   PATCH  /guests/groups/{groupOid} → GuestGroupResponse
///   DELETE /guests/groups/{groupOid} → 204
///   GET    /guests/summary           → GuestSummaryResponse
///   GET    /guests?groupOid=&sort=   → GuestResponse[]
///   POST   /guests                   → GuestResponse
///   PATCH  /guests/{guestOid}        → GuestResponse
///   DELETE /guests/{guestOid}        → 204
class GuestRemoteDatasource {
  final Dio _dio;

  const GuestRemoteDatasource(this._dio);

  // ── 그룹 ─────────────────────────────────────────────────────────────────

  Future<List<GuestGroupModel>> getGroups() async {
    final resp = await _dio.get('/guests/groups');
    final data = resp.data['data'] as List<dynamic>;
    return data
        .map((e) => GuestGroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GuestGroupModel> createGroup(String name) async {
    final resp = await _dio.post('/guests/groups', data: {'name': name});
    return GuestGroupModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<GuestGroupModel> updateGroup(String groupOid, String name) async {
    final resp = await _dio.patch(
      '/guests/groups/$groupOid',
      data: {'name': name},
    );
    return GuestGroupModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteGroup(String groupOid) async {
    await _dio.delete('/guests/groups/$groupOid');
  }

  // ── 집계 + 목록 ──────────────────────────────────────────────────────────

  Future<GuestSummaryModel> getSummary() async {
    final resp = await _dio.get('/guests/summary');
    return GuestSummaryModel.fromJson(
        resp.data['data'] as Map<String, dynamic>);
  }

  Future<List<GuestModel>> getGuests({
    String? groupOid,
    String sort = 'NAME_ASC',
  }) async {
    final queryParams = <String, dynamic>{'sort': sort};
    if (groupOid != null) queryParams['groupOid'] = groupOid;

    final resp = await _dio.get('/guests', queryParameters: queryParams);
    final data = resp.data['data'] as List<dynamic>;
    return data
        .map((e) => GuestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 하객 CRUD ────────────────────────────────────────────────────────────

  Future<GuestModel> createGuest(Map<String, dynamic> body) async {
    final resp = await _dio.post('/guests', data: body);
    return GuestModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<GuestModel> updateGuest(
      String guestOid, Map<String, dynamic> body) async {
    final resp = await _dio.patch('/guests/$guestOid', data: body);
    return GuestModel.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteGuest(String guestOid) async {
    await _dio.delete('/guests/$guestOid');
  }
}
