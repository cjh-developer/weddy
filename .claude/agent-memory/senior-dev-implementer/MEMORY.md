# Weddy Project Memory

---

## Backend (Spring Boot)

### Project Location
- Root: D:\workspace\weddy\weddy-backend-1.0\weddy
- Package: com.project.weddy
- Stack: Spring Boot 3.2.3, Java 17, Gradle, MySQL

### Database Rules
- Table prefix: weddy_
- PK: oid VARCHAR(14), server-generated 14-digit numeric string (NO auto-increment)
- OidGenerator: com.project.weddy.common.util.OidGenerator (SecureRandom, first digit 1-9)
- Field names: user_id (login), name, hand_phone, email

### Common Infrastructure (implemented)
- com.project.weddy.common.util.OidGenerator
- com.project.weddy.common.response.ApiResponse<T>
- com.project.weddy.common.response.PageResponse<T>
- com.project.weddy.common.exception.ErrorCode (enum)
- com.project.weddy.common.exception.CustomException
- com.project.weddy.common.exception.GlobalExceptionHandler
- com.project.weddy.common.security.JwtTokenProvider (jjwt 0.12.3)
- com.project.weddy.common.security.JwtAuthenticationFilter
- com.project.weddy.common.security.SecurityConfig (Stateless, BCrypt)
- com.project.weddy.common.security.RateLimitFilter (bucket4j + caffeine, IP 기반, /auth/** 적용)
- com.project.weddy.common.init.DataInitializer (@Profile("!test"), CommandLineRunner)

### Password Encoding
- Algorithm: BCryptPasswordEncoder(cost=12)
- Bean: PasswordEncoder (single bean, no Sha512PasswordEncoder)
- UserService injects PasswordEncoder interface
- signup(): passwordEncoder.encode(request.getPassword())
- login(): user=orElse(null), null이면 dummy encode 후 UNAUTHORIZED (사용자 열거 방지)
- DataInitializer auto-creates test accounts on startup (idempotent via existsByUserId check)

### Security Patches Applied
- BCrypt(12) 복귀: Sha512PasswordEncoder.java 삭제
- JWT Secret 폴백 제거: application.yml에서 하드코딩 폴백 모두 제거 (${JWT_SECRET} only)
- JwtTokenProvider: 생성자에 secret.length() < 32 검증 추가
- application-dev.yml: .gitignore에 등록, 개발용 자격증명 분리
- CORS: cors.allowed-origins 설정 기반, 와일드카드 제거
- Rate Limiting: bucket4j-core:8.10.1, caffeine:3.1.8, RateLimitFilter @Order(1)
- ErrorCode: RATE_LIMIT_EXCEEDED("COMMON_429") 추가
- IDOR 차단: CoupleResponse에서 groomOid/brideOid 제거 (coupleOid만 유지)
- SignUpRequest handPhone @Pattern: ^01[016789]-?\\d{3,4}-?\\d{4}$
- Swagger 비활성화: application.yml springdoc.api-docs.enabled=false (dev yml에서만 true)
- disconnectCouple: 연관 데이터 JdbcTemplate 직접 삭제 (체크리스트→항목, 예산→항목, 즐겨찾기 순)
- 로그인 로그 마스킹: maskUserId() — 앞 3자리 + * repeat

### JWT Config
- jwt.secret / jwt.expiration=86400000 / jwt.refresh-expiration=604800000
- Public paths: /api/v1/auth/**, /swagger-ui/**, /v3/api-docs/**

### Dependencies Added
- jjwt-api/impl/jackson:0.12.3
- spring-boot-starter-validation
- springdoc-openapi-starter-webmvc-ui:2.3.0

### SQL Scripts
- scripts/schema.sql - uses SET FOREIGN_KEY_CHECKS=0 + DROP TABLE IF EXISTS (safe order)
- scripts/data.sql - uses SET FOREIGN_KEY_CHECKS=0 + DELETE (safe order), vendors only
- Users inserted by DataInitializer at runtime (not data.sql)
- spring.jpa.hibernate.ddl-auto=validate

---

## Frontend (Flutter)

### Project Overview
- Path: D:\workspace\weddy\weddy-frontend-1.0\weddy
- Flutter (Dart ^3.5.4), Riverpod, Dio, flutter_secure_storage

## Tech Stack
- State: flutter_riverpod ^2.5.1, riverpod_annotation ^2.3.5
- Network: dio ^5.4.3+1
- Auth Storage: flutter_secure_storage ^9.2.2
- Navigation: go_router ^14.2.7
- Env: flutter_dotenv ^5.2.1
- Code Gen: riverpod_generator ^2.4.0, build_runner ^2.4.9

## Core Architecture (implemented)
- lib/core/network/api_response.dart    - Generic ApiResponse<T> matching Spring Boot
- lib/core/network/page_response.dart  - PageResponse<T> for pagination
- lib/core/network/api_exception.dart  - ApiException + ErrorCode constants
- lib/core/network/dio_client.dart     - Dio setup + dotenv baseUrl + Riverpod providers
- lib/core/storage/token_storage.dart  - JWT token secure storage

## Key Decisions
- baseUrl from dotenv: dotenv.env['API_BASE_URL'] fallback 'http://10.0.2.2:8080/api/v1'
- FLAVOR=production → .env.production, else .env (loaded in main() before runApp)
- .env / .env.* in .gitignore (except .env.example)
- assets: .env, .env.production, .env.example, assets/images/ in pubspec.yaml
- Logo: assets/images/logo.jpg (copied from D:\workspace\weddy\images\default.jpg)
- Theme: Pink (seedColor 0xFFEC4899), scaffoldBg 0xFFFDF2F8 (3단계부터 전환)
- TokenStorage uses EncryptedSharedPreferences on Android
- DioException always converted to ApiException in ErrorInterceptor
- 401 response auto-clears tokens (screen nav handled by router layer)
- Logging via dart:developer (not print) for structured log output

## Providers
- tokenStorageProvider: Provider<TokenStorage>
- dioClientProvider: Provider<Dio>
- authRepositoryProvider: Provider<AuthRepository>
- authNotifierProvider: StateNotifierProvider<AuthNotifier, AuthState>
- routerProvider: Provider<GoRouter>

## Auth Feature (implemented)
- lib/features/auth/data/model/auth_response.dart     - AuthResponse DTO
- lib/features/auth/data/model/user_model.dart        - UserModel DTO
- lib/features/auth/data/model/sign_up_request.dart   - SignUpRequest DTO
- lib/features/auth/data/datasource/auth_remote_datasource.dart
- lib/features/auth/data/repository/auth_repository_impl.dart
- lib/features/auth/domain/repository/auth_repository.dart  - abstract interface
- lib/features/auth/domain/model/auth_state.dart      - sealed AuthState
- lib/features/auth/presentation/notifier/auth_notifier.dart
- lib/features/auth/presentation/screen/login_screen.dart
- lib/features/auth/presentation/screen/sign_up_screen.dart
- lib/core/router/app_router.dart  - GoRouter + AppRoutes + _AuthStateListenable (HomeScreen 연결 완료)

## Home Feature (implemented)
- lib/features/home/presentation/screen/home_screen.dart
  - 6개 섹션: AppBar(SliverAppBar), 초대 섹션, 진행률, 메뉴 그리드(3x2), 추천 업체(탭바), 사랑순위
  - 전체 정적 목업 데이터
  - _VendorSection: StatefulWidget (탭 상태 관리)
  - _MenuItemTile: StatefulWidget (press 애니메이션)
  - _HomePinkButton: StatefulWidget (hover/press 효과)

## Checklist Feature (implemented — 4단계)
### BE
- domain/checklist/entity: Checklist.java, ChecklistItem.java
- domain/checklist/repository: ChecklistRepository, ChecklistItemRepository
- domain/checklist/dto/request: CreateChecklistRequest, CreateChecklistItemRequest, UpdateChecklistItemRequest
- domain/checklist/dto/response: ChecklistResponse, ChecklistItemResponse
- domain/checklist/service: ChecklistService (COUPLE_NOT_FOUND guard, IDOR validation)
- domain/checklist/controller: ChecklistController (/api/v1/checklists)
- ErrorCode: CHECKLIST_NOT_FOUND("CHECKLIST_001"), CHECKLIST_ITEM_NOT_FOUND("CHECKLIST_002")
- ChecklistItemRepository.findRecentUndoneItems: JPQL LIMIT (Spring Data JPA 3.x 지원)
### FE
- lib/features/checklist/data/model: ChecklistModel, ChecklistItemModel
- lib/features/checklist/presentation/notifier/checklist_notifier.dart
  - sealed ChecklistState (Initial/Loading/Loaded/Error)
  - toggleItem: 낙관적 업데이트 후 서버 동기화
  - checklistPreviewProvider: FutureProvider.autoDispose, 404→빈 리스트
- lib/features/checklist/presentation/screen/checklist_screen.dart
  - Dark Glass 테마, Dismissible 스와이프 삭제, AnimatedCrossFade 펼침/접기
- AppRoutes.checklist = '/checklist' 추가
- home_screen.dart: _buildChecklistSection → checklistPreviewProvider 연동

## Budget Feature (implemented — 5단계, 솔로 허용 패치 완료)
### BE
- domain/budget/entity: Budget.java (owner_oid, category, planned_amount), BudgetItem.java (budget_oid, title, amount, memo, paid_at)
- domain/budget/repository: BudgetRepository (findByOwnerOid, existsByOidAndOwnerOid, countByOwnerOid), BudgetItemRepository (JPA)
- domain/budget/dto/request: CreateBudgetRequest, CreateBudgetItemRequest, UpdateBudgetItemRequest
- domain/budget/dto/response: BudgetItemResponse, BudgetResponse (spentAmount/remainingAmount 인메모리 계산), BudgetSummaryResponse
- domain/budget/service: BudgetService (getOwnerOid() 패턴 — 체크리스트와 동일, IDOR 3단계 검증)
  - getOwnerOid(): 커플 연결 시 coupleOid, 솔로 시 userOid 반환
- domain/budget/entity: BudgetSettings.java (oid PK, owner_oid UNIQUE, total_amount)
- domain/budget/repository: BudgetSettingsRepository (findByOwnerOid)
- domain/budget/dto/request: UpsertBudgetSettingsRequest (@Min(1), @Max(9_999_999_999L))
- domain/budget/dto/response: BudgetSettingsResponse (totalBudget nullable, notConfigured() 팩토리)
- domain/budget/controller: BudgetController (/api/v1/budgets) — 9개 엔드포인트
  - GET /api/v1/budgets — 전체 목록 + 항목
  - POST /api/v1/budgets — 예산 카테고리 생성
  - DELETE /api/v1/budgets/{oid} — 삭제 (항목 포함)
  - POST /api/v1/budgets/{oid}/items — 항목 추가
  - PATCH /api/v1/budgets/{oid}/items/{itemOid} — 항목 수정 (null=기존값 유지)
  - DELETE /api/v1/budgets/{oid}/items/{itemOid} — 항목 삭제
  - GET /api/v1/budgets/settings — 전체 예산 설정 조회 (미설정 시 totalBudget=null)
  - PUT /api/v1/budgets/settings — 전체 예산 설정 저장 (upsert)
  - GET /api/v1/budgets/summary — 홈 화면용 요약 (totalPlanned, totalSpent, usageRate, totalBudget)
- BudgetSummaryResponse.totalBudget 추가: usageRate 분모 = totalBudget(설정 시) or totalPlanned
- ErrorCode: BUDGET_COUPLE_REQUIRED("BUDGET_003") — 미사용이나 하위 호환성 위해 enum 유지
- schema.sql: weddy_budgets.couple_oid → owner_oid (INDEX idx_owner)
- schema.sql: weddy_budget_settings 테이블 추가 (owner_oid UNIQUE)
- DataInitializer: createBudgetSettings() 추가 — ownerOid=20000000000001, 5천만원 (oid=50000000000001)
### FE
- lib/features/budget/data/model: BudgetItemModel, BudgetModel (usageRatio getter)
- BudgetSummaryModel: totalBudget(nullable), isOver getter, overRate getter 추가
- BudgetSettingsModel: lib/features/budget/data/model/budget_settings_model.dart (isConfigured getter)
- lib/features/budget/presentation/notifier/budget_notifier.dart
  - sealed BudgetState (Initial/Loading/Loaded/Error)
  - upsertSettings(int totalAmount) → Future<bool> 추가
  - budgetSummaryProvider: FutureProvider.autoDispose<BudgetSummaryModel?>, 에러→null
  - budgetSettingsProvider: FutureProvider.autoDispose<BudgetSettingsModel>, 에러→BudgetSettingsModel()
- lib/features/budget/presentation/screen/budget_screen.dart
  - _BudgetScreenState: _setupAmountCtrl (TextEditingController) — initState/dispose 관리
  - _buildBody(): settingsAsync.when() → !isConfigured이면 _buildTotalBudgetSetupScreen()
  - _buildTotalBudgetSetupScreen(): 전체 예산 최초 설정 화면 (SingleChildScrollView)
  - _buildSummaryCard(budgets, settings): 전체 예산 행 + 편집 아이콘(edit_outlined) 표시
  - _showEditTotalBudgetDialog(): 전체 예산 수정 다이얼로그, 성공 시 ref.invalidate(budgetSettingsProvider)
  - 초과율 표시: isOver ? '${초과%}% 초과' : '${사용률}%', 초과 시 _kUrgent
- home_screen.dart: _BudgetSummaryCard
  - totalBudget != null이면 '전체 예산' 표시, 없으면 '총 계획'
  - summary.isOver ? '${overRate}% 초과' 빨간색 : '${usageRate}%'
- AppRoutes.budget = '/budget' 추가
- home_screen.dart: _buildBudgetSection → budgetSummaryProvider 연동, _BudgetSummaryCard 위젯
- home_screen.dart: summary==null 시 "첫 예산 카테고리를 추가해보세요" 카드 (→ /budget)
- home_screen.dart: 메뉴 그리드 인덱스 1(예산) → context.push(AppRoutes.budget)

## 구현 완료 (6단계 — 일정 관리 & 웨딩 관리, 2026-03-20)
→ 상세: phase6-schedule-roadmap.md
- [BE] weddy_schedules, weddy_roadmap_steps, weddy_roadmap_hall_tours, weddy_roadmap_travel_stops 테이블
- [BE] ScheduleService, ScheduleController (/api/v1/schedules — GET?year&month, POST, PUT, DELETE)
- [BE] RoadmapService (BUDGET단계↔예산설정 동기화, 투어↔일정 자동등록/연쇄삭제)
- [BE] RoadmapController (/api/v1/roadmap) — 11개 엔드포인트 (toggle, hall-tours 포함)
- [BE] DataInitializer: 로드맵 9단계(80000000000001~9), 일정 3개(60000000000001~3)
- [FE] pubspec.yaml: table_calendar ^3.1.2 추가
- [FE] AppRoutes.schedule = '/schedule', AppRoutes.roadmap = '/roadmap' 추가
- [FE] home_screen.dart 메뉴 그리드: '웨딩 관리' 6번째 추가, i==0→/schedule, i==5→/roadmap
- [FE] lib/features/schedule/ — ScheduleModel, ScheduleNotifier(sealed state), ScheduleScreen
  - TableCalendar 다크 테마, 카테고리 색상 점 마커, _ScheduleFormBottomSheet
  - ScaffoldMessenger async gap 전 캡처 패턴 적용
- [FE] lib/features/roadmap/ — RoadmapStepModel, HallTourModel, RoadmapNotifier, RoadmapScreen
  - 9단계 카드 목록 (stepType별 아이콘/색상), 낙관적 toggle/delete
  - _StepDetailBottomSheet: stepType별 특화 폼 (BUDGET/HALL/PLANNER/DRESS/HOME/TRAVEL/GIFT/SANGGYEONRYE/ETC)
  - HALL 투어 추가 다이얼로그, 삭제 확인 AlertDialog
  - Navigator/ScaffoldMessenger async gap 전 캡처 패턴

## Vendor Feature (implemented — 7단계 BE)
- schema.sql: weddy_couple_favorites → weddy_favorites (oid PK, owner_oid, vendor_oid, UNIQUE uq_owner_vendor)
- DROP 목록에 weddy_favorites + weddy_couple_favorites 둘 다 유지 (기존 DB 마이그레이션용)
- data.sql: DELETE FROM weddy_couple_favorites → DELETE FROM weddy_favorites
- domain/vendor/entity: Vendor.java (읽기전용, @NoArgsConstructor PROTECTED, @PrePersist 없음), Favorite.java (@PrePersist OidGenerator)
- domain/vendor/repository: VendorRepository (JPQL search: category IS NULL 패턴), FavoriteRepository
- domain/vendor/dto/request: AddFavoriteRequest (@NotBlank @Size(14,14))
- domain/vendor/dto/response: VendorResponse, VendorDetailResponse (favoriteOid nullable), FavoriteItemResponse, AddFavoriteResponse
- domain/vendor/service: VendorService (getOwnerOid() 동일 패턴, N+1 방지 IN 쿼리)
  - getVendors(): vendorRepository.search() → findByOwnerOidAndVendorOidIn() Set<String>으로 isFavorite 결정
  - getFavorites(): findByOwnerOidOrderByCreatedAtDesc() → findAllById() Map으로 조합
  - addFavorite(): existsById 확인 → existsByOwnerOidAndVendorOid 확인 → save()
  - removeFavorite(): findById → ownerOid 일치 확인(IDOR) → delete()
- domain/vendor/controller: VendorController (/api/v1/vendors) — 5개 엔드포인트
  - GET /api/v1/vendors?category=&keyword= — 검색
  - GET /api/v1/vendors/favorites — 즐겨찾기 목록 (정적경로 우선으로 /{vendorOid}보다 먼저 선언)
  - GET /api/v1/vendors/{vendorOid} — 상세
  - POST /api/v1/vendors/favorites — 즐겨찾기 추가 (201)
  - DELETE /api/v1/vendors/favorites/{favoriteOid} — 즐겨찾기 삭제 (204)
- ErrorCode: VENDOR_NOT_FOUND("VENDOR_001"), FAVORITE_NOT_FOUND("FAVORITE_001"), FAVORITE_ALREADY_EXISTS("FAVORITE_002")
- DataInitializer: createFavorites() weddy_favorites로 교체 (oid 범위 610000000000XX)
  - 커플(20000000000001): 그랜드웨딩홀/스튜디오아이엘/뷰티아뜰리에 (61000000000001~3)
  - 솔로(10000000000003): 로맨티크드레스샵 (61000000000004)

## Auth Key Patterns
- DioException handling: check e.error is ApiException first, then ApiException.fromDioException(e)
- login/signup both call getMyInfo() after to build full UserModel for AuthAuthenticated
- GoRouter refresh uses _AuthStateListenable(ChangeNotifier) bridging ref.listen to notifyListeners()
- checkAuthStatus() called in WeddyApp initState via addPostFrameCallback
- AuthError cleared via clearError() → AuthUnauthenticated after SnackBar shown
