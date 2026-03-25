# Security Advisor Memory - Weddy Project

## 핵심 보안 패턴 (확인됨)
- refreshToken 검증 순서: isTokenExpired 먼저 -> validateToken 나중 (UserService.refreshToken에서 올바르게 구현됨)
- JWT SecurityContext principal = userOid (String) - JwtAuthenticationFilter에서 설정
- 토큰 저장: flutter_secure_storage + EncryptedSharedPreferences(Android) + Keychain(iOS) - 올바르게 구현됨
- 401 강제 로그아웃: unauthorizedCallbackProvider -> AuthNotifier.logout() 연결 - 올바르게 구현됨
- GlobalExceptionHandler에서 스택트레이스 미노출 - 올바르게 구현됨
- BCrypt(cost=12) 적용 완료 (2026-03-12 패치) - Sha512PasswordEncoder.java 완전히 제거됨
- JWT Secret 폴백 제거 완료 (2026-03-12 패치) - ${JWT_SECRET} 환경변수 필수화, JwtTokenProvider에서 32자 미만 시 IllegalStateException
- RateLimitFilter 구현 완료 (2026-03-12 패치) - Bucket4j + Caffeine, 분당 10회, login/signup/refresh 적용
- CORS 명시적 오리진 완료 (2026-03-12 패치) - ${CORS_ALLOWED_ORIGINS} 환경변수 기반
- 사용자 열거 방지 완료 (2026-03-12 패치) - login()에서 user==null/password불일치 동일 UNAUTHORIZED 응답, 타이밍공격 방어

## 현재 미해결 취약점 (2026-03-20 일정/로드맵 기능 검토 후 갱신)

### HIGH
- RateLimitFilter IP 스푸핑: X-Forwarded-For 헤더 조작으로 Rate Limit 우회 가능
  - server.forward-headers-strategy: NATIVE 설정으로 완화됨 (주석에 명시됨)
  - 운영환경 인프라 레벨 제어 필요
- /api/v1/couples/connect Rate Limit 미적용 (2026-03-14 발견)
  - 초대 코드 브루트포스 방어 없음 - RateLimitFilter RATE_LIMITED_PATHS에 추가 필요
- Race Condition - 커플 중복 연결 (2026-03-14 발견)
  - weddy_couples.groom_oid, bride_oid에 UNIQUE 제약 없음
  - check-then-act 패턴 (existsBy + save) 비원자적 - 동시 요청 시 중복 레코드 생성 가능
- [신규] ChecklistService.updateItem() TOCTOU 패턴 (2026-03-15 발견)
  - findById(itemOid) 먼저 → validateItemOwnership() 나중: 타인 데이터가 먼저 메모리에 로드됨
  - findByOidAndChecklistOid() 단일 복합 쿼리로 교체 필요
- [신규] BudgetSummaryResponse 정수 오버플로우 위험 (2026-03-17 발견)
  - totalPlanned/totalSpent: long 타입이나 getSummary()에서 mapToLong().sum() 사용 시 Long.MAX_VALUE 초과 무결성 오염 가능
  - plannedAmount/amount에 @Max(9_999_999_999L) 상한 제약 추가 필요

