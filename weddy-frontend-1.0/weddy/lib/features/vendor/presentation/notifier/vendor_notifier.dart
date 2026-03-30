import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/vendor/data/datasource/vendor_remote_datasource.dart';
import 'package:weddy/features/vendor/data/model/vendor_model.dart';

// ---------------------------------------------------------------------------
// 업체 목록 상태 sealed class
// ---------------------------------------------------------------------------

sealed class VendorState {
  const VendorState();
}

final class VendorInitial extends VendorState {
  const VendorInitial();
}

final class VendorLoading extends VendorState {
  const VendorLoading();
}

final class VendorLoaded extends VendorState {
  final List<VendorModel> vendors;
  final String? selectedCategory; // null = 전체
  final String keyword;
  final bool showingFavorites;

  const VendorLoaded(
    this.vendors, {
    this.selectedCategory,
    this.keyword = '',
    this.showingFavorites = false,
  });

  VendorLoaded copyWith({
    List<VendorModel>? vendors,
    String? Function()? selectedCategory,
    String? keyword,
    bool? showingFavorites,
  }) {
    return VendorLoaded(
      vendors ?? this.vendors,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      keyword: keyword ?? this.keyword,
      showingFavorites: showingFavorites ?? this.showingFavorites,
    );
  }
}

final class VendorError extends VendorState {
  final String message;
  const VendorError(this.message);
}

// ---------------------------------------------------------------------------
// VendorNotifier
// ---------------------------------------------------------------------------

class VendorNotifier extends StateNotifier<VendorState> {
  final VendorRemoteDatasource _datasource;

  VendorNotifier(this._datasource) : super(const VendorInitial());

