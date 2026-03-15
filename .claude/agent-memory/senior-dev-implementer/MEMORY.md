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

## Auth Key Patterns
- DioException handling: check e.error is ApiException first, then ApiException.fromDioException(e)
- login/signup both call getMyInfo() after to build full UserModel for AuthAuthenticated
- GoRouter refresh uses _AuthStateListenable(ChangeNotifier) bridging ref.listen to notifyListeners()
- checkAuthStatus() called in WeddyApp initState via addPostFrameCallback
- AuthError cleared via clearError() → AuthUnauthenticated after SnackBar shown