### MEDIUM
- DataInitializer 약한 비밀번호 "1234" - @Profile("dev") 이므로 dev 환경 한정
- application-dev.yml DB 평문 자격증명: weddy/weddy01 하드코딩 (개발 환경 한정이므로 MEDIUM)
- application-dev.yml show-sql: true - 개발 환경 전용이나 운영 프로파일 실수 적용 위험
- Swagger UI 인증 없이 노출: PUBLIC_PATHS에 /swagger-ui/**, /v3/api-docs/** 포함 (운영 배포 전 조치 필요)
- SignUpRequest handPhone 형식 검증 없음: @Pattern(regexp="^01[016789]-?\\d{3,4}-?\\d{4}$") 미적용
- userId 허용문자 미제한: 영숫자+언더스코어 외 문자 허용 가능성
- UpdateWeddingDateRequest @Future/@FutureOrPresent 검증 없음 - 과거 날짜 허용
- ConnectCoupleRequest @Size(4-20)만 있고 @Pattern("^WED-[A-Z0-9]{6}$") 미적용
- CoupleResponse에 groomOid/brideOid 평문 노출 - IDOR 공격 시작점
- [신규] ChecklistResponse에 coupleOid 평문 노출 (2026-03-15 발견) - 응답 DTO에서 제거 필요
- [신규] ChecklistItemResponse에 checklistOid 평문 노출 (2026-03-15 발견) - 클라이언트 사용 여부 확인 후 제거 검토
- [신규] getHomePreview() limit 파라미터 방어 가드 없음 - limit <= 0 || limit > 20 시 기본값 3 사용
- [신규] CreateChecklistItemRequest.sortOrder, UpdateChecklistItemRequest.sortOrder 범위 검증 없음
  - @Min(0) @Max(9999) 추가 필요
- [신규] BudgetResponse에 coupleOid 평문 노출 (2026-03-17 발견) - 응답 DTO에서 제거 필요 (4단계 반복 패턴)
- [신규] BudgetItemResponse에 budgetOid 평문 노출 (2026-03-17 발견) - 응답 DTO에서 제거 검토
- [신규] CreateBudgetRequest.category @Pattern 미적용 (2026-03-17 발견) - XSS 페이로드 저장 가능 (체크리스트와 동일 패턴 반복)
- [신규] CreateBudgetItemRequest.title/memo @Pattern 미적용 (2026-03-17 발견) - 특수문자/스크립트 태그 허용
- [신규] 금액 필드(plannedAmount, amount) 상한값 미설정 (2026-03-17 발견) - 비정상 금액 + 정수 오버플로우 위험
  - @Max(9_999_999_999L) 또는 Long 래퍼 + @DecimalMax 추가 필요
- [신규] 커플당 예산 카테고리 최대 개수 제한 없음 (2026-03-17 발견) - 스토리지 DoS 가능 (체크리스트와 동일 패턴)
  - ErrorCode.BUDGET_LIMIT_EXCEEDED 추가 + countByCoupleOid 제한 필요
- [신규] 예산 카테고리 수정(PATCH) API 미구현 (2026-03-17 발견) - Budget.update() 메서드는 존재하나 컨트롤러 엔드포인트 없음 (보안 이슈 아님, INFO)
- [신규] paidAt 미래 날짜 제한 없음 (2026-03-17 발견) - 결제일에 수십 년 후 날짜 허용, @PastOrPresent 추가 검토

### LOW
- accessToken 만료시간 24시간(86400000ms): OWASP 권고 15-30분 대비 너무 김
- 도메인 정보 로그 노출: userId, userOid를 INFO 레벨로 로깅 (가명정보이나 운영 로그 관리 주의)
- DataInitializer 테스트 계정 OID 고정값(10000000000001 등): 순차적 예측 가능성 있음
- updateWeddingDate() 응답(UserResponse)에 inviteCode 포함 - 불필요한 노출
- 커플 연결 로그에 groomOid/brideOid 평문 기록 (CoupleService Line 98-99)
- [신규] 커플당 체크리스트 최대 개수 제한 없음 - 스토리지 DoS 가능 (2026-03-15 발견)
  - ErrorCode.CHECKLIST_LIMIT_EXCEEDED 추가 + countByCoupleOid 50개 제한
- [신규] CreateChecklistRequest.category 자유 문자열 허용 - XSS 페이로드 저장 가능 (2026-03-15)
  - @Pattern(regexp="^[가-힣a-zA-Z0-9\\s_\\-]{1,50}$") 추가 필요
- [신규] 커플당 예산 카테고리 최대 개수 제한 없음 - 스토리지 DoS 가능 (2026-03-17 발견) - 20개 제한 권고

### INFO (미해결, 백로그)
- .env 파일 gitignore 미적용 상태 미확인 (Flutter 쪽 재검토 필요)
- iOS Keychain accessibility: first_unlock -> after_first_unlock_this_device_only 권고
- 인증서 피닝 (Flutter - 운영 배포 전)
- 사용자 탈퇴 기능 구현 시 orphan couple 레코드 처리 정책 필요
- [신규] upsertSettings() 로그에 totalAmount 평문 기록 (2026-03-19 발견) - log.debug로 낮춤 권고
- [신규] BudgetSettings.updateTotalAmount() 파라미터 long primitive - null 전달 시 NPE (2026-03-19 발견) - Long 박싱 타입으로 전환 권고
- [신규 6단계] syncBudgetSettings()에서 details JSON totalBudget 값 상한 검증 없음 (2026-03-20 발견)
  - asLong()이 음수/0/Long.MAX_VALUE 반환 가능 - upsertSettingsInternal() 내 totalAmount < 1 방어가 있으나 Long.MAX_VALUE 등 비정상값 허용
  - CreateRoadmapStepRequest.details에 @Size(max=2000) 추가 + syncBudgetSettings()에서 totalBudget 범위 체크 필요
- [신규 6단계] HallTourResponse.totalMealCost 정수 오버플로우 위험 (2026-03-20 발견)
  - mealPrice(Long) * minGuests(Integer) 곱셈에서 오버플로우 미방어
  - rentalFee/mealPrice @Max(9_999_999_999L), minGuests @Max(10000) 추가 필요

## 보안 부채 항목 (2026-03-15 업데이트)
- [x] 비밀번호 해시 알고리즘 BCrypt(12) 마이그레이션 완료
- [x] Rate Limiting 구현 완료 (Bucket4j + Caffeine)
- [x] 운영환경 JWT Secret 환경변수 주입 강제화 완료
- [x] 운영환경 CORS 화이트리스트 구성 완료
- [ ] ChecklistService.updateItem() findByOidAndChecklistOid 단일 쿼리로 교체 (HIGH - 즉시)
- [ ] /api/v1/couples/connect Rate Limit 추가 (HIGH - 즉시)
- [ ] weddy_couples groom_oid/bride_oid UNIQUE 제약 추가 + DataIntegrityViolationException 핸들러 (HIGH - 즉시)
- [ ] 금액 필드 상한 @Max(9_999_999_999L) 추가 - CreateBudgetRequest.plannedAmount, CreateBudgetItemRequest.amount, UpdateBudgetItemRequest.amount (MEDIUM)
- [ ] BudgetResponse coupleOid 제거 (MEDIUM)
- [ ] BudgetItemResponse budgetOid 제거 검토 (MEDIUM)
- [ ] CreateBudgetRequest.category @Pattern 추가 (MEDIUM)
- [ ] CreateBudgetItemRequest.title/memo @Pattern 추가 (MEDIUM)
- [ ] paidAt @PastOrPresent 검토 (LOW)
- [ ] 커플당 예산 카테고리 20개 제한 + ErrorCode.BUDGET_LIMIT_EXCEEDED 추가 (LOW)
- [ ] ChecklistResponse coupleOid 제거 (MEDIUM)
- [ ] ChecklistItemResponse checklistOid 제거 검토 (MEDIUM)
- [ ] getHomePreview() limit 방어 가드 추가 (MEDIUM)
- [ ] sortOrder @Min(0) @Max(9999) 추가 - Create/UpdateChecklistItemRequest (MEDIUM)
- [ ] UpdateWeddingDateRequest @FutureOrPresent 추가 (MEDIUM)
- [ ] ConnectCoupleRequest @Pattern("^WED-[A-Z0-9]{6}$") 추가 (MEDIUM)
- [ ] CoupleResponse groomOid/brideOid 제거 여부 검토 (MEDIUM)
- [ ] DataInitializer @Profile("dev") 전환 완료 (확인 필요)
- [ ] Swagger UI 운영환경 비활성화 또는 인증 적용
- [ ] handPhone 입력 검증 패턴 추가
- [ ] 커플당 체크리스트 50개 제한 + ErrorCode.CHECKLIST_LIMIT_EXCEEDED 추가 (LOW)
- [ ] category 필드 허용 문자 패턴 제한 (LOW)
- [ ] accessToken 만료시간 단축 (24시간 → 15-30분)
- [ ] 인증서 피닝 (Flutter - 운영 배포 전)
- [x] GlobalExceptionHandler DataIntegrityViolationException 핸들러 COMMON_409로 교체 완료 (2026-03-19) - COUPLE_ALREADY_CONNECTED 고정 에러코드 제거, 범용 DUPLICATE_REQUEST 적용
- [x] upsertSettings() 로그 totalAmount 제거 완료 (2026-03-19)
- [x] BudgetSettings.updateTotalAmount() Long 박싱 타입으로 변경 + null/range 방어 추가 완료 (2026-03-19)
- [ ] CreateScheduleRequest.category @Pattern 추가 - 자유 문자열 허용 (MEDIUM, 6단계)
- [ ] CreateScheduleRequest.description @Size(max=1000) 추가 - 무제한 TEXT 입력 (MEDIUM, 6단계)
- [ ] CreateScheduleRequest.alertBefore 허용값 화이트리스트 검증 - @Pattern 추가 (LOW, 6단계)
- [ ] CreateRoadmapStepRequest.stepType @Pattern 추가 - 허용값 강제화 (MEDIUM, 6단계)
- [ ] CreateRoadmapStepRequest.details @Size(max=2000) 추가 (MEDIUM, 6단계)
- [ ] HallTour rentalFee/mealPrice @Max(9_999_999_999L) + minGuests @Max(10000) 추가 (MEDIUM, 6단계)
- [ ] syncBudgetSettings() totalBudget 범위 체크(1 이상 9_999_999_999L 이하) 추가 (MEDIUM, 6단계)
- [ ] CreateHallTourRequest.memo @Size(max=500) 추가 (LOW, 6단계)
- [ ] 소유자당 HallTour/TravelStop 최대 개수 제한 없음 - DoS 가능 (LOW, 6단계)

## 잘 구현된 패턴
- RefreshToken DB 저장 + 재발급 시 기존 토큰 무효화 (토큰 탈취 방어)
- OidGenerator SecureRandom 사용 - IDOR 예측 불가
- GlobalExceptionHandler 스택트레이스 미노출 (500 에러 메시지 일반화)
- flutter_secure_storage EncryptedSharedPreferences + Keychain 올바른 사용
- JPA 사용으로 SQL Injection 기본 방어
- BCrypt(cost=12) 비밀번호 해시 - 성능/보안 균형 적절
- 타이밍 공격 방지: 사용자 미존재 시에도 passwordEncoder.encode() 실행
- JwtTokenProvider 생성자에서 32자 미만 secret 즉시 실패 처리
- application.yml에서 JWT_SECRET 환경변수 폴백 없이 필수화
- RateLimitFilter @Order(1)로 SecurityFilterChain 앞에서 실행
- isTokenExpired -> validateToken 순서 올바르게 유지됨
- [3단계] @AuthenticationPrincipal userOid 일관 적용 - CoupleController, UserController 모두 정상
- [3단계] 자기 자신 초대코드 입력 방지 me.getOid().equals(partner.getOid()) 체크 구현됨
- [3단계] 파트너 기존 커플 연결 여부 양방향 검사 구현됨 (내 연결 + 파트너 연결 모두 체크)
- [3단계] User.generateInviteCode() static SecureRandom 재사용 (매번 new 생성 안함) - 올바름
- [3단계] SecurityConfig anyRequest().authenticated()로 커플/웨딩날짜 API 인증 자동 보호
- [4단계] 체크리스트 2단계 IDOR 방어: getCoupleOrThrow → validateChecklistOwnership → validateItemOwnership 계층적 소유권 검증 일관 적용
- [4단계] 체크리스트 deleteChecklist() 자식 항목 선삭제(deleteByChecklistOid) 후 부모 삭제 순서 올바름
- [4단계] ReadOnly 트랜잭션 조회 메서드(getChecklists, getHomePreview)에 일관 적용
- [5단계] 예산 소유권 검증 3단계 올바르게 구현: requireCoupleOid(SecurityContext) → validateBudgetOwnership(budgetOid+coupleOid) → validateItemOwnership(itemOid+budgetOid)
- [5단계] updateItem() 인메모리 소유권 검증 패턴 채택: findById 후 item.getBudgetOid().equals(budgetOid) 비교로 추가 DB 조회 없음 (체크리스트와 일관된 패턴)
- [5단계] deleteBudget() 자식 항목 선삭제(deleteByBudgetOid) 후 부모 삭제 순서 올바름
- [5단계] getSummary() N+1 방지: findAllByBudgetOidIn(budgetOids) 단일 IN 쿼리로 전체 항목 조회
- [5단계] @AuthenticationPrincipal userOid 일관 적용 - BudgetController 전 엔드포인트 정상
- [5단계] coupleOid를 요청 파라미터로 받지 않고 SecurityContext에서 추출 - 커플 연결 우회 공격 방어 올바름
- [5단계] getBudgets/getSummary에 @Transactional(readOnly = true) 올바르게 적용
- [5.5단계] BudgetSettingsResponse에 ownerOid/oid/createdAt/updatedAt 모두 제거 - 반복 지적 패턴 사전 방어 성공
- [5.5단계] UpsertBudgetSettingsRequest @NotNull+@Min(1)+@Max(9_999_999_999L) 3종 세트 올바르게 적용
- [5.5단계] getSettings()/upsertSettings() 모두 getOwnerOid() 패턴 일관 적용 - IDOR 구조적 차단
- [5.5단계] weddy_budget_settings.owner_oid UNIQUE KEY 선언 - Race Condition 시 데이터 중복 DB 레벨 차단
- [6단계] ScheduleService 소유권 검증 올바름: getOwnerOid() + existsByOidAndOwnerOid() 일관 적용
- [6단계] RoadmapService 소유권 검증 올바름: findByOidAndOwnerOid() 단일 복합 쿼리로 IDOR 방어 (5단계 updateItem 패턴 일관 적용)
- [6단계] deleteStep() 연쇄 삭제 순서 올바름: hallTour → travelStop → schedule → step
- [6단계] ScheduleResponse/RoadmapStepResponse에 ownerOid 미포함 - 반복 지적 사전 방어 성공
- [6단계] toggleDone() findByOidAndOwnerOid 단일 쿼리로 소유권 확인 동시 수행
- [6단계] createScheduleInternal() 내부 전용 메서드 - 외부 ownerOid 조작 불가 구조 (RoadmapService에서만 호출)

## 반복 패턴 경고 (이 프로젝트에서 자주 발생)
- Rate Limit 새 API 추가 시 RateLimitFilter.RATE_LIMITED_PATHS 업데이트 누락 위험 (3단계에서 발생)
  -> 새 민감 API(인증 관련, 반복 시도 가능 API) 추가 시 항상 RateLimitFilter 체크할 것
- FK 없는 아키텍처에서 check-then-act 패턴 사용 시 Race Condition 위험
  -> 데이터 유일성이 중요한 테이블은 DB UNIQUE 제약 필수 추가할 것
- 응답 DTO에 내부 관계 컬럼(coupleOid, groomOid, brideOid, checklistOid 등) 평문 노출 반복 발생
  -> API 목적에 맞는 전용 응답 DTO에서 내부 관계 컬럼 제거 필요 (3단계 CoupleResponse, 4단계 ChecklistResponse에서 반복됨)
- Service 내 복합 소유권 검증 시 findById 먼저 → validate 나중 순서 역전 위험
  -> updateItem() 패턴 참고: findById + validateOwnership 두 쿼리 → findByOidAndParentOid 단일 쿼리로 통일 권장

## 파일 위치 참조
- Backend: D:/workspace/weddy/weddy-backend-1.0/weddy
- Frontend: D:/workspace/weddy/weddy-frontend-1.0/weddy
- 핵심 보안 파일들:
  - JwtTokenProvider.java: common/security/ (Sha512PasswordEncoder.java 삭제됨)
  - JwtAuthenticationFilter.java: common/security/
  - RateLimitFilter.java: common/security/ (신규 추가됨)
  - SecurityConfig.java: common/security/
  - UserService.java: domain/user/service/
  - DataInitializer.java: common/init/
  - application.yml: src/main/resources/
  - application-dev.yml: src/main/resources/
  - token_storage.dart: lib/core/storage/
  - dio_client.dart: lib/core/network/
