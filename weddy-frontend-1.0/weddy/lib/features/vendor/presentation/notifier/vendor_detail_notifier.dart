import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/vendor/data/datasource/vendor_remote_datasource.dart';
import 'package:weddy/features/vendor/data/model/vendor_model.dart';

// ---------------------------------------------------------------------------
// 업체 상세 상태 sealed class
// ---------------------------------------------------------------------------

sealed class VendorDetailState {
  const VendorDetailState();
}

final class VendorDetailInitial extends VendorDetailState {
  const VendorDetailInitial();
}

final class VendorDetailLoading extends VendorDetailState {
  const VendorDetailLoading();
}

final class VendorDetailLoaded extends VendorDetailState {
  final VendorModel vendor;
  const VendorDetailLoaded(this.vendor);
}

final class VendorDetailError extends VendorDetailState {
  final String message;
  const VendorDetailError(this.message);
}

// ---------------------------------------------------------------------------
// VendorDetailNotifier
// ---------------------------------------------------------------------------

class VendorDetailNotifier extends StateNotifier<VendorDetailState> {
  final VendorRemoteDatasource _datasource;
  final String _vendorOid;

  VendorDetailNotifier(this._datasource, this._vendorOid)
      : super(const VendorDetailInitial()) {
    loadVendor();
  }

  Future<void> loadVendor() async {
    state = const VendorDetailLoading();
    try {
      final vendor = await _datasource.getVendor(_vendorOid);
      if (!mounted) return;
      state = VendorDetailLoaded(vendor);
    } on DioException catch (e) {
      if (!mounted) return;
      state = VendorDetailError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
    } catch (_) {
      if (!mounted) return;
      state = const VendorDetailError('업체 정보를 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 즐겨찾기 토글. 낙관적 업데이트 후 서버 동기화.
  Future<void> toggleFavorite() async {
    final current = state;
    if (current is! VendorDetailLoaded) return;
    final vendor = current.vendor;

    if (vendor.isFavorite) {
      // 낙관적 삭제
      state = VendorDetailLoaded(
        vendor.copyWith(isFavorite: false, favoriteOid: null),
      );
      try {
        if (vendor.favoriteOid != null) {
          await _datasource.removeFavorite(vendor.favoriteOid!);
        }
        if (!mounted) return;
        // 서버 동기화
        await loadVendor();
      } on DioException catch (e) {
        if (!mounted) return;
        state = current;
        state = VendorDetailError(
          e.error is ApiException
              ? (e.error as ApiException).message
              : ApiException.fromDioException(e).message,
        );
      } catch (_) {
        if (!mounted) return;
        state = current;
        state = const VendorDetailError('즐겨찾기 취소 중 오류가 발생했습니다.');
      }
    } else {
      // 낙관적 추가
      state = VendorDetailLoaded(vendor.copyWith(isFavorite: true));
      try {
        final result = await _datasource.addFavorite(vendor.oid);
        if (!mounted) return;
        final favoriteOid = result['favoriteOid'] as String?;
        state = VendorDetailLoaded(
          vendor.copyWith(isFavorite: true, favoriteOid: favoriteOid),
        );
      } on DioException catch (e) {
        if (!mounted) return;
        state = current;
        state = VendorDetailError(
          e.error is ApiException
              ? (e.error as ApiException).message
              : ApiException.fromDioException(e).message,
        );
      } catch (_) {
        if (!mounted) return;
        state = current;
        state = const VendorDetailError('즐겨찾기 추가 중 오류가 발생했습니다.');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Provider (autoDispose.family — vendorOid로 격리)
// ---------------------------------------------------------------------------

final vendorDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<VendorDetailNotifier, VendorDetailState, String>((ref, vendorOid) {
  return VendorDetailNotifier(
    VendorRemoteDatasource(ref.read(dioClientProvider)),
    vendorOid,
  );
});
