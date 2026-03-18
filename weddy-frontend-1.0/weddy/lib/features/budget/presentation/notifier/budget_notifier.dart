import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/api_response.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/budget/data/model/budget_model.dart';
import 'package:weddy/features/budget/data/model/budget_settings_model.dart';
import 'package:weddy/features/budget/data/model/budget_summary_model.dart';

// ---------------------------------------------------------------------------
// 예산 상태 sealed class
// ---------------------------------------------------------------------------

sealed class BudgetState {
  const BudgetState();
}

final class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

final class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

final class BudgetLoaded extends BudgetState {
  final List<BudgetModel> budgets;

  const BudgetLoaded(this.budgets);
}

final class BudgetError extends BudgetState {
  final String message;
  const BudgetError(this.message);
}

// ---------------------------------------------------------------------------
// BudgetNotifier
// ---------------------------------------------------------------------------

class BudgetNotifier extends StateNotifier<BudgetState> {
  final Dio _dio;

  BudgetNotifier(this._dio) : super(const BudgetInitial());

  /// 소유자의 전체 예산 목록을 서버에서 불러온다.
  /// 솔로/커플 모두 허용되므로 403 케이스는 발생하지 않는다.
  Future<void> loadBudgets() async {
    state = const BudgetLoading();
    try {
      final res = await _dio.get('/budgets');
      if (!mounted) return;
      final apiResp = ApiResponse<List<dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as List<dynamic>,
      );
      if (apiResp.success && apiResp.data != null) {
        final list = apiResp.data!
            .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
            .toList();
        state = BudgetLoaded(list);
      } else {
        state = BudgetError(apiResp.message);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? BudgetError((e.error as ApiException).message)
          : BudgetError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const BudgetError('예산을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 새 예산 카테고리를 생성한다.
  Future<void> createBudget(String category, int plannedAmount) async {
    try {
      await _dio.post('/budgets', data: {
        'category': category,
        'plannedAmount': plannedAmount,
      });
      if (!mounted) return;
      await loadBudgets();
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? BudgetError((e.error as ApiException).message)
          : BudgetError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const BudgetError('예산 생성 중 오류가 발생했습니다.');
    }
  }

  /// 예산 카테고리와 소속 항목을 삭제한다.
  Future<void> deleteBudget(String budgetOid) async {
    try {
      await _dio.delete('/budgets/$budgetOid');
      if (!mounted) return;
      await loadBudgets();
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? BudgetError((e.error as ApiException).message)
          : BudgetError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const BudgetError('예산 삭제 중 오류가 발생했습니다.');
    }
  }

  /// 예산 카테고리에 지출 항목을 추가한다.
  Future<void> addItem(
    String budgetOid,
    String title,
    int amount,
    String? memo,
    DateTime? paidAt,
  ) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'amount': amount,
        if (memo != null && memo.isNotEmpty) 'memo': memo,
        if (paidAt != null)
          'paidAt':
              '${paidAt.year.toString().padLeft(4, '0')}-${paidAt.month.toString().padLeft(2, '0')}-${paidAt.day.toString().padLeft(2, '0')}',
      };
      await _dio.post('/budgets/$budgetOid/items', data: body);
      if (!mounted) return;
      await loadBudgets();
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? BudgetError((e.error as ApiException).message)
          : BudgetError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const BudgetError('항목 추가 중 오류가 발생했습니다.');
    }
  }

  /// 예산 항목을 삭제한다.
  Future<void> deleteItem(String budgetOid, String itemOid) async {
    try {
      await _dio.delete('/budgets/$budgetOid/items/$itemOid');
      if (!mounted) return;
      await loadBudgets();
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? BudgetError((e.error as ApiException).message)
          : BudgetError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const BudgetError('항목 삭제 중 오류가 발생했습니다.');
    }
  }

  /// 전체 예산 설정을 저장(upsert)한다.
  /// 성공 시 true, 실패 시 false를 반환한다.
  Future<bool> upsertSettings(int totalAmount) async {
    try {
      await _dio.put('/budgets/settings', data: {'totalAmount': totalAmount});
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      final apiEx = e.error is ApiException
          ? e.error as ApiException
          : ApiException.fromDioException(e);
      state = BudgetError(apiEx.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const BudgetError('예산 설정 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 에러 상태를 초기화한다.
  void clearError() {
    if (state is BudgetError) state = const BudgetInitial();
  }

  /// 로그아웃 시 예산 상태를 초기화한다.
  void reset() {
    state = const BudgetInitial();
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier(ref.watch(dioClientProvider));
});

// ---------------------------------------------------------------------------
// 홈 화면용 예산 요약 Provider
// ---------------------------------------------------------------------------

/// 홈 화면에서 예산 요약 정보를 조회한다.
/// 솔로/커플 모두 정상 응답하며, 에러 시 null을 반환한다.
final budgetSummaryProvider =
    FutureProvider.autoDispose<BudgetSummaryModel?>((ref) async {
  final dio = ref.watch(dioClientProvider);
  try {
    final res = await dio.get('/budgets/summary');
    final apiResp = ApiResponse<Map<String, dynamic>>.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiResp.success || apiResp.data == null) return null;
    return BudgetSummaryModel.fromJson(apiResp.data!);
  } catch (_) {
    return null;
  }
});

// ---------------------------------------------------------------------------
// 전체 예산 설정 Provider
// ---------------------------------------------------------------------------

/// BudgetScreen 진입 시 전체 예산 설정 여부를 조회한다.
/// 에러 시 미설정 상태(BudgetSettingsModel())를 반환한다.
final budgetSettingsProvider =
    FutureProvider.autoDispose<BudgetSettingsModel>((ref) async {
  final dio = ref.watch(dioClientProvider);
  try {
    final res = await dio.get('/budgets/settings');
    final data = res.data as Map<String, dynamic>;
    if (data['success'] == true && data['data'] != null) {
      return BudgetSettingsModel.fromJson(
          data['data'] as Map<String, dynamic>);
    }
    return const BudgetSettingsModel();
  } catch (_) {
    return const BudgetSettingsModel();
  }
});
