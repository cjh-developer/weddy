# Lead Code Validator - Agent Memory

## Project Context
- Project: Weddy (웨딩 플래너 앱) - Flutter frontend + Spring Boot backend
- Flutter SDK: ^3.5.4, Dart null-safety 완전 적용
- State management: flutter_riverpod ^2.5.1 + riverpod_annotation/generator
- Network: dio ^5.4.3, flutter_secure_storage ^9.2.2
- Navigation: go_router ^14.2.7 (main.dart에 MaterialApp.router + routerProvider로 적용 완료)

## Recurring Patterns & Known Issues

### [CRITICAL] DioException.error 래핑 패턴 주의
- `handler.reject(DioException(error: apiException))` 패턴 사용 중
- 호출부에서 `catch (e)` 시 `e is ApiException` 조건이 false가 됨
- Repository 계층에서 반드시 `(e as DioException).error as ApiException`으로 꺼내야 함
- 향후 Repository 계층 구현 시 공통 try-catch 유틸 제공 필요

### [PATTERN] Flutter main()에서 WidgetsFlutterBinding.ensureInitialized() 누락
- flutter_secure_storage 등 네이티브 플러그인 사용 시 반드시 필요
- 매 프로젝트 초기 설정 시 확인 항목

### [PATTERN] copyWith에서 nullable 필드의 명시적 null 설정 불가 버그
- `field: newValue ?? this.field` 패턴은 null 설정 의도를 구분 불가
- `clearField` boolean flag 패턴으로 해결
- Dart에서는 freezed 패키지가 이 문제를 자동 처리함 (도입 검토 권장)

### [PATTERN] baseUrl 환경 분리 미적용
- Android 에뮬레이터 전용 10.0.2.2 하드코딩 주의
- --dart-define=FLAVOR=dev/staging/production 패턴으로 분리해야 함

### [PATTERN] static const 인스턴스 vs 인스턴스 필드
- TokenStorage._storage가 static const로 선언되어 Provider 싱글톤 보장이 있어도 숨겨진 공유 발생
- Provider에서 싱글톤 보장 시 인스턴스 필드로 유지하는 것이 더 명확

## Architecture Decisions
- Server response format: `{success, message, data, errorCode}` (Spring Boot 공통 규격)
- Pagination format: `{content, totalElements, totalPages, currentPage, size}`
- Token storage: flutter_secure_storage (Android: EncryptedSharedPreferences, iOS: Keychain)
- Error hierarchy: DioException -> ApiException (domain layer exception)
- Provider 위치: dio_client.dart에 tokenStorageProvider, dioClientProvider 함께 정의

### [CRITICAL] go_router Provider dispose 미처리
- routerProvider 내 GoRouter와 _AuthStateListenable은 ref.onDispose로 반드시 dispose 해야 함
- GoRouter는 내부 RouteInformationProvider 등 리소스를 보유하므로 누락 시 메모리 누수 발생

### [CRITICAL] 401 처리 후 AuthNotifier 상태 미갱신
- _ErrorInterceptor에서 clearTokens()만 호출하면 go_router redirect가 트리거되지 않음
- 해결: unauthorizedCallbackProvider 패턴으로 콜백 주입 → AuthNotifier.logout() 호출 → 상태 전환 → redirect 트리거
- dio_client.dart에서 auth_notifier.dart를 직접 import하면 순환 의존성 발생
- 해결 패턴: unauthorizedCallbackProvider(기본: 토큰삭제만) + authLogoutCallbackProvider(실제: logout()) + main.dart에서 overrideWith

### [PATTERN] Notifier 계층의 불필요한 DioException catch
- DataSource에서 모든 DioException을 ApiException으로 변환하므로 Notifier 계층의 `on DioException` 절은 dead code
- Notifier에서는 `on ApiException`과 `catch (e)` (fallback)만 있으면 충분
- 불필요한 `import 'package:dio/dio.dart'`도 함께 제거

### [PATTERN] DropdownButtonFormField validator와 수동 null 체크 중복
- Form에 validator 있으면 _formKey.validate()가 모든 필드를 검증함
- 별도 null 체크 + SnackBar 조합은 UX 불일치 유발 (validator 에러 + SnackBar 동시 노출)
- validator만으로 처리하는 것이 정확함

