import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/guest/data/datasource/guest_remote_datasource.dart';
import 'package:weddy/features/guest/data/model/guest_summary_model.dart';

/// 하객 집계 요약 Provider.
///
/// autoDispose: 화면이 dispose될 때 자동으로 상태를 해제한다.
/// 홈 화면 대시보드 및 GuestScreen 상단 요약 카드에서 사용한다.
/// API 오류 시 GuestSummaryModel.empty()를 반환하여 null 처리를 피한다.
final guestSummaryProvider =
    FutureProvider.autoDispose<GuestSummaryModel>((ref) async {
  final datasource = GuestRemoteDatasource(ref.read(dioClientProvider));
  try {
    return await datasource.getSummary();
  } catch (_) {
    return const GuestSummaryModel.empty();
  }
});
