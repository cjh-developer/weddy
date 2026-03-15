import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/api_response.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/auth/data/model/user_model.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';

// ---------------------------------------------------------------------------
// 결혼 예정일 설정 상태
// ---------------------------------------------------------------------------

sealed class WeddingSetupState {
  const WeddingSetupState();
}

final class WeddingSetupIdle extends WeddingSetupState {
  const WeddingSetupIdle();
}

final class WeddingSetupLoading extends WeddingSetupState {
  const WeddingSetupLoading();
}

final class WeddingSetupSuccess extends WeddingSetupState {
  final UserModel user;
  const WeddingSetupSuccess(this.user);
}

final class WeddingSetupError extends WeddingSetupState {
  final String message;
  const WeddingSetupError(this.message);
}

// ---------------------------------------------------------------------------
// WeddingSetupNotifier
// ---------------------------------------------------------------------------

class WeddingSetupNotifier extends StateNotifier<WeddingSetupState> {
  final Dio _dio;
  final Ref _ref;

  WeddingSetupNotifier(this._dio, this._ref) : super(const WeddingSetupIdle());

  /// 결혼 예정일을 서버에 저장하고 AuthNotifier의 UserModel을 갱신한다.
  Future<void> saveWeddingDate(DateTime date) async {
    state = const WeddingSetupLoading();
    try {
      final iso =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _dio.patch(
        '/users/me/wedding-date',
        data: {'weddingDate': iso},
      );
      final apiResp = ApiResponse<UserModel>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => UserModel.fromJson(data as Map<String, dynamic>),
      );
      if (apiResp.success && apiResp.data != null) {
        // AuthNotifier 상태를 최신 UserModel로 갱신하여 라우터 redirect 재평가를 트리거한다.
        await _ref.read(authNotifierProvider.notifier).refreshUser();
        state = WeddingSetupSuccess(apiResp.data!);
      } else {
        state = WeddingSetupError(apiResp.message.isNotEmpty ? apiResp.message : '저장에 실패했습니다.');
      }
    } on DioException catch (e) {
      if (e.error is ApiException) {
        state = WeddingSetupError((e.error as ApiException).message);
      } else {
        state = WeddingSetupError(ApiException.fromDioException(e).message);
      }
    } catch (_) {
      state = const WeddingSetupError('오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  void clearError() {
    if (state is WeddingSetupError) state = const WeddingSetupIdle();
  }
}

final weddingSetupProvider = StateNotifierProvider.autoDispose<
    WeddingSetupNotifier, WeddingSetupState>((ref) {
  final dio = ref.watch(dioClientProvider);
  return WeddingSetupNotifier(dio, ref);
});
