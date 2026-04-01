import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:weddy/core/network/dio_client.dart';
import 'package:weddy/features/auth/domain/model/auth_state.dart';
import 'package:weddy/features/auth/presentation/notifier/auth_notifier.dart';
import 'package:weddy/features/guest/data/datasource/guest_remote_datasource.dart';
import 'package:weddy/features/guest/data/model/guest_summary_model.dart';

/// 하객 집계 요약 Provider.
///
/// autoDispose: 화면이 dispose될 때 자동으로 상태를 해제한다.
///
/// [주의] authNotifierProvider를 ref.watch하여 인증 상태가 변경되면
/// 즉시 재실행된다. 비인증 상태에서는 API를 호출하지 않고 빈 데이터를 반환한다.
/// → 401 수신 시 onUnauthorized → logout → 재실행 → 401 무한루프 방지
final guestSummaryProvider =
    FutureProvider.autoDispose<GuestSummaryModel>((ref) async {
  // 비인증 상태에서 API 호출 금지 — 401 → logout → 재실행 무한루프 방지
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) {
    return const GuestSummaryModel.empty();
  }

  final datasource = GuestRemoteDatasource(ref.read(dioClientProvider));
  try {
    return await datasource.getSummary();
  } catch (_) {
    return const GuestSummaryModel.empty();
  }
});