### [PATTERN] SliverAppBar expandedHeight:0 + flexibleSpace 조합 버그
- expandedHeight:0으로 설정하면 FlexibleSpaceBar.background가 렌더링될 공간이 없음
- 결과: 그라디언트/배경 이미지가 표시되지 않고, backgroundColor:transparent이면 AppBar 완전 투명
- 해결: flexibleSpace 제거 후 backgroundColor 직접 지정, 또는 expandedHeight를 kToolbarHeight 이상으로 설정

### [PATTERN] 기타 FE
- 중복 헬퍼 → top-level 함수 추출 / go_router errorBuilder: HomeScreen 금지 → 전용 404 위젯

## Files Reviewed
- `lib/main.dart` - WidgetsFlutterBinding.ensureInitialized() 추가됨, unauthorizedCallbackProvider override 추가됨
- `lib/core/network/api_response.dart` - copyWith clearData flag 추가됨
- `lib/core/network/page_response.dart` - isLast 경계 조건 명확화됨
- `lib/core/network/api_exception.dart` - unused param 주석 추가됨
- `lib/core/network/dio_client.dart` - sendTimeout, 환경분리, onUnauthorized 콜백 패턴, unauthorizedCallbackProvider 추가됨
- `lib/core/storage/token_storage.dart` - static const 제거, iOSOptions 추가됨
- `lib/core/router/app_router.dart` - ref.onDispose로 GoRouter+_AuthStateListenable dispose 추가됨, errorBuilder 미수정(개선 권고)
- `lib/features/auth/presentation/notifier/auth_notifier.dart` - DioException catch 제거, dio import 제거, authLogoutCallbackProvider 추가됨
- `lib/features/auth/presentation/screen/sign_up_screen.dart` - 중복 역할 null 체크 제거됨
- `lib/features/home/presentation/screen/home_screen.dart` - SliverAppBar 그라디언트 버그 수정, _showComingSoon top-level 추출

---

## Spring Boot Backend (weddy-backend-1.0)

### Stack
- Java 17, Spring Boot 3.2.3, JPA, MySQL, jjwt 0.12.3, Lombok, Springdoc OpenAPI 2.3.0
- Base package: com.project.weddy
- Path: D:/workspace/weddy/weddy-backend-1.0/weddy/

### DB 규칙 (확정)
- 모든 테이블명: weddy_ 접두사 필수
- 모든 PK: oid VARCHAR(14), auto-increment 절대 금지, 서버에서 OidGenerator로 생성
- weddy_users 필수 컬럼: oid, user_id, name, hand_phone, email, role, invite_code
- weddy_couple_favorites: 복합 PK (couple_oid, vendor_oid)
- FK ON DELETE: CASCADE(자식) 또는 SET NULL(약한 참조) 패턴 사용

### JWT 규칙 (jjwt 0.12.x)
- 신규 API만 사용: subject() / expiration() / signWith() / parseSignedClaims().getPayload()
- deprecated 절대 금지: parseClaimsJws(), setSubject(), setExpiration()
- 액세스 토큰: sub=userOid, uid=userId / 리프레시 토큰: sub=userOid만 포함
- wildcard import (io.jsonwebtoken.*) 금지 → 명시적 import 필수

### Backend 반복 실수 패턴
- [확인됨] JwtAuthenticationFilter: 만료/무효 토큰 구분 없이 INVALID_TOKEN 일괄 반환
  → isTokenExpired() 선행 체크 후 EXPIRED_TOKEN vs INVALID_TOKEN 구분 필수
- [확인됨] SecurityConfig: AuthenticationManager 빈 미노출 → 로그인 API 전 선제 추가 필요
- [확인됨] application.yml: DB 비밀번호, JWT secret 하드코딩 금지 → ${VAR:default} 패턴 사용
- [확인됨] Service에서 Entity 정적 유틸 중복 구현: User.generateInviteCode()가 Entity에 있음에도
  UserService에 동일 로직 재구현 → 항상 Entity의 정적 메서드 재사용할 것
