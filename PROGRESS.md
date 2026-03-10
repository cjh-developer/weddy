# Weddy 프로젝트 개발 진행 현황

> 최종 업데이트: 2026-03-11

---

## 프로젝트 개요

결혼 준비를 돕는 모바일 앱 (신랑-신부 커플 공유 기능 포함)

| 항목 | 내용 |
|------|------|
| Frontend | Flutter (Dart ^3.5.4) — Riverpod, Dio, go_router |
| Backend | Spring Boot 3.2.3 (Java 17, Gradle) |
| Database | MySQL |
| 통신 방식 | REST API (JSON) |
| Frontend 경로 | `D:\workspace\weddy\weddy-frontend-1.0\weddy` |
| Backend 경로 | `D:\workspace\weddy\weddy-backend-1.0\weddy` |

---

## MVP 핵심 기능

| # | 기능 | 상태 |
|---|------|------|
| 1 | 사용자 로그인 및 파트너 연결 (신랑-신부) | ✅ 완료 |
| 2 | 웨딩 체크리스트 (할 일 관리) | 🔲 미구현 |
| 3 | 예산 관리 (지출 내역 기록) | 🔲 미구현 |
| 4 | 업체 즐겨찾기 (홀, 스튜디오 등) | 🔲 미구현 |

---

## DB 설계 규칙

| 규칙 | 내용 |
|------|------|
| 테이블명 | `weddy_` 접두사 (예: `weddy_users`) |
| PK | `oid` VARCHAR(14), SecureRandom 14자리 숫자, auto-increment 금지 |
| 사용자 아이디 | `user_id` |
| 사용자 이름 | `name` |
| 휴대번호 | `hand_phone` |
| 이메일 | `email` |

---

## 공통 응답 규격

```json
// 성공
{ "success": true,  "message": "OK",       "data": { ... },  "errorCode": null }

// 실패
{ "success": false, "message": "에러 설명", "data": null,     "errorCode": "ERROR_CODE" }

// 페이지네이션
{
  "success": true,
  "data": {
    "content": [ ... ],
    "totalElements": 42,
    "totalPages": 5,
    "currentPage": 0,
    "size": 10
  }
}
```

---

## DB 테이블 목록

| 테이블 | 설명 | 상태 |
|--------|------|------|
| `weddy_users` | 사용자 계정 | ✅ |
| `weddy_refresh_tokens` | JWT Refresh Token 저장 | ✅ |
| `weddy_couples` | 신랑-신부 커플 정보 | ✅ (DDL만) |
| `weddy_checklists` | 체크리스트 그룹 | ✅ (DDL만) |
| `weddy_checklist_items` | 체크리스트 항목 | ✅ (DDL만) |
| `weddy_budgets` | 예산 카테고리 | ✅ (DDL만) |
| `weddy_budget_items` | 지출 내역 | ✅ (DDL만) |
| `weddy_vendors` | 업체 정보 | ✅ (DDL만) |
| `weddy_couple_favorites` | 업체 즐겨찾기 (N:M) | ✅ (DDL만) |

> SQL 파일 위치: `weddy-backend-1.0/weddy/scripts/schema.sql`, `data.sql`

---

## 1단계: 공통 기반 (완료)

### Spring Boot

| 파일 | 경로 | 설명 |
|------|------|------|
| `OidGenerator` | `common/util/` | SecureRandom 14자리 PK 생성 |
| `ApiResponse<T>` | `common/response/` | 공통 응답 래퍼 |
| `PageResponse<T>` | `common/response/` | 페이지네이션 래퍼 |
| `ErrorCode` | `common/exception/` | 전역 에러코드 enum |
| `CustomException` | `common/exception/` | 비즈니스 예외 |
| `GlobalExceptionHandler` | `common/exception/` | `@RestControllerAdvice` 전역 처리 |
| `JwtTokenProvider` | `common/security/` | JWT 발급/검증 (jjwt 0.12.3) |
| `JwtAuthenticationFilter` | `common/security/` | Bearer 토큰 인증 필터 |
| `SecurityConfig` | `common/security/` | Spring Security 설정, CORS |

**주요 설계 결정:**
- JWT secret, DB 비밀번호: `${ENV_VAR:default}` 환경변수 패턴
- `JwtAuthenticationFilter`: `EXPIRED_TOKEN` / `INVALID_TOKEN` 분리 응답
- `ddl-auto: validate` — 스키마는 `schema.sql`로 수동 관리

