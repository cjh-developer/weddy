# Senior Dev Implementer Memory

## 프로젝트 패턴 (Weddy)

### Flutter CoupleNotifier 패턴
- `coupleNotifierProvider`: `StateNotifierProvider` (autoDispose 사용 금지 — 홈화면 이탈 시 상태 소멸 방지)
- `initState`에서 loadMyCouple()은 `CoupleInitial` 상태일 때만 호출 (중복 API 호출 방지)
- 404 → CoupleNotConnected (정상), 그 외 → CoupleError

### CoupleModel nullable 필드
- `brideOid: String?` — 미연결 상태에서 서버가 null 반환 가능 (크래시 방지)
- `brideName: String?` — 동일 이유

### D-DAY 계산 우선순위
- 커플 weddingDate 우선 → 개인 weddingDate fallback
- `_buildHeader`에서 `coupleState is CoupleConnected ? coupleState.couple.weddingDate : null` 패턴 사용

### DioException catch 순서 (반드시 준수)
```dart
on DioException catch (e) {
  if (e.response?.statusCode == 404) { ... }
  else if (e.error is ApiException) { state = CoupleError((e.error as ApiException).message); }
  else { state = CoupleError(ApiException.fromDioException(e).message); }
}
```

### test/widget_test.dart
- 기본 보일러플레이트 `MyApp` 참조 제거됨 (WeddyApp으로 클래스명 변경됨)
- placeholder 테스트로 교체 완료 — flutter analyze 통과