- [확인됨] generateUniqueInviteCode() 무한 루프 의도를 for+return으로 잘못 구현:
  루프 내 첫 반복에서 무조건 return → 실질적 재시도 로직 없음. 반드시 existsByX() 체크 후 return 패턴 사용
- [확인됨] UserService.refreshToken(): validateToken() 먼저 호출 시 만료 토큰도 false 반환하여
  EXPIRED_TOKEN 대신 INVALID_TOKEN으로 응답됨 → isTokenExpired() 반드시 선행 호출
- [확인됨] SecurityConfig: DaoAuthenticationProvider 빈 등록 후 filterChain에 .authenticationProvider() 미등록
  → securityFilterChain()에 DaoAuthenticationProvider 파라미터로 주입 후 .authenticationProvider() 등록 필수
- [확인됨] UserRepository: generateUniqueInviteCode()에서 existsByInviteCode() 사용 시 Repository에 메서드 미선언
  → Service 로직 추가 시 Repository에 필요한 메서드 동시 선언 확인

### 보안 규칙
- JWT secret: 최소 256비트(32바이트) 이상
- 운영환경 CORS: allowedOriginPatterns("*") 금지, 실제 도메인으로 제한

### PasswordEncoder 패턴 (BCrypt 복귀 확정)
- [확인됨] 보안 패치에서 BCrypt(cost=12)로 최종 복귀 완료
- SecurityConfig, UserService, DataInitializer 모두 BCryptPasswordEncoder(12) 사용 확인됨
- SecurityConfig @Bean 메서드 간 직접 호출 금지 → 파라미터 주입 패턴 사용 (proxyBeanMethods 안전)
- DataInitializer: @Profile("!test") + existsByUserId() 체크 → 멱등 보장 확인됨

### 보안 패치 검토 완료 사항 (이번 세션)
- [수정됨] CORS split(",") → stream().map(String::trim).filter(!empty) 패턴으로 공백 처리
- [수정됨] Caffeine expireAfterWrite → expireAfterAccess (Rate Limit 버킷 만료 정책 수정)
- [수정됨] RateLimitFilter: new ObjectMapper() → @RequiredArgsConstructor + 생성자 주입
- [수정됨] RateLimitFilter: 하드코딩 에러코드/메시지 → ErrorCode.RATE_LIMIT_EXCEEDED enum 참조
- [수정됨] JwtTokenProvider: secret.length() 문자 수 기준 → secretBytes.length 바이트 수 기준 검증
- [이상 없음] BCrypt 복귀 완전성: SecurityConfig(BCryptPasswordEncoder(12) Bean), UserService(passwordEncoder.matches()),
  DataInitializer(passwordEncoder.encode()) 모두 확인됨. Sha512PasswordEncoder 흔적 없음.
- [이상 없음] 사용자 열거 방지: login()에서 user==null 시 dummy encode 후 UNAUTHORIZED 반환 확인
- [이상 없음] JWT secret: application.yml 폴백 없음(${JWT_SECRET}), dev yml에 32자+ 시크릿, 바이트 검증 로직 있음
- [이상 없음] RateLimitFilter @Order(1), bucket4j/caffeine import 정상, ApiResponse.fail() 시그니처 일치
- [이상 없음] application.yml cors.allowed-origins 폴백값 정상 (localhost:3000 등)

### [CRITICAL] CoupleService.connectCouple() TOCTOU 레이스 컨디션
- existsByGroomOidOrBrideOid() 체크 후 save() 사이에 동시 요청이 들어오면 같은 사용자가 두 커플에 속할 수 있음
- 해결: DB UNIQUE 제약(groom_oid, bride_oid 각각 UNIQUE) + 트랜잭션 격리 + DB 레벨에서 최종 방어
- @Transactional 단독으로는 멀티 인스턴스 환경에서 보장 불가

### [CRITICAL] CoupleService 역할 배정 로직 버그 (GROOM+GROOM 커플 가능)
- me.getRole() == GROOM 이면 partner는 무조건 bride로 배정됨
- me=GROOM, partner=GROOM 조합: groomOid=me, brideOid=partner(실제 GROOM) → DB에 GROOM이 bride 컬럼에 저장
- UserRole.BRIDE 체크 없이 else 처리 → partner 역할 검증 미완
- 해결: partner 역할이 me와 다른지 반드시 검증

