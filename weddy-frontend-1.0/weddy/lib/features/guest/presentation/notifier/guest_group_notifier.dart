import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/guest/data/datasource/guest_remote_datasource.dart';
import 'package:weddy/features/guest/data/model/guest_group_model.dart';

// ---------------------------------------------------------------------------
// 하객 그룹 상태 sealed class
// ---------------------------------------------------------------------------

sealed class GuestGroupState {
  const GuestGroupState();
}

final class GuestGroupInitial extends GuestGroupState {
  const GuestGroupInitial();
}

final class GuestGroupLoading extends GuestGroupState {
  const GuestGroupLoading();
}

final class GuestGroupLoaded extends GuestGroupState {
  final List<GuestGroupModel> groups;
  const GuestGroupLoaded(this.groups);
}

final class GuestGroupError extends GuestGroupState {
  final String message;
  const GuestGroupError(this.message);
}

// ---------------------------------------------------------------------------
// GuestGroupNotifier
// ---------------------------------------------------------------------------

class GuestGroupNotifier extends StateNotifier<GuestGroupState> {
  final GuestRemoteDatasource _datasource;

  GuestGroupNotifier(this._datasource) : super(const GuestGroupInitial());

  /// 하객 그룹 목록을 불러온다.
  Future<void> loadGroups() async {
    state = const GuestGroupLoading();
    try {
      final groups = await _datasource.getGroups();
      if (!mounted) return;
      state = GuestGroupLoaded(groups);
    } on DioException catch (e) {
      if (!mounted) return;
      state = GuestGroupError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
    } catch (_) {
      if (!mounted) return;
      state = const GuestGroupError('하객 그룹 목록을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 하객 그룹을 생성한다.
  Future<bool> createGroup(String name) async {
    try {
      final created = await _datasource.createGroup(name);
      if (!mounted) return false;
      final current = state;
      if (current is GuestGroupLoaded) {
        state = GuestGroupLoaded([...current.groups, created]);
      }
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = GuestGroupError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const GuestGroupError('그룹 생성 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 하객 그룹명을 수정한다.
  Future<bool> updateGroup(String groupOid, String name) async {
    try {
      final updated = await _datasource.updateGroup(groupOid, name);
      if (!mounted) return false;
      final current = state;
      if (current is GuestGroupLoaded) {
        state = GuestGroupLoaded(
          current.groups
              .map((g) => g.oid == groupOid ? updated : g)
              .toList(),
        );
      }
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = GuestGroupError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const GuestGroupError('그룹 수정 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 하객 그룹을 삭제한다.
  Future<bool> deleteGroup(String groupOid) async {
    try {
      await _datasource.deleteGroup(groupOid);
      if (!mounted) return false;
      final current = state;
      if (current is GuestGroupLoaded) {
        state = GuestGroupLoaded(
          current.groups.where((g) => g.oid != groupOid).toList(),
        );
      }
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = GuestGroupError(
        e.error is ApiException
            ? (e.error as ApiException).message
            : ApiException.fromDioException(e).message,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = const GuestGroupError('그룹 삭제 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 상태를 초기화한다 (로그아웃 시 사용).
  void reset() => state = const GuestGroupInitial();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final guestGroupNotifierProvider =
    StateNotifierProvider<GuestGroupNotifier, GuestGroupState>((ref) {
  return GuestGroupNotifier(
    GuestRemoteDatasource(ref.read(dioClientProvider)),
  );
});