### Flutter

| 파일 | 경로 | 설명 |
|------|------|------|
| `ApiResponse<T>` | `core/network/` | 서버 응답 제네릭 모델 |
| `PageResponse<T>` | `core/network/` | 페이지네이션 모델 |
| `ApiException` | `core/network/` | API 에러 처리 |
| `DioClient` | `core/network/` | Dio 설정, JWT 자동 주입 인터셉터 |
| `TokenStorage` | `core/storage/` | flutter_secure_storage JWT 저장 |

**주요 설계 결정:**
- baseUrl: `--dart-define=FLAVOR=dev|staging|production` 환경 분리
- 401 수신 시 토큰 삭제 + `unauthorizedCallbackProvider`로 `AuthNotifier` 연동
- `DioException.error`에 `ApiException` 래핑 → catch 패턴: `e.error is ApiException`

---

## 2단계: 인증 (완료)

### Spring Boot

| 파일 | 경로 | 설명 |
|------|------|------|
| `UserRole` | `domain/user/entity/` | GROOM / BRIDE enum |
| `User` | `domain/user/entity/` | weddy_users 엔티티, `@PrePersist` oid 자동 설정 |
| `RefreshToken` | `domain/user/entity/` | weddy_refresh_tokens 엔티티 |
| `UserRepository` | `domain/user/repository/` | JPA, `existsByInviteCode()` 포함 |
| `RefreshTokenRepository` | `domain/user/repository/` | `findByUserOid()`, `deleteByUserOid()` |
| `SignUpRequest` | `domain/user/dto/request/` | Validation 포함 |
| `LoginRequest` | `domain/user/dto/request/` | |
| `TokenRefreshRequest` | `domain/user/dto/request/` | |
| `AuthResponse` | `domain/user/dto/response/` | accessToken, refreshToken, userOid, userId, name, role |
| `UserResponse` | `domain/user/dto/response/` | `from(User)` 팩토리 |
| `UserService` | `domain/user/service/` | signup, login, refreshToken, getMyInfo |
| `AuthController` | `domain/user/controller/` | `/api/v1/auth/**` |
| `UserController` | `domain/user/controller/` | `/api/v1/users/me` |
| `WeddyUserDetailsService` | `common/security/` | `username = userOid` 저장 |

**핵심 API:**

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/v1/auth/signup` | 회원가입 |
| POST | `/api/v1/auth/login` | 로그인 (JWT 발급) |
| POST | `/api/v1/auth/refresh` | 토큰 갱신 |
| GET | `/api/v1/users/me` | 내 정보 조회 (인증 필요) |

**주요 설계 결정:**
- `WeddyUserDetailsService`: `UserDetails.username` = `userOid` → `@AuthenticationPrincipal String userOid` 직접 사용
- RefreshToken: 사용자당 1개 (`user_oid UNIQUE`), upsert 패턴
- Refresh Token Replay Attack 방어: JWT 서명 검증 + DB 저장값 일치 확인
- `refreshToken()` 검증 순서: **`isTokenExpired()` 먼저 → `validateToken()` 나중** (역순 시 만료 토큰이 INVALID_TOKEN 응답)
- 초대코드: `WED-XXXXXX` 형식, DB `existsByInviteCode()` 중복 체크 + 5회 재시도

### Flutter

| 파일 | 경로 | 설명 |
|------|------|------|
| `AuthResponse` | `features/auth/data/model/` | 서버 AuthResponse DTO |
| `UserModel` | `features/auth/data/model/` | 서버 UserResponse DTO |
| `SignUpRequest` | `features/auth/data/model/` | 회원가입 요청 모델 |
| `AuthRemoteDataSource` | `features/auth/data/datasource/` | Dio API 호출 |
| `AuthRepositoryImpl` | `features/auth/data/repository/` | 토큰 저장 포함 |
| `AuthRepository` | `features/auth/domain/repository/` | 추상 인터페이스 |
| `AuthState` | `features/auth/domain/model/` | sealed class (Dart 3.0+) |
| `AuthNotifier` | `features/auth/presentation/notifier/` | Riverpod StateNotifier |
| `LoginScreen` | `features/auth/presentation/screen/` | 로그인 화면 |
| `SignUpScreen` | `features/auth/presentation/screen/` | 회원가입 화면 |
| `AppRouter` | `core/router/` | go_router + 인증 redirect |

**주요 설계 결정:**
- `AuthState` sealed class: `AuthInitial`, `AuthLoading`, `AuthAuthenticated(UserModel)`, `AuthUnauthenticated`, `AuthError`
- `_AuthStateListenable`: `ChangeNotifier` 어댑터로 Riverpod → go_router `refreshListenable` 연결
- 401 처리: `unauthorizedCallbackProvider` override → `main.dart`에서 `AuthNotifier.logout()` 연결 (순환 의존성 방지)
- `checkAuthStatus()`: `initState + addPostFrameCallback`으로 타이밍 이슈 방지
- `login/signup` 후 `/users/me` 호출로 완전한 `UserModel` 획득

---

## 핵심 패턴 요약

### DioException 처리 패턴 (Flutter)
```dart
} on DioException catch (e) {
  if (e.error is ApiException) throw e.error as ApiException;
  throw ApiException.fromDioException(e);
}
```
> DataSource 레이어에서 처리. Notifier 레이어에서 DioException catch 불필요.

### 401 강제 로그아웃 패턴 (Flutter)
```dart
// main.dart
ProviderScope(
  overrides: [
    unauthorizedCallbackProvider.overrideWith(authLogoutCallbackProvider),
  ],
  child: const WeddyApp(),
)
```

### OID 생성 (Spring Boot)
```java
String oid = OidGenerator.generate(); // 14자리 숫자 문자열
```

---

## 환경 설정

### Spring Boot (`application.yml`)
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/weddy_db?useSSL=false&serverTimezone=Asia/Seoul
    username: ${DB_USERNAME:root}
    password: ${DB_PASSWORD:1234}
jwt:
  secret: ${JWT_SECRET:weddySecretKeyFor...}
  expiration: 86400000       # 24시간
  refresh-expiration: 604800000  # 7일
```