### [RESOLVED] CoupleModel.brideOid non-nullable 문제
- CoupleModel.brideOid가 String?으로 수정 완료됨 (현재 세션에서 확인)
- brideName도 String?으로 선언되어 nullable 처리 정상

### [RESOLVED] connectCouple() catch 블록 누락
- connectCouple()에 catch(e) 블록이 추가되어 완전한 예외 처리 확인됨

### [CONFIRMED] CoupleService 역할 배정 로직 버그 미수정 (현재 세션)
- GROOM+GROOM, BRIDE+BRIDE 조합 방어 없이 else 처리 유지 중
- partner 역할이 me와 반대인지 검증하는 코드 여전히 없음
- 후속 단계에서 반드시 수정 필요

### [PATTERN] autoDispose Provider + ref.read() 조합 주의
- coupleNotifierProvider가 autoDispose인데 화면 전환 후 다시 진입하면 새 인스턴스 생성
- weddingSetupProvider도 동일: autoDispose이므로 화면 이탈 시 상태 리셋 → 의도된 동작인지 확인 필요

### [PATTERN] application.yml DB 자격증명 하드코딩 잔존
- application.yml에 username:weddy, password:weddy01 평문 저장 확인됨
- dev 환경이라도 application-dev.yml로 분리하거나 ${DB_PASSWORD:weddy01} 환경변수 패턴 사용 권고

### [PATTERN] disconnectCouple JdbcTemplate JOIN DELETE — MySQL 전용 문법
- "DELETE ci FROM weddy_checklist_items ci INNER JOIN weddy_checklists c ON ..." 문법은 MySQL/MariaDB 전용
- 다른 DB 엔진(H2, PostgreSQL)에서는 동작 불가 → 테스트 환경이 H2이면 반드시 별도 쿼리로 분리 필요
- 이 프로젝트는 MySQL 고정이므로 현재 문법은 허용되나 주석으로 명시 필요
- @Transactional(class-level)이 있으므로 6단계 삭제가 단일 트랜잭션으로 묶임 → 정상

### [PATTERN] handPhone @Pattern과 DB schema 컬럼 길이 일치 확인 필요
- SignUpRequest @Pattern: ^01[016789]-?\d{3,4}-?\d{4}$ → 최대 13자 (010-1234-5678 포맷)
- schema.sql hand_phone VARCHAR(20) → 충분 (문제 없음)
- 하이픈 포함 여부에 따라 실제 저장 값 형태가 혼재될 수 있음 → 저장 전 정규화(하이픈 제거) 권고

### [PATTERN] springdoc 비활성화 시 SecurityConfig permitAll 정리 필요
- /v3/api-docs/**, /swagger-ui/** 등 SpringDoc 경로를 permitAll로 열어두는 SecurityConfig 패턴
- springdoc 비활성화 후에도 해당 경로가 permitAll이면 불필요한 공격 표면이 열려 있음
- 프로파일 분기 또는 조건부 SecurityFilterChain 등록으로 개발 환경에서만 허용 필요

### Flutter flutter_dotenv 패턴 (확정)
- .env, .env.production pubspec.yaml assets 등록 필수
- 전략 A (현재): gitignore 미포함 커밋 / 전략 B: gitignore + CI 파일 생성
- .env.example은 assets에 포함하지 않음 (실제 로드 대상이 아님)
- dotenv.load() → WidgetsFlutterBinding.ensureInitialized() 다음, runApp() 이전 순서 필수

### [PATTERN] 일정/웨딩관리 도메인 패턴
- 상세 내용: patterns-schedule-roadmap.md 참조
- 핵심: BUDGET details key = totalBudget, SANGGYEONRYE = restaurantName/extraItems, TRAVEL = purchaseSource/stopovers
- RoadmapStep.update()에 clearDueDate 파라미터 추가됨 (null 명시 지우기 지원)
- ROADMAP_TRAVEL_STOP_NOT_FOUND(ROADMAP_004) ErrorCode 추가됨
