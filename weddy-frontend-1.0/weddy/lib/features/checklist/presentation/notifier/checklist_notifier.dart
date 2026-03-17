import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/api_response.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/checklist/data/model/checklist_model.dart';

// ---------------------------------------------------------------------------
// 체크리스트 상태 sealed class
// ---------------------------------------------------------------------------

sealed class ChecklistState {
  const ChecklistState();
}

final class ChecklistInitial extends ChecklistState {
  const ChecklistInitial();
}

final class ChecklistLoading extends ChecklistState {
  const ChecklistLoading();
}

final class ChecklistLoaded extends ChecklistState {
  final List<ChecklistModel> checklists;
  const ChecklistLoaded(this.checklists);
}

final class ChecklistError extends ChecklistState {
  final String message;
  const ChecklistError(this.message);
}

// ---------------------------------------------------------------------------
// ChecklistNotifier
// ---------------------------------------------------------------------------

class ChecklistNotifier extends StateNotifier<ChecklistState> {
  final Dio _dio;

  ChecklistNotifier(this._dio) : super(const ChecklistInitial());

  /// 체크리스트 전체 목록을 서버에서 불러온다.
  /// 커플 미연결(404) 시 빈 목록으로 처리한다.
  Future<void> loadChecklists() async {
    state = const ChecklistLoading();
    try {
      final res = await _dio.get(
        '/checklists',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (!mounted) return;
      if (res.statusCode == 404) {
        state = const ChecklistLoaded([]);
        return;
      }
      final apiResp = ApiResponse<List<dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as List<dynamic>,
      );
      if (apiResp.success && apiResp.data != null) {
        final list = apiResp.data!
            .map((e) => ChecklistModel.fromJson(e as Map<String, dynamic>))
            .toList();
        state = ChecklistLoaded(list);
      } else {
        state = ChecklistError(apiResp.message);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? ChecklistError((e.error as ApiException).message)
          : ChecklistError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const ChecklistError('체크리스트를 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 새 체크리스트를 생성한다.
  Future<void> createChecklist(String title, String? category) async {
    try {
      final body = <String, dynamic>{'title': title};
      if (category != null && category.isNotEmpty) body['category'] = category;
      await _dio.post('/checklists', data: body);
      if (!mounted) return;
      await loadChecklists();
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? ChecklistError((e.error as ApiException).message)
          : ChecklistError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const ChecklistError('체크리스트 생성 중 오류가 발생했습니다.');
    }
  }

  /// 체크리스트를 삭제한다.
  Future<void> deleteChecklist(String checklistOid) async {
    try {
      await _dio.delete('/checklists/$checklistOid');
      if (!mounted) return;
      await loadChecklists();
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? ChecklistError((e.error as ApiException).message)
          : ChecklistError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const ChecklistError('체크리스트 삭제 중 오류가 발생했습니다.');
    }
  }

  /// 체크리스트에 항목을 추가한다.
  Future<void> addItem(
    String checklistOid,
    String content,
    DateTime? dueDate,
    int sortOrder,
  ) async {
    try {
      final body = <String, dynamic>{
        'content': content,
        'sortOrder': sortOrder,
        if (dueDate != null)
          'dueDate':
              '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
      };
      await _dio.post('/checklists/$checklistOid/items', data: body);
      if (!mounted) return;
      await loadChecklists();
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? ChecklistError((e.error as ApiException).message)
          : ChecklistError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const ChecklistError('항목 추가 중 오류가 발생했습니다.');
    }
  }

  /// 완료 여부를 토글한다. 낙관적 업데이트 후 서버에 반영한다.
  /// 서버 실패 시 이전 상태로 롤백하지 않고 loadChecklists()로 동기화한다.
  Future<void> toggleItem(
    String checklistOid,
    String itemOid,
    bool currentIsDone,
  ) async {
    // 낙관적 업데이트
    if (state is ChecklistLoaded) {
      final current = (state as ChecklistLoaded).checklists;
      final optimistic = current.map((cl) {
        if (cl.oid != checklistOid) return cl;
        final updatedItems = cl.items.map((item) {
          if (item.oid != itemOid) return item;
          return item.copyWith(isDone: !currentIsDone);
        }).toList();
        return cl.copyWithItems(updatedItems);
      }).toList();
      state = ChecklistLoaded(optimistic);
    }

    try {
      await _dio.patch(
        '/checklists/$checklistOid/items/$itemOid',
        data: {'isDone': !currentIsDone},
      );
      // 서버 동기화 (조용히)
      if (!mounted) return;
      final res = await _dio.get(
        '/checklists',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (!mounted) return;
      final apiResp = ApiResponse<List<dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as List<dynamic>,
      );
      if (apiResp.success && apiResp.data != null) {
        final list = apiResp.data!
            .map((e) => ChecklistModel.fromJson(e as Map<String, dynamic>))
            .toList();
        state = ChecklistLoaded(list);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      // 실패 시 이전 상태로 직접 복원 (loadChecklists 후 에러 상태 덮어쓰기 방지)
      final errorMsg = e.error is ApiException
          ? (e.error as ApiException).message
          : ApiException.fromDioException(e).message;
      await loadChecklists();
      if (!mounted) return;
      state = ChecklistError(errorMsg);
    } catch (_) {
      if (!mounted) return;
      await loadChecklists();
    }
  }

  /// 체크리스트 항목을 삭제한다.
  Future<void> deleteItem(String checklistOid, String itemOid) async {
    try {
      await _dio.delete('/checklists/$checklistOid/items/$itemOid');
      if (!mounted) return;
      await loadChecklists();
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? ChecklistError((e.error as ApiException).message)
          : ChecklistError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const ChecklistError('항목 삭제 중 오류가 발생했습니다.');
    }
  }

  /// 에러 상태를 초기화한다.
  void clearError() {
    if (state is ChecklistError) state = const ChecklistInitial();
  }

  /// 로그아웃 시 체크리스트 상태를 초기화한다.
  void reset() {
    state = const ChecklistInitial();
  }
}

final checklistNotifierProvider =
    StateNotifierProvider<ChecklistNotifier, ChecklistState>((ref) {
  return ChecklistNotifier(ref.watch(dioClientProvider));
});

// ---------------------------------------------------------------------------
// 홈 화면용 체크리스트 제목 프리뷰 Provider (최대 3개)
// ---------------------------------------------------------------------------

/// 홈 화면에서 체크리스트 제목 최대 3개를 조회한다.
/// 커플 미연결 상태(404)는 빈 리스트로 처리한다.
final checklistPreviewProvider =
    FutureProvider.autoDispose<List<ChecklistModel>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  try {
    final res = await dio.get(
      '/checklists',
      options: Options(validateStatus: (s) => s != null && s < 500),
    );
    if (res.statusCode == 404) return [];
    final apiResp = ApiResponse<List<dynamic>>.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as List<dynamic>,
    );
    if (!apiResp.success || apiResp.data == null) return [];
    final all = apiResp.data!
        .map((e) => ChecklistModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return all.length > 3 ? all.sublist(0, 3) : all;
  } catch (_) {
    return [];
  }
});
