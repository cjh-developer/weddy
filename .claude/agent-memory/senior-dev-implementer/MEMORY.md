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
- com.project.weddy.common.security.SecurityConfig (Stateless, BCrypt strength 12)

### JWT Config
- jwt.secret / jwt.expiration=86400000 / jwt.refresh-expiration=604800000
- Public paths: /api/v1/auth/**, /swagger-ui/**, /v3/api-docs/**

### Dependencies Added
- jjwt-api/impl/jackson:0.12.3
- spring-boot-starter-validation
- springdoc-openapi-starter-webmvc-ui:2.3.0

### SQL Scripts
- scripts/schema.sql, scripts/data.sql
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
- Code Gen: riverpod_generator ^2.4.0, build_runner ^2.4.9

## Core Architecture (implemented)
- lib/core/network/api_response.dart    - Generic ApiResponse<T> matching Spring Boot
- lib/core/network/page_response.dart  - PageResponse<T> for pagination
- lib/core/network/api_exception.dart  - ApiException + ErrorCode constants
- lib/core/network/dio_client.dart     - Dio setup + Riverpod providers
- lib/core/storage/token_storage.dart  - JWT token secure storage

## Key Decisions
- Android emulator baseUrl: http://10.0.2.2:8080/api/v1
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
- lib/core/router/app_router.dart  - GoRouter + AppRoutes + _AuthStateListenable

## Auth Key Patterns
- DioException handling: check e.error is ApiException first, then ApiException.fromDioException(e)
- login/signup both call getMyInfo() after to build full UserModel for AuthAuthenticated
- GoRouter refresh uses _AuthStateListenable(ChangeNotifier) bridging ref.listen to notifyListeners()
- checkAuthStatus() called in WeddyApp initState via addPostFrameCallback
- AuthError cleared via clearError() → AuthUnauthenticated after SnackBar shown