### Flutter (`--dart-define`)
```
# Android 에뮬레이터 (기본)
FLAVOR=dev  → baseUrl: http://10.0.2.2:8080/api/v1

# 스테이징
FLAVOR=staging  → baseUrl: https://staging-api.weddy.co.kr/api/v1

# 프로덕션
FLAVOR=production  → baseUrl: https://api.weddy.co.kr/api/v1
```

### 테스트 계정 (data.sql)
| 역할 | user_id | 비밀번호 |
|------|---------|---------|
| GROOM | (data.sql 참조) | `Password1!` |
| BRIDE | (data.sql 참조) | `Password1!` |

---

## 실행 순서

### 최초 실행
```bash
# 1. MySQL DB 생성
CREATE DATABASE weddy_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 2. 스키마 실행
mysql -u root -p weddy_db < scripts/schema.sql

# 3. 테스트 데이터 삽입 (선택)
mysql -u root -p weddy_db < scripts/data.sql

# 4. Spring Boot 기동
./gradlew bootRun

# 5. Flutter 패키지 설치
flutter pub get

# 6. Flutter 실행 (Android 에뮬레이터)
flutter run --dart-define=FLAVOR=dev
```

---

## 다음 구현 단계

| 단계 | 내용 | 상태 |
|------|------|------|
| 1단계 | 공통 기반 (ApiResponse, JWT, Dio) | ✅ 완료 |
| 2단계 | 인증 (회원가입, 로그인, 토큰 갱신) | ✅ 완료 |
| **3단계** | **커플 연결** (초대코드로 신랑-신부 연결) | 🔲 대기 |
| 4단계 | 체크리스트 CRUD | 🔲 대기 |
| 5단계 | 예산 관리 CRUD | 🔲 대기 |
| 6단계 | 업체 즐겨찾기 | 🔲 대기 |

### 3단계 구현 예정 내용
**Spring Boot**
- `Couple` 엔티티 (`weddy_couples` 매핑)
- `CoupleRepository`, `CoupleService`
- `POST /api/v1/couples/connect` — 초대코드로 파트너 연결
- `GET /api/v1/couples/me` — 내 커플 정보 조회

**Flutter**
- `CoupleModel`, `CoupleRemoteDataSource`, `CoupleRepository`
- `CoupleNotifier` (Riverpod)
- 커플 연결 화면 (초대코드 입력)
- 내 초대코드 공유 화면

---

*이 문서는 개발 진행에 따라 지속적으로 업데이트됩니다.*
