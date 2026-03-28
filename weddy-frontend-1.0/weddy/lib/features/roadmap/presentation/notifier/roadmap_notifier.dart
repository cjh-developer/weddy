import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/api_response.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/roadmap/data/model/hall_tour_model.dart';
import 'package:weddy/features/roadmap/data/model/roadmap_step_model.dart';

// ---------------------------------------------------------------------------
// 웨딩 관리 상태 sealed class
// ---------------------------------------------------------------------------

sealed class RoadmapState {
  const RoadmapState();
}

final class RoadmapInitial extends RoadmapState {
  const RoadmapInitial();
}

final class RoadmapLoading extends RoadmapState {
  const RoadmapLoading();
}

final class RoadmapLoaded extends RoadmapState {
  final List<RoadmapStepModel> steps;
  const RoadmapLoaded(this.steps);
}

final class RoadmapError extends RoadmapState {
  final String message;
  const RoadmapError(this.message);
}

// ---------------------------------------------------------------------------
// RoadmapNotifier
// ---------------------------------------------------------------------------

class RoadmapNotifier extends StateNotifier<RoadmapState> {
  final Dio _dio;

  RoadmapNotifier(this._dio) : super(const RoadmapInitial());

  /// 로드맵 단계 전체를 불러온다.
  Future<void> loadSteps() async {
    state = const RoadmapLoading();
    try {
      final res = await _dio.get(
        '/roadmap',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (!mounted) return;

      if (res.statusCode == 404) {
        state = const RoadmapLoaded([]);
        return;
      }

      final apiResp = ApiResponse<List<dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as List<dynamic>,
      );
      if (apiResp.success && apiResp.data != null) {
        final list = apiResp.data!
            .map((e) => RoadmapStepModel.fromJson(e as Map<String, dynamic>))
            .toList();
        // sortOrder 기준 정렬
        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        state = RoadmapLoaded(list);
      } else {
        state = RoadmapError(apiResp.message);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? RoadmapError((e.error as ApiException).message)
          : RoadmapError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const RoadmapError('웨딩 관리 정보를 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 완료 상태를 낙관적으로 토글한 뒤 서버에 반영한다.
  Future<void> toggleDone(String oid) async {
    final current = state;
    if (current is! RoadmapLoaded) return;

    // 낙관적 업데이트
    final optimistic = current.steps.map((s) {
      if (s.oid != oid) return s;
      return s.copyWith(isDone: !s.isDone);
    }).toList();
    state = RoadmapLoaded(optimistic);

    try {
      await _dio.patch('/roadmap/$oid/toggle');
      if (!mounted) return;
      // 서버 동기화 (조용히)
      await loadSteps();
    } on DioException catch (e) {
      if (!mounted) return;
      // 실패 시 복원
      state = current;
      final errorMsg = e.error is ApiException
          ? (e.error as ApiException).message
          : ApiException.fromDioException(e).message;
      state = RoadmapError(errorMsg);
    } catch (_) {
      if (!mounted) return;
      state = current;
      state = const RoadmapError('상태 변경 중 오류가 발생했습니다.');
    }
  }

  /// 단계를 낙관적으로 삭제한다. 실패 시 이전 상태로 복원한다.
  Future<bool> deleteStep(String oid) async {
    final current = state;
    if (current is! RoadmapLoaded) return false;

    // 낙관적 삭제
    state = RoadmapLoaded(
      current.steps.where((s) => s.oid != oid).toList(),
    );

    try {
      await _dio.delete('/roadmap/$oid');
      if (!mounted) return false;
      await loadSteps();
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = current;
      final errorMsg = e.error is ApiException
          ? (e.error as ApiException).message
          : ApiException.fromDioException(e).message;
      state = RoadmapError(errorMsg);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = current;
      state = const RoadmapError('단계 삭제 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 단계 정보를 업데이트한다.
  Future<bool> updateStep(
    String oid,
    Map<String, dynamic> details, {
    String? title,
    DateTime? dueDate,
    bool? hasDueDate,
    bool clearDueDate = false,
  }) async {
    try {
      String fmtDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      final body = <String, dynamic>{
        'details': details,
        if (title != null && title.isNotEmpty) 'title': title,
        if (hasDueDate != null) 'hasDueDate': hasDueDate,
        if (clearDueDate)
          'dueDate': null
        else if (dueDate != null)
          'dueDate': fmtDate(dueDate),
      };

      await _dio.put('/roadmap/$oid', data: body);
      if (!mounted) return false;
      await loadSteps();
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = e.error is ApiException
          ? RoadmapError((e.error as ApiException).message)
          : RoadmapError(ApiException.fromDioException(e).message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const RoadmapError('단계 정보 저장 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 새 로드맵 단계를 생성한다.
  Future<bool> createStep({
    required String stepType,
    required String title,
    DateTime? dueDate,
    bool hasDueDate = false,
  }) async {
    try {
      String fmtDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      final body = <String, dynamic>{
        'stepType': stepType,
        'title': title,
        'hasDueDate': hasDueDate,
        if (hasDueDate && dueDate != null) 'dueDate': fmtDate(dueDate),
        'details': '{}',
      };

      await _dio.post('/roadmap', data: body);
      if (!mounted) return false;
      await loadSteps();
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = e.error is ApiException
          ? RoadmapError((e.error as ApiException).message)
          : RoadmapError(ApiException.fromDioException(e).message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const RoadmapError('단계 생성 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 웨딩홀 투어를 추가한다.
  Future<bool> addHallTour(
      String stepOid, Map<String, dynamic> tourData) async {
    try {
      await _dio.post('/roadmap/$stepOid/hall-tours', data: tourData);
      if (!mounted) return false;
      await loadSteps();
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = e.error is ApiException
          ? RoadmapError((e.error as ApiException).message)
          : RoadmapError(ApiException.fromDioException(e).message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const RoadmapError('웨딩홀 투어 추가 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 특정 단계의 웨딩홀 투어 목록을 조회한다.
  Future<List<HallTourModel>> getHallTours(String stepOid) async {
    try {
      final res = await _dio.get(
        '/roadmap/$stepOid/hall-tours',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (res.statusCode == 404) return [];
      final apiResp = ApiResponse<List<dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as List<dynamic>,
      );
      if (!apiResp.success || apiResp.data == null) return [];
      return apiResp.data!
          .map((e) => HallTourModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 에러 상태를 초기화한다.
  void clearError() {
    if (state is RoadmapError) state = const RoadmapInitial();
  }

  /// 로그아웃 시 상태를 초기화한다.
  void reset() {
    state = const RoadmapInitial();
  }
}

final roadmapNotifierProvider =
    StateNotifierProvider<RoadmapNotifier, RoadmapState>((ref) {
  return RoadmapNotifier(ref.watch(dioClientProvider));
});
