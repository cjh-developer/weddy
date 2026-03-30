import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/api_response.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/roadmap/data/model/custom_roadmap_model.dart';

// ---------------------------------------------------------------------------
// 직접 로드맵 상태 sealed class
// ---------------------------------------------------------------------------

sealed class CustomRoadmapState {
  const CustomRoadmapState();
}

final class CustomRoadmapInitial extends CustomRoadmapState {
  const CustomRoadmapInitial();
}

final class CustomRoadmapLoading extends CustomRoadmapState {
  const CustomRoadmapLoading();
}

final class CustomRoadmapLoaded extends CustomRoadmapState {
  final List<CustomRoadmapModel> roadmaps;
  const CustomRoadmapLoaded(this.roadmaps);
}

final class CustomRoadmapError extends CustomRoadmapState {
  final String message;
  const CustomRoadmapError(this.message);
}

// ---------------------------------------------------------------------------
// CustomRoadmapNotifier
// ---------------------------------------------------------------------------

class CustomRoadmapNotifier extends StateNotifier<CustomRoadmapState> {
  final Dio _dio;

  CustomRoadmapNotifier(this._dio) : super(const CustomRoadmapInitial());

  /// 직접 로드맵 목록(및 소속 steps 포함)을 서버에서 불러온다.
  Future<void> loadCustomRoadmaps() async {
    state = const CustomRoadmapLoading();
    try {
      final res = await _dio.get(
        '/roadmap/custom',
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (!mounted) return;

      if (res.statusCode == 404) {
        state = const CustomRoadmapLoaded([]);
        return;
      }

      final apiResp = ApiResponse<List<dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as List<dynamic>,
      );
      if (apiResp.success && apiResp.data != null) {
        final list = apiResp.data!
            .map((e) => CustomRoadmapModel.fromJson(e as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        state = CustomRoadmapLoaded(list);
      } else {
        state = CustomRoadmapError(apiResp.message);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? CustomRoadmapError((e.error as ApiException).message)
          : CustomRoadmapError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const CustomRoadmapError('직접 로드맵을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 새 직접 로드맵 컨테이너를 생성한다.
  /// 성공 시 생성된 [CustomRoadmapModel]을 반환하고 상태에 즉시 반영한다.
  Future<CustomRoadmapModel?> createCustomRoadmap(String name) async {
    try {
      final res = await _dio.post('/roadmap/custom', data: {'name': name});
      if (!mounted) return null;
      final apiResp = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as Map<String, dynamic>,
      );
      if (apiResp.success && apiResp.data != null) {
        final newRoadmap = CustomRoadmapModel.fromJson(apiResp.data!);
        final current = state;
        if (current is CustomRoadmapLoaded) {
          state = CustomRoadmapLoaded([...current.roadmaps, newRoadmap]);
        } else {
          state = CustomRoadmapLoaded([newRoadmap]);
        }
        return newRoadmap;
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 직접 로드맵 이름을 변경한다.
  Future<bool> renameCustomRoadmap(String groupOid, String newName) async {
    try {
      final res = await _dio.patch(
        '/roadmap/custom/$groupOid',
        data: {'name': newName},
      );
      if (!mounted) return false;
      final apiResp = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as Map<String, dynamic>,
      );
      if (apiResp.success) {
        // 전체 재로드로 서버 상태와 동기화
        await loadCustomRoadmaps();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 직접 로드맵을 삭제한다. 낙관적 업데이트 후 서버에 반영하며 실패 시 복원한다.
  Future<bool> deleteCustomRoadmap(String groupOid) async {
    final current = state;
    if (current is CustomRoadmapLoaded) {
      // 낙관적 삭제
      state = CustomRoadmapLoaded(
        current.roadmaps.where((r) => r.oid != groupOid).toList(),
      );
    }
    try {
      await _dio.delete('/roadmap/custom/$groupOid');
      if (!mounted) return false;
      return true;
    } on DioException catch (_) {
      if (!mounted) return false;
      // 실패 시 이전 상태로 복원
      if (current is CustomRoadmapLoaded) state = current;
      return false;
    } catch (_) {
      if (!mounted) return false;
      if (current is CustomRoadmapLoaded) state = current;
      return false;
    }
  }

  /// 상태를 초기화한다 (로그아웃 시 호출).
  void reset() {
    state = const CustomRoadmapInitial();
  }
}

final customRoadmapNotifierProvider =
    StateNotifierProvider<CustomRoadmapNotifier, CustomRoadmapState>((ref) {
  return CustomRoadmapNotifier(ref.watch(dioClientProvider));
});
