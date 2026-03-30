# Lead Code Validator - Project Memory

## 프로젝트 핵심 컨벤션
- 응답 언어: 한국어
- DB PK: oid VARCHAR(14), OidGenerator로 @PrePersist 생성
- FK 없음 → INDEX만, 소유권 검증은 Service 레이어
- getOwnerOid() 패턴: 커플 연결 시 coupleOid, 미연결 시 userOid (공통)
- 공통 응답: ApiResponse<T> 래퍼 (success/message/data/errorCode)

## 시니어 개발자 에이전트의 반복 패턴 및 주의사항

### BE 패턴 (검증 완료)
- 매직 스트링 상수 관리: 동일 상수가 여러 메서드에 final String으로 중복 선언되는 경향 있음
  (예: ROADMAP_CATEGORY = "[로드맵] 결혼예산" — BudgetService 내 두 메서드에 반복)
- syncXxx() 메서드의 트랜잭션 전파: 내부 private 헬퍼는 호출자(@Transactional)에서 전파받음 — 명시 불필요
- deleteStep() 순서 위험: SANGGYEONRYE 전용 sourceOid(stepOid+"_SANG")와 일반 sourceOid(stepOid) 모두 삭제하지만,
  stepOid만으로 조회하면 SANGGYEONRYE 관련 일정은 누락 가능 (현재는 중복 deleteBySourceOid로 대응)
- 서비스 간 순환 참조 방지: RoadmapService → BudgetService (단방향), BudgetService → RoadmapService 없음 (안전)

### FE 패턴 (검증 완료)
- TextEditingController 누수: initState에서 생성한 동적 리스트 컨트롤러는 dispose()에서 반드시 해제
  (현재 구현은 올바름 - 각 항목 삭제 시 c.dispose() 인라인 호출)
- showDialog vs showModalBottomSheet: 투어 추가는 Dialog, 단계 상세는 ModalBottomSheet 패턴
- scaffoldContext 파라미터 전달: 모달 내 ScaffoldMessenger 접근용 부모 context 전달 (올바른 패턴)
- async gap 이전 캡처: _onSave/_onDelete에서 messenger/navigator를 await 이전에 캡처 (올바름)
- _buildDetails()의 int.tryParse: null 반환 가능 — BE에서 nullable 처리 필요

### 발견된 반복 문제 유형
1. 매직 스트링 상수 중복 (BE: private final String 지역 변수 반복)
2. 날짜 DatePicker lastDate 하드코딩 (DateTime(2030) — 갱신 필요)
3. SANGGYEONRYE 날짜 미입력 시 일정 미등록 (의도된 동작이나 사용자 피드백 없음)
4. DRESS 폼에서 잔금 납부일 초기화 버그 (dressBalanceDate == null이면 DatePicker에 오늘 날짜 기본값 표시)
5. [BE] countByOwnerOid() 범위 오용: 기본/직접 로드맵 단계 전체 합산 → 스코프별 카운트 쿼리 분리 필요
   - 기본 로드맵 20개 제한: countByOwnerOidAndGroupOidIsNull 사용
   - 직접 로드맵 sort_order: countByOwnerOidAndGroupOid 사용
6. [FE] 로그아웃 시 Notifier reset 누락: 새 도메인 Notifier 추가 시 반드시 logout()에 reset() 호출 추가
   → auth_notifier.dart finally 블록, 9단계에서 vendorNotifierProvider reset 누락 확인됨
7. [BE] boolean isFavorite Jackson 직렬화 키: boolean 원시 타입은 "favorite", Boolean 래퍼는 "isFavorite"로
   Jackson이 직렬화 → @JsonProperty로 키를 명시적으로 고정해야 버전업 시 silent break 방지
8. [FE] 상세 화면에서 detail notifier와 list notifier 양쪽에 토글 호출 시 이중 API 호출 버그
   → detail screen에서는 detailNotifier.toggleFavorite()만 호출, listNotifier.toggleFavorite()는 이중 호출 금지
9. [FE] 화면 색상 상수 중복: vendor_screen.dart / vendor_detail_screen.dart 동일 상수 선언 반복
   → lib/core/theme/app_colors.dart 공통 파일 추출 권고

## 아키텍처 결정 사항
- roadmap-budget 연동: "[로드맵] 결혼예산" 카테고리 자동 생성, budgetItems 배열로 계약금/잔금 매핑
- roadmap-schedule 연동: sourceType=ROADMAP/SANGGYEONRYE/HALL_TOUR, sourceOid로 연결
- SANGGYEONRYE 일정: sourceOid = stepOid + "_SANG" (stepOid 단독의 ROADMAP 일정과 충돌 방지)
- createStep: details='{}' 빈 JSON으로 생성, 이후 updateStep으로 세부 내용 저장
- 로드맵 아키텍처 (6.3단계, 2026-03-29): 기본 로드맵(group_oid=NULL) + 직접 로드맵(weddy_custom_roadmaps + group_oid 있는 단계)
  - 기본 로드맵 단계 20개 제한: countByOwnerOidAndGroupOidIsNull
  - 직접 로드맵 10개 제한: customRoadmapRepository.countByOwnerOid
  - 직접 로드맵 단계는 20개 제한 없음 (sortOrder만 그룹 내 카운트 기준)
- TabController 동적 재초기화: build() 중 직접 setState 금지, addPostFrameCallback으로 안전하게 처리 (확인됨)

## 리뷰 기준 우선순위
1. 버그/데이터 무결성 (Critical)
2. 보안 (IDOR, 입력 검증)
3. 트랜잭션 경계 및 데이터 일관성
4. 코드 중복 및 매직 스트링
5. UX 피드백 및 엣지 케이스
