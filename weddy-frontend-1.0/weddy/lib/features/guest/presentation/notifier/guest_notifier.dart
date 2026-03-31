import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/guest/data/datasource/guest_remote_datasource.dart';
import 'package:weddy/features/guest/data/model/guest_model.dart';

// ---------------------------------------------------------------------------
// 하객 목록 상태 sealed class
// ---------------------------------------------------------------------------

sealed class GuestState {
  const GuestState();
}

final class GuestInitial extends GuestState {
  const GuestInitial();
}

final class GuestLoading extends GuestState {
  const GuestLoading();
}

final class GuestLoaded extends GuestState {
  final List<GuestModel> guests;
  final String? selectedGroupOid;
  final String sort;

  const GuestLoaded(
    this.guests, {
    this.selectedGroupOid,
    this.sort = 'NAME_ASC',
  });

  GuestLoaded copyWith({
    List<GuestModel>? guests,
    String? Function()? selectedGroupOid,
    String? sort,
  }) {
    return GuestLoaded(
      guests ?? this.guests,
      selectedGroupOid: selectedGroupOid != null
          ? selectedGroupOid()
          : this.selectedGroupOid,
      sort: sort ?? this.sort,
    );
  }
}

final class GuestError extends GuestState {
  final String message;
  const GuestError(this.message);
}

// ---------------------------------------------------------------------------
// GuestNotifier
// ---------------------------------------------------------------------------

class GuestNotifier extends StateNotifier<GuestState> {
  final GuestRemoteDatasource _datasource;

  GuestNotifier(this._datasource) : super(const GuestInitial());

  /// 하객 목록을 불러온다.
  Future<void> loadGuests({String? groupOid, String sort = 'NAME_ASC'}) async {
    state = const GuestLoading();
    try {
      final guests = await _datasource.getGuests(
        groupOid: groupOid,
        sort: sort,
      );
      if (!mounted) return;
      state = GuestLoaded(
        guests,
        selectedGroupOid: groupOid,
        sort: sort,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      state = GuestError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
    } catch (_) {
      if (!mounted) return;
      state = const GuestError('하객 목록을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 그룹 필터 변경 후 재조회.
  Future<void> selectGroup(String? groupOid) async {
    final current = state;
    final sort = current is GuestLoaded ? current.sort : 'NAME_ASC';
    await loadGuests(groupOid: groupOid, sort: sort);
  }

  /// 정렬 기준 변경 후 재조회.
  Future<void> changeSort(String sort) async {
    final current = state;
    final groupOid = current is GuestLoaded ? current.selectedGroupOid : null;
    await loadGuests(groupOid: groupOid, sort: sort);
  }

  /// 하객을 추가한다.
  Future<bool> createGuest(Map<String, dynamic> body) async {
    try {
      final created = await _datasource.createGuest(body);
      if (!mounted) return false;
      final current = state;
      if (current is GuestLoaded) {
        state = current.copyWith(guests: [...current.guests, created]);
      }
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = GuestError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const GuestError('하객 추가 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 하객 정보를 수정한다.
  Future<bool> updateGuest(String guestOid, Map<String, dynamic> body) async {
    try {
      final updated = await _datasource.updateGuest(guestOid, body);
      if (!mounted) return false;
      final current = state;
      if (current is GuestLoaded) {
        state = current.copyWith(
          guests: current.guests
              .map((g) => g.oid == guestOid ? updated : g)
              .toList(),
        );
      }
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = GuestError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const GuestError('하객 수정 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 하객을 삭제한다 (낙관적 업데이트).
  Future<bool> deleteGuest(String guestOid) async {
    final current = state;
    if (current is! GuestLoaded) return false;

    // 낙관적 삭제
    state = current.copyWith(
      guests: current.guests.where((g) => g.oid != guestOid).toList(),
    );

    try {
      await _datasource.deleteGuest(guestOid);
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      // 실패 시 복원
      state = current;
      state = GuestError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = current;
      state = const GuestError('하객 삭제 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 상태를 초기화한다 (로그아웃 시 사용).
  void reset() => state = const GuestInitial();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final guestNotifierProvider =
    StateNotifierProvider<GuestNotifier, GuestState>((ref) {
  return GuestNotifier(
    GuestRemoteDatasource(ref.read(dioClientProvider)),
  );
});
