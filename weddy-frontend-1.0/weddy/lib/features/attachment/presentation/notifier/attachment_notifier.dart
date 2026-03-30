import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/api_exception.dart';
import 'package:weddy/core/network/api_response.dart';
import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/attachment/data/model/attachment_model.dart';

// ---------------------------------------------------------------------------
// 첨부파일 상태 sealed class
// ---------------------------------------------------------------------------

sealed class AttachmentState {
  const AttachmentState();
}

final class AttachmentInitial extends AttachmentState {
  const AttachmentInitial();
}

final class AttachmentLoading extends AttachmentState {
  const AttachmentLoading();
}

final class AttachmentLoaded extends AttachmentState {
  final List<AttachmentModel> attachments;
  const AttachmentLoaded(this.attachments);
}

final class AttachmentUploading extends AttachmentState {
  final List<AttachmentModel> current;
  const AttachmentUploading(this.current);
}

final class AttachmentError extends AttachmentState {
  final String message;
  const AttachmentError(this.message);
}

// ---------------------------------------------------------------------------
// AttachmentNotifier
// ---------------------------------------------------------------------------

class AttachmentNotifier extends StateNotifier<AttachmentState> {
  final Dio _dio;
  final String refType;
  final String refOid;

  /// 마지막으로 확인된 정상 목록 — clearError() 상태 복원에 사용
  List<AttachmentModel> _lastKnownList = [];

  AttachmentNotifier(this._dio, this.refType, this.refOid)
      : super(const AttachmentInitial());

  /// 첨부파일 목록을 불러온다.
  Future<void> loadAttachments() async {
    state = const AttachmentLoading();
    try {
      final res = await _dio.get(
        '/attachments',
        queryParameters: {'refType': refType, 'refOid': refOid},
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
      if (!mounted) return;

      if (res.statusCode == 404) {
        state = const AttachmentLoaded([]);
        return;
      }

      final apiResp = ApiResponse<List<dynamic>>.fromJson(
        res.data as Map<String, dynamic>,
        (d) => d as List<dynamic>,
      );
      if (apiResp.success && apiResp.data != null) {
        final list = apiResp.data!
            .map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _lastKnownList = list;
        state = AttachmentLoaded(list);
      } else {
        state = AttachmentError(apiResp.message);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      state = e.error is ApiException
          ? AttachmentError((e.error as ApiException).message)
          : AttachmentError(ApiException.fromDioException(e).message);
    } catch (_) {
      if (!mounted) return;
      state = const AttachmentError('첨부파일을 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 파일을 업로드한다. 업로드 중에도 기존 목록이 표시된다.
  Future<bool> upload(String filePath, String fileName, String mimeType) async {
    final current = state is AttachmentLoaded
        ? (state as AttachmentLoaded).attachments
        : <AttachmentModel>[];
    state = AttachmentUploading(current);
    try {
      final formData = FormData.fromMap({
        'refType': refType,
        'refOid': refOid,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      await _dio.post('/attachments', data: formData);
      if (!mounted) return false;
      await loadAttachments();
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      final msg = e.error is ApiException
          ? (e.error as ApiException).message
          : ApiException.fromDioException(e).message;
      state = AttachmentLoaded(current);
      state = AttachmentError(msg);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = AttachmentLoaded(current);
      state = const AttachmentError('파일 업로드 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 첨부파일을 삭제한다 (낙관적).
  Future<bool> delete(String oid) async {
    final current = state;
    if (current is! AttachmentLoaded) return false;

    // 낙관적 삭제
    state = AttachmentLoaded(
      current.attachments.where((a) => a.oid != oid).toList(),
    );

    try {
      await _dio.delete('/attachments/$oid');
      if (!mounted) return false;
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = current;
      final msg = e.error is ApiException
          ? (e.error as ApiException).message
          : ApiException.fromDioException(e).message;
      state = AttachmentError(msg);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = current;
      state = const AttachmentError('파일 삭제 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 에러 상태를 마지막으로 알려진 목록으로 복원한다.
  void clearError() {
    if (state is AttachmentError) {
      state = AttachmentLoaded(_lastKnownList);
    }
  }
}

// ---------------------------------------------------------------------------
// Provider — refType + refOid 조합으로 autoDispose
// ---------------------------------------------------------------------------

final attachmentNotifierProvider = StateNotifierProvider.autoDispose
    .family<AttachmentNotifier, AttachmentState, (String, String)>(
  (ref, args) {
    return AttachmentNotifier(ref.watch(dioClientProvider), args.$1, args.$2);
  },
);
