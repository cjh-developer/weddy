import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/api_response.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/couple/data/model/couple_model.dart';

// ---------------------------------------------------------------------------
// 커플 상태
// ---------------------------------------------------------------------------

sealed class CoupleState {
  const CoupleState();
}

final class CoupleInitial extends CoupleState {
  const CoupleInitial();
}

final class CoupleLoading extends CoupleState {
  const CoupleLoading();
}

final class CoupleConnected extends CoupleState {
  final CoupleModel couple;
  const CoupleConnected(this.couple);
}

final class CoupleNotConnected extends CoupleState {
  const CoupleNotConnected();
}

final class CoupleError extends CoupleState {
  final String message;
  const CoupleError(this.message);
}

// ---------------------------------------------------------------------------
// CoupleNotifier
// ---------------------------------------------------------------------------

class CoupleNotifier extends StateNotifier<CoupleState> {
  final Dio _dio;

  CoupleNotifier(this._dio) : super(const CoupleInitial());

  /// 내 커플 정보를 서버에서 불러온다.
  /// 404는 미연결 상태(정상), 그 외 오류는 CoupleError로 전환한다.
  Future<void> loadMyCouple() async {
    state = const CoupleLoading();
    try {
      // 404는 "커플 없음" 정상 케이스 → validateStatus로 허용하여 에러 인터셉터 우회
      final response = await _dio.get(
        '/couples/me',
        options: Options(validateStatus: (status) => status != null && status < 500),
      );
      if (!mounted) return;
      if (response.statusCode == 404) {
        state = const CoupleNotConnected();
        return;
      }
      final apiResp = ApiResponse<CoupleModel>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => CoupleModel.fromJson(data as Map<String, dynamic>),
      );
      state = (apiResp.success && apiResp.data != null)
          ? CoupleConnected(apiResp.data!)
          : const CoupleNotConnected();
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? CoupleError((e.error as ApiException).message)
          : CoupleError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const CoupleNotConnected();
    }
  }

  /// 파트너 초대코드를 입력하여 커플을 연결한다.
  Future<void> connectCouple(String partnerInviteCode) async {
    state = const CoupleLoading();
    try {
      final response = await _dio.post(
        '/couples/connect',
        data: {'partnerInviteCode': partnerInviteCode},
      );
      if (!mounted) return;
      final apiResp = ApiResponse<CoupleModel>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => CoupleModel.fromJson(data as Map<String, dynamic>),
      );
      state = (apiResp.success && apiResp.data != null)
          ? CoupleConnected(apiResp.data!)
          : CoupleError(apiResp.message);
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? CoupleError((e.error as ApiException).message)
          : CoupleError(ApiException.fromDioException(e).message);
    } catch (e) {
      if (!mounted) return;
      state = const CoupleError('연결 처리 중 오류가 발생했습니다.');
    }
  }

  /// 커플 연결을 해제한다.
  Future<void> disconnectCouple() async {
    state = const CoupleLoading();
    try {
      await _dio.delete('/couples/me');
      if (!mounted) return;
      state = const CoupleNotConnected();
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.error is ApiException) {
        state = CoupleError((e.error as ApiException).message);
      } else {
        state = CoupleError(ApiException.fromDioException(e).message);
      }
    } catch (e) {
      if (!mounted) return;
      state = const CoupleError('연결 처리 중 오류가 발생했습니다.');
    }
  }

  void clearError() {
    if (state is CoupleError) state = const CoupleNotConnected();
  }

  /// 로그아웃 시 커플 상태를 초기화한다.
  void reset() {
    state = const CoupleInitial();
  }
}

final coupleNotifierProvider =
    StateNotifierProvider<CoupleNotifier, CoupleState>((ref) {
  final dio = ref.watch(dioClientProvider);
  return CoupleNotifier(dio);
});
