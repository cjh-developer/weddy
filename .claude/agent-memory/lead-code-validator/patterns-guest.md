# 하객 관리 (10단계) 패턴 및 이슈 기록

## 구현 현황 (2026-04-01 검토 완료)

### 스키마
- weddy_guest_groups: oid PK, owner_oid INDEX, name, is_default TINYINT(1), sort_order
- weddy_guests: oid PK, owner_oid INDEX, group_oid INDEX, attend/invitation INDEX 복합
- DROP 순서: weddy_guests → weddy_guest_groups (정상)

### ErrorCode
- GUEST_001: GUEST_GROUP_NOT_FOUND
- GUEST_002: GUEST_NOT_FOUND
- GUEST_003: GUEST_GROUP_DEFAULT_DELETE (삭제+수정 모두 이 코드 재사용 — 의미상 혼용이나 현재 허용)
- GUEST_004: GUEST_GROUP_LIMIT_EXCEEDED (최대 20개)
- GUEST_005: GUEST_LIMIT_EXCEEDED (최대 500명)

### GuestService 핵심 패턴
- getOwnerOid(): coupleRepository.findByGroomOidOrBrideOid() → 커플 OID or userOid
- deleteGroup(): clearGroupOid() 먼저 → 그룹 삭제 순서 정확
- getSummary(): companion_count + 1 기준 집계 (본인 포함)
- getGuests(): N+1 방지 — 그룹 목록 한 번 조회 후 Map으로 그룹명 매핑

### GuestController
- /summary 정적 경로가 /{guestOid} 가변 경로보다 먼저 선언됨 (Spring 라우팅 충돌 방지)
- @Validated 적용됨, PathVariable @Pattern 검증 적용됨
- sort @Pattern으로 허용값 제한: NAME_ASC|ATTEND_STATUS|INVITATION_STATUS|GIFT_HIGH|GIFT_LOW

### 수정된 버그
- [수정됨] GuestService.updateGuest(): `findById().ifPresent(g -> {})` 후 동일 findById() 중복 호출
  → 불필요한 첫 번째 호출 제거

### data.sql 주의사항
- weddy_guest_groups/weddy_guests INSERT가 DataInitializer의 커플(20000000000001)에 의존
- data.sql 단독 실행 시 앱 기동(DataInitializer) 선행 필요
- 주석으로 명시됨

## Flutter 구현 패턴

### GuestModel
- giftAmount: int (Dart int = 64bit, BE long 최대 9,999,999원 — 오버플로우 없음)
- fromJson: (json['giftAmount'] as num?)?.toInt() 패턴으로 안전 파싱
- clearGroup bool 파라미터: copyWith에서 nullable 그룹 OID 명시 해제 지원

### GuestSummaryModel
- totalGiftAmount: int (500명 × 9,999,999 ≈ 50억, Dart int 최대 9.2 × 10^18 — 안전)
- FutureProvider.autoDispose 패턴으로 화면 이탈 시 자동 해제

### GuestNotifier / GuestGroupNotifier
- deleteGuest(): 낙관적 삭제 — 실패 시 상태 복원 패턴
- deleteGroup() 후 탭 전환(전체 탭으로 복귀) + loadGuests() 재조회 순서 주의

### GuestScreen
- TabController 동적 재생성: _syncTabController() — 그룹 목록 변경 감지 후 dispose + 재생성
- [+] 탭 클릭 시 즉시 이전 탭으로 복원 후 대화상자 표시 (UX 개선)
- Dismissible: confirmDismiss → return false (낙관적 삭제는 notifier에서만 처리)

### GuestFormScreen
- 수정 모드 판별: widget.guestOid != null
- clearGroup 처리: _selectedGroupOid == null && _isEdit → body['clearGroup'] = true
- 저장 성공 후 Navigator.of(context).pop(true) → GuestScreen에서 invalidate + 재조회

### app_router.dart
- /guest → GuestScreen
- /guest/form?oid=... → GuestFormScreen (쿼리 파라미터로 guestOid 전달)

### auth_notifier.dart logout()
- guestGroupNotifierProvider.notifier.reset() 추가됨
- guestNotifierProvider.notifier.reset() 추가됨