  /// 업체 목록을 불러온다.
  Future<void> loadVendors({String? category, String? keyword}) async {
    state = const VendorLoading();
    try {
      final vendors = await _datasource.getVendors(
        category: category,
        keyword: keyword,
      );
      if (!mounted) return;
      state = VendorLoaded(
        vendors,
        selectedCategory: category,
        keyword: keyword ?? '',
        showingFavorites: false,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      state = VendorError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
    } catch (_) {
      if (!mounted) return;
      state = const VendorError('업체 목록을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 카테고리 필터 변경 후 재조회.
  Future<void> selectCategory(String? category) async {
    final current = state;
    final keyword = current is VendorLoaded ? current.keyword : '';
    await loadVendors(category: category, keyword: keyword.isEmpty ? null : keyword);
  }

  /// 키워드 검색 (현재 카테고리 유지).
  Future<void> search(String keyword) async {
    final current = state;
    final category = current is VendorLoaded ? current.selectedCategory : null;
    await loadVendors(
      category: category,
      keyword: keyword.isEmpty ? null : keyword,
    );
  }

  /// 상태를 초기화한다 (로그아웃 시 사용).
  void reset() => state = const VendorInitial();

  /// API 호출 없이 특정 벤더의 즐겨찾기 상태만 로컬 갱신한다.
  ///
  /// [VendorDetailScreen]에서 즐겨찾기 토글 성공 후 목록 상태를 동기화할 때 사용.
  /// 직접 API를 다시 호출하지 않으므로 이중 요청 버그를 방지한다.
  void updateFavoriteStatus(String vendorOid, bool isFavorite, String? favoriteOid) {
    final current = state;
    if (current is! VendorLoaded) return;

    final updated = current.vendors.map((v) {
      if (v.oid != vendorOid) return v;
      return v.copyWith(isFavorite: isFavorite, favoriteOid: favoriteOid);
    }).toList();

    // 즐겨찾기 목록 보기 중이고 즐겨찾기가 해제됐으면 목록에서 제거
    final filtered = (current.showingFavorites && !isFavorite)
        ? updated.where((v) => v.oid != vendorOid).toList()
        : updated;

    state = current.copyWith(vendors: filtered);
  }

  /// 즐겨찾기 목록만 표시.
  Future<void> loadFavorites() async {
    state = const VendorLoading();
    try {
      final vendors = await _datasource.getFavoriteVendors();
      if (!mounted) return;
      state = VendorLoaded(
        vendors,
        showingFavorites: true,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      state = VendorError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
    } catch (_) {
      if (!mounted) return;
      state = const VendorError('즐겨찾기 목록을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 즐겨찾기 토글 (목록 화면 낙관적 업데이트).
  /// 즐겨찾기 추가 시 API를 호출하고, 반환된 favoriteOid로 상태를 갱신한다.
  /// 즐겨찾기 삭제 시 favoriteOid로 API를 호출한다.
  Future<void> toggleFavorite(VendorModel vendor) async {
    final current = state;
    if (current is! VendorLoaded) return;

    if (vendor.isFavorite) {
      // 즐겨찾기 삭제 — favoriteOid가 없으면 API 호출 불가, 서버에서 조회 필요
      // 목록에서는 favoriteOid가 없으므로 낙관적으로 isFavorite=false로 변경 후
      // 서버에 removeFavorite 요청 (favoriteOid 없을 경우 addFavorite로 조회)
      final optimistic = current.vendors.map((v) {
        if (v.oid != vendor.oid) return v;
        return v.copyWith(isFavorite: false);
      }).toList();

      // 즐겨찾기 표시 중이면 목록에서 제거
      final updated = current.showingFavorites
          ? current.vendors.where((v) => v.oid != vendor.oid).toList()
          : optimistic;

      state = current.copyWith(vendors: updated);

      try {
        // favoriteOid가 있으면 직접 삭제, 없으면 서버 조회 없이 vendorOid로 조회 후 삭제
        if (vendor.favoriteOid != null) {
          await _datasource.removeFavorite(vendor.favoriteOid!);
        } else {
          // favoriteOid 없이 삭제하는 경우: 상세 조회로 favoriteOid 취득 후 삭제
          final detail = await _datasource.getVendor(vendor.oid);
          if (detail.favoriteOid != null) {
            await _datasource.removeFavorite(detail.favoriteOid!);
          }
        }
      } on DioException catch (e) {
        if (!mounted) return;
        // 실패 시 복원
        state = current;
        state = VendorError(
          e.error is ApiException
              ? (e.error as ApiException).message
              : ApiException.fromDioException(e).message,
        );
      } catch (_) {
        if (!mounted) return;
        state = current;
        state = const VendorError('즐겨찾기 변경 중 오류가 발생했습니다.');
      }
    } else {
      // 즐겨찾기 추가 — 낙관적으로 isFavorite=true 처리
      final optimistic = current.vendors.map((v) {
        if (v.oid != vendor.oid) return v;
        return v.copyWith(isFavorite: true);
      }).toList();
      state = current.copyWith(vendors: optimistic);

      try {
        final result = await _datasource.addFavorite(vendor.oid);
        if (!mounted) return;
        final favoriteOid = result['favoriteOid'] as String?;
        // favoriteOid를 상태에 반영
        final withFavOid = (state as VendorLoaded).vendors.map((v) {
          if (v.oid != vendor.oid) return v;
          return v.copyWith(isFavorite: true, favoriteOid: favoriteOid);
        }).toList();
        state = (state as VendorLoaded).copyWith(vendors: withFavOid);
      } on DioException catch (e) {
        if (!mounted) return;
        state = current;
        state = VendorError(
          e.error is ApiException
              ? (e.error as ApiException).message
              : ApiException.fromDioException(e).message,
        );
      } catch (_) {
        if (!mounted) return;
        state = current;
        state = const VendorError('즐겨찾기 추가 중 오류가 발생했습니다.');
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final vendorNotifierProvider =
    StateNotifierProvider<VendorNotifier, VendorState>((ref) {
  return VendorNotifier(
    VendorRemoteDatasource(ref.read(dioClientProvider)),
  );
});
