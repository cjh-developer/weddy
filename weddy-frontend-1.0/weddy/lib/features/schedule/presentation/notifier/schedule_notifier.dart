import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/api_response.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/schedule/data/model/schedule_model.dart';

// ---------------------------------------------------------------------------
// 일정 상태 sealed class
// ---------------------------------------------------------------------------

sealed class ScheduleState {
  const ScheduleState();
}

final class ScheduleInitial extends ScheduleState {
  const ScheduleInitial();
}

final class ScheduleLoading extends ScheduleState {
  const ScheduleLoading();
}

final class ScheduleLoaded extends ScheduleState {
  final List<ScheduleModel> schedules;
  final int year;
  final int month;

  const ScheduleLoaded({
    required this.schedules,
    required this.year,
    required this.month,
  });
}

final class ScheduleError extends ScheduleState {
  final String message;
  const ScheduleError(this.message);
}

// ---------------------------------------------------------------------------
// ScheduleNotifier
// ---------------------------------------------------------------------------

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final Dio _dio;

  ScheduleNotifier(this._dio) : super(const ScheduleInitial());

  /// 현재 연/월 기준으로 일정 목록을 불러온다. (기본값: 현재 달)
  Future<void> loadSchedules({int? year, int? month}) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    state = const ScheduleLoading();
    try {
      final res = await _dio.get(
        '/schedules',
        queryParameters: {
          'year': targetYear,
          'month': targetMonth,
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (!mounted) return;

      // 404: 데이터 없음 → 빈 목록
      if (res.statusCode == 404) {
        state = ScheduleLoaded(
          schedules: const [],
          year: targetYear,
          month: targetMonth,
        );
        return;
      }

      final apiResp = ApiResponse<List<dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as List<dynamic>,
      );
      if (apiResp.success && apiResp.data != null) {
        final list = apiResp.data!
            .map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList();
        state = ScheduleLoaded(
          schedules: list,
          year: targetYear,
          month: targetMonth,
        );
      } else {
        state = ScheduleError(apiResp.message);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? ScheduleError((e.error as ApiException).message)
          : ScheduleError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const ScheduleError('일정을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 새 일정을 생성한다.
  Future<bool> createSchedule({
    required String title,
    required String category,
    required DateTime startAt,
    String? description,
    bool isAllDay = false,
    DateTime? endAt,
    String? location,
    String? alertBefore,
  }) async {
    try {
      String fmtDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      String fmtDateTime(DateTime d) =>
          '${fmtDate(d)}T'
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}:00';

      final body = <String, dynamic>{
        'title': title,
        'category': category,
        'isAllDay': isAllDay,
        'startAt': isAllDay ? fmtDate(startAt) : fmtDateTime(startAt),
        if (description != null && description.isNotEmpty)
          'description': description,
        if (endAt != null)
          'endAt': isAllDay ? fmtDate(endAt) : fmtDateTime(endAt),
        if (location != null && location.isNotEmpty) 'location': location,
        if (alertBefore != null && alertBefore.isNotEmpty)
          'alertBefore': alertBefore,
      };

      await _dio.post('/schedules', data: body);
      if (!mounted) return false;

      // 현재 조회 중인 연/월 기준으로 재조회
      final current = state;
      final year =
          current is ScheduleLoaded ? current.year : startAt.year;
      final month =
          current is ScheduleLoaded ? current.month : startAt.month;
      await loadSchedules(year: year, month: month);
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = e.error is ApiException
          ? ScheduleError((e.error as ApiException).message)
          : ScheduleError(ApiException.fromDioException(e).message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const ScheduleError('일정 생성 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 일정을 수정한다.
  Future<bool> updateSchedule(
    String oid, {
    String? title,
    String? category,
    String? description,
    bool? isAllDay,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    String? alertBefore,
  }) async {
    try {
      String fmtDate(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      String fmtDateTime(DateTime d) =>
          '${fmtDate(d)}T'
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}:00';

      final allDay = isAllDay ?? false;
      final body = <String, dynamic>{
        if (title != null) 'title': title,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (isAllDay != null) 'isAllDay': isAllDay,
        if (startAt != null)
          'startAt': allDay ? fmtDate(startAt) : fmtDateTime(startAt),
        if (endAt != null)
          'endAt': allDay ? fmtDate(endAt) : fmtDateTime(endAt),
        if (location != null) 'location': location,
        if (alertBefore != null) 'alertBefore': alertBefore,
      };

      await _dio.put('/schedules/$oid', data: body);
      if (!mounted) return false;

      final current = state;
      if (current is ScheduleLoaded) {
        await loadSchedules(year: current.year, month: current.month);
      }
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = e.error is ApiException
          ? ScheduleError((e.error as ApiException).message)
          : ScheduleError(ApiException.fromDioException(e).message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const ScheduleError('일정 수정 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 일정을 삭제한다.
  Future<bool> deleteSchedule(String oid) async {
    final current = state;
    // 낙관적 삭제
    if (current is ScheduleLoaded) {
      state = ScheduleLoaded(
        schedules:
            current.schedules.where((s) => s.oid != oid).toList(),
        year: current.year,
        month: current.month,
      );
    }

    try {
      await _dio.delete('/schedules/$oid');
      if (!mounted) return false;

      if (current is ScheduleLoaded) {
        await loadSchedules(
            year: current.year, month: current.month);
      }
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      // 실패 시 복원
      state = current;
      state = e.error is ApiException
          ? ScheduleError((e.error as ApiException).message)
          : ScheduleError(ApiException.fromDioException(e).message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = current;
      state = const ScheduleError('일정 삭제 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 날짜 범위(rangeStart ~ rangeEnd)에 포함된 모든 월의 일정을 병합하여 로드한다.
  /// 주별 뷰에서 사용하며, 월 경계에 걸친 주도 올바르게 처리한다.
  Future<void> loadSchedulesForRange(DateTime rangeStart, DateTime rangeEnd) async {
    state = const ScheduleLoading();
    try {
      final months = <({int year, int month})>[];
      var cur = DateTime(rangeStart.year, rangeStart.month);
      final endMonth = DateTime(rangeEnd.year, rangeEnd.month);
      while (!cur.isAfter(endMonth)) {
        months.add((year: cur.year, month: cur.month));
        cur = DateTime(cur.year, cur.month + 1);
      }

      final allSchedules = <ScheduleModel>[];
      for (final m in months) {
        if (!mounted) return;
        final res = await _dio.get(
          '/schedules',
          queryParameters: {'year': m.year, 'month': m.month},
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
        if (!mounted) return;
        if (res.statusCode == 404) continue;
        final apiResp = ApiResponse<List<dynamic>>.fromJson(
          res.data as Map<String, dynamic>,
          (d) => d as List<dynamic>,
        );
        if (apiResp.success && apiResp.data != null) {
          allSchedules.addAll(
            apiResp.data!.map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>)),
          );
        }
      }

      if (!mounted) return;
      state = ScheduleLoaded(
        schedules: allSchedules,
        year: rangeStart.year,
        month: rangeStart.month,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? ScheduleError((e.error as ApiException).message)
          : ScheduleError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const ScheduleError('일정을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 월을 변경하고 해당 월의 일정을 다시 조회한다.
  Future<void> changeMonth(int year, int month) async {
    await loadSchedules(year: year, month: month);
  }

  /// 에러 상태를 초기화한다.
  void clearError() {
    if (state is ScheduleError) state = const ScheduleInitial();
  }

  /// 로그아웃 시 상태를 초기화한다.
  void reset() {
    state = const ScheduleInitial();
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(ref.watch(dioClientProvider));
});
