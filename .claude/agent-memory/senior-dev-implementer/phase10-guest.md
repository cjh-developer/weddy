# Phase 10 — 하객 관리 구현 노트

## 구현 완료 시점
2026-04-01

## BE (이미 완성 상태로 시작)
- domain/guest/entity: Guest.java, GuestGroup.java
- domain/guest/repository: GuestGroupRepository, GuestRepository (clearGroupOid @Modifying)
- domain/guest/dto/request: CreateGuestGroupRequest, UpdateGuestGroupRequest, CreateGuestRequest, UpdateGuestRequest
- domain/guest/dto/response: GuestGroupResponse (@JsonProperty("isDefault") 필수), GuestResponse, GuestSummaryResponse
- domain/guest/service: GuestService (getOwnerOid 패턴, IDOR 3단계, 정렬 switch, 집계 companionCount+1)
- domain/guest/controller: GuestController (/api/v1/guests, /summary 경로는 /{guestOid} 보다 먼저 선언)
- scripts/schema.sql: weddy_guest_groups + weddy_guests 테이블 추가
- scripts/data.sql: 기본 그룹 5개(90000000000001~05) + 하객 5명(91000000000001~05) INSERT
- ErrorCode: GUEST_001~005 추가
- DataInitializer: createGuestGroups() + createGuests() 멱등 추가

## FE 구현 내용

### 이미 있었던 파일
- guest_group_model.dart (isDefault: json['isDefault'] as bool — @JsonProperty 대응)
- guest_model.dart (attendLabel/inviteLabel/totalCount getter, copyWith clearGroup 플래그)
- guest_summary_model.dart (GuestSummaryModel.empty() 팩토리)
- guest_remote_datasource.dart (9개 메서드)
- guest_group_notifier.dart (sealed state + load/create/update/delete/reset)
- guest_notifier.dart (sealed state + loadGuests/selectGroup/changeSort/create/update/delete/reset, 낙관적 삭제)
- guest_summary_notifier.dart (FutureProvider.autoDispose, 오류 시 empty() 반환)
- guest_form_screen.dart (추가/수정 통합 폼, glass 스타일)

### 신규 작성
- guest_screen.dart: GuestScreen (TabController 동적 재생성, 대시보드, 탭바+그룹 메뉴, 정렬칩, ListView Dismissible)

### 수정 파일
- app_router.dart: AppRoutes.guest='/guest', AppRoutes.guestForm='/guest/form' 추가
- home_screen.dart: 하객 메뉴(i==3) → context.push(AppRoutes.guest) 연결
- auth_notifier.dart: logout() finally에 guestGroupNotifierProvider.reset() + guestNotifierProvider.reset() 추가

## 주의사항
- TabController 동적 재생성: 그룹 목록이 바뀔 때 _syncTabController()로 재생성, _lastGroups로 변경 감지
- [+] 탭 클릭 처리: 탭 인덱스 == groups.length+1 일 때 이전 탭 복원 + showDialog
- GuestGroupResponse.isDefault: Jackson이 Lombok boolean getter를 "default"로 직렬화하는 문제를 @JsonProperty("isDefault")로 방지
- flutter analyze: guest_form_screen.dart에서 GuestModel import 제거 (unused)
- 불필요한 string interpolation braces 제거: '${man}만' → '$man만'
