# Weddy 프로젝트 변경 이력

> 결혼 준비 앱 — Flutter (Frontend) + Spring Boot (Backend)

---

## [2단계] 인증 시스템 구현

### Backend
| 파일 | 내용 |
|------|------|
| `domain/user/entity/User.java` | 사용자 엔티티 (oid PK, BCrypt 비밀번호, 초대코드) |
| `domain/user/entity/UserRole.java` | GROOM / BRIDE Enum |
| `domain/user/entity/RefreshToken.java` | 리프레시 토큰 엔티티 (user_oid UNIQUE) |
| `domain/user/repository/UserRepository.java` | JPA Repository (existsByUserId, findByUserId 등) |
| `domain/user/repository/RefreshTokenRepository.java` | JPA Repository (findByUserOid, deleteByUserOid 등) |
| `domain/user/dto/request/SignUpRequest.java` | 회원가입 요청 DTO |
| `domain/user/dto/request/LoginRequest.java` | 로그인 요청 DTO |
| `domain/user/dto/request/TokenRefreshRequest.java` | 토큰 갱신 요청 DTO |
| `domain/user/dto/response/AuthResponse.java` | 인증 응답 DTO (accessToken, refreshToken, userOid) |
| `domain/user/dto/response/UserResponse.java` | 사용자 정보 응답 DTO |
| `domain/user/service/UserService.java` | 회원가입·로그인·토큰갱신·내정보조회 비즈니스 로직 |
| `domain/user/controller/AuthController.java` | POST /api/v1/auth/{signup, login, refresh, logout} |
| `domain/user/controller/UserController.java` | GET /api/v1/users/me |
| `common/security/WeddyUserDetailsService.java` | username = userOid 기반 UserDetails 구현 |
| `common/security/SecurityConfig.java` | Spring Security 설정 (JWT + DaoAuthenticationProvider) |
| `common/security/JwtTokenProvider.java` | JWT 발급·검증 (accessToken 24h, refreshToken 7d) |
| `common/security/JwtAuthenticationFilter.java` | 요청마다 토큰 검증 및 SecurityContext 주입 |

### Frontend
| 파일 | 내용 |
|------|------|
| `lib/features/auth/data/model/auth_response.dart` | AuthResponse 모델 |
| `lib/features/auth/data/model/user_model.dart` | UserModel |
| `lib/features/auth/data/model/sign_up_request.dart` | SignUpRequest 모델 |
| `lib/features/auth/data/datasource/auth_remote_datasource.dart` | 인증 API 호출 |
| `lib/features/auth/data/repository/auth_repository_impl.dart` | Repository 구현체 |
| `lib/features/auth/domain/repository/auth_repository.dart` | Repository 추상 인터페이스 |
| `lib/features/auth/presentation/notifier/auth_notifier.dart` | AuthState(sealed) + AuthNotifier(Riverpod) |
| `lib/features/auth/presentation/screen/login_screen.dart` | 로그인 화면 |
| `lib/features/auth/presentation/screen/sign_up_screen.dart` | 회원가입 화면 |
| `lib/core/router/app_router.dart` | go_router + _AuthStateListenable 어댑터 |
| `lib/main.dart` | ProviderScope + unauthorizedCallbackProvider override |

---

## [2.5단계] 보안·환경·UI 개선 (2026-03-12)

### 1. Flutter 환경 설정 — flutter_dotenv 적용

**목적**: 서버 주소 등 설정값을 코드에서 분리, Dev/Prod 환경 구분

| 파일 | 변경 내용 |
|------|-----------|
| `pubspec.yaml` | `flutter_dotenv: ^5.2.1` 추가, assets 섹션 등록 |
| `.env` | Dev 환경 설정 (`API_BASE_URL=http://10.0.2.2:8080/api/v1`) |
| `.env.production` | Prod 환경 설정 |
| `.env.example` | 팀 공유용 템플릿 (커밋 허용) |
| `.gitignore` | `.env` 파일 제외 규칙 추가 |
| `lib/main.dart` | `dotenv.load(fileName: envFile)` 초기화 추가 |
| `lib/core/network/dio_client.dart` | `_baseUrl`을 dotenv 참조로 교체 |

**빌드 커맨드**
```bash
flutter run                                         # Dev (.env 사용)
flutter build apk --dart-define=FLAVOR=production   # Prod (.env.production 사용)
```

---

### 2. 비밀번호 암호화 — BCrypt(strength=12)

**목적**: OWASP 권고 방식인 BCrypt 적용 (SHA-512는 GPU 크래킹에 취약)

| 파일 | 변경 내용 |
|------|-----------|
| `common/security/SecurityConfig.java` | `BCryptPasswordEncoder(12)` 빈 등록 |
| `domain/user/service/UserService.java` | `passwordEncoder.encode()` / `matches()` 사용 |
| `common/init/DataInitializer.java` | `PasswordEncoder` 주입 → 런타임에 BCrypt 해시 생성 |

---

### 3. UI 테마 — Light Green + 로고

**목적**: 옅은 초록색 계열 테마 적용, 로고 이미지 연동

| 파일 | 변경 내용 |
|------|-----------|
| `lib/main.dart` | `seedColor: 0xFF22C55E` (Green-500) 전면 교체, AppBar/Button/Input/Card 테마 통일 |
| `lib/features/auth/presentation/screen/login_screen.dart` | `_WeddyLogo` 위젯 재설계 — `assets/images/logo.jpg` 사용, 로드 실패 시 텍스트 fallback |
| `assets/images/logo.jpg` | `D:/workspace/weddy/images/default.jpg` 복사 배치 |

**테마 컬러 팔레트**
| 역할 | 색상 |
|------|------|
| Primary Seed | `#22C55E` (Green-500, 로고 동일) |
| Scaffold 배경 | `#F0FDF4` (Green-50) |
| AppBar 전경 | `#15803D` (Green-700) |
| Input 포커스 테두리 | `#22C55E` (width 2) |
| Card 테두리 | `#BBF7D0` (Green-200) |

---

### 4. DB 초기화 스크립트 정비

| 파일 | 변경 내용 |
|------|-----------|
| `scripts/schema.sql` | `SET FOREIGN_KEY_CHECKS=0`, `DROP TABLE IF EXISTS` (자식→부모 역순) |
| `scripts/data.sql` | `DELETE FROM` (자식→부모 역순), 업체 데이터 삽입 |

---

### 5. 보안 패치 — 6개 항목

#### 5-1. 로그인 사용자 열거 방지
- `UserService.login()`: 사용자 미존재 시 `USER_NOT_FOUND` → `UNAUTHORIZED` 통일
- 타이밍 공격 방지: 사용자 없어도 더미 `encode()` 연산 수행

#### 5-2. JWT Secret 관리 강화
- `application.yml`: 하드코딩 폴백 제거 → 환경변수 전용
- `JwtTokenProvider` 생성자: 32자(UTF-8 바이트) 미만 시 기동 즉시 실패
- `application-dev.yml` 생성 (개발용 자격증명 분리, `.gitignore` 등록)

#### 5-3. Rate Limiting
| 항목 | 내용 |
|------|------|
| 라이브러리 | `bucket4j-core:8.10.1` + `caffeine:3.1.8` |
| 적용 경로 | `/api/v1/auth/login`, `/api/v1/auth/signup`, `/api/v1/auth/refresh` |
| 정책 | IP + 경로 조합 키, 분당 최대 10회 (greedy refill) |
| 필터 위치 | `@Order(1)` — SecurityFilterChain 앞에서 실행 |
| 초과 응답 | HTTP 429 + `ApiResponse.fail("COMMON_429", ...)` |
| IP 스푸핑 방지 | `server.forward-headers-strategy: NATIVE` + `getRemoteAddr()` 사용 |

#### 5-4. CORS 환경별 설정
- `SecurityConfig.java`: 와일드카드(`allowedOriginPatterns("*")`) → `setAllowedOrigins()` 명시적 오리진
- `application.yml`: `cors.allowed-origins: ${CORS_ALLOWED_ORIGINS:...}` 환경변수 주입

#### 5-5. DataInitializer 프로파일 제한
- `@Profile("!test")` → `@Profile("dev")`: 운영·스테이징 환경에서 테스트 계정 생성 차단

#### 5-6. 운영 설정 기본값 안전화
- `jpa.show-sql: false` (dev에서는 `application-dev.yml`로 오버라이드)
- `logging.level: INFO` (dev에서는 DEBUG)

---

### 6. 테스트 데이터 초기화 — DataInitializer 확장

**목적**: 앱 기동 시 전체 테스트 데이터 자동 생성 (멱등 보장)

#### 생성 데이터 전체 목록

**사용자 (비밀번호 모두 `1234`)**
| userId | 이름 | 역할 | oid |
|--------|------|------|-----|
| groom_kim | 김지훈 | GROOM | 10000000000001 |
| bride_lee | 이수연 | BRIDE | 10000000000002 |
| solo_park | 박민지 | BRIDE (미연결) | 10000000000003 |

**커플**
- 김지훈 + 이수연 / 예식일 `2026-10-15` / 총 예산 5,000만원 / oid: 20000000000001

**체크리스트 (3카테고리, 13항목)**
| 카테고리 | oid | 완료 | 미완료 |
|----------|-----|------|--------|
| 예식장 준비 | 30000000000001 | 2개 | 3개 |
| 스드메 준비 | 30000000000002 | 2개 | 2개 |
| 신혼여행 준비 | 30000000000003 | 1개 | 2개 |

**예산 (4카테고리, 10항목)**
| 카테고리 | 계획 금액 | 지출 항목 | oid |
|----------|-----------|-----------|-----|
| 예식비 | 1,500만원 | 웨딩홀 대관료, 답례품, 사회자 | 40000000000001 |
| 스드메 | 1,000만원 | 촬영비, 드레스, 메이크업 | 40000000000002 |
| 신혼여행 | 800만원 | 항공권, 숙소 | 40000000000003 |
| 기타 | 500만원 | 예복, 혼수 가전 | 40000000000004 |

**즐겨찾기**: 그랜드 웨딩홀, 스튜디오 아이엘, 뷰티 아뜰리에

**웨딩 업체 (data.sql — 13개)**
| 카테고리 | 업체명 |
|----------|--------|
| HALL | 그랜드 웨딩홀, 더베뉴 웨딩홀, 파크 웨딩홀 |
| STUDIO | 스튜디오 아이엘, 스튜디오 화이트 |
| DRESS | 로맨티크 드레스샵, 웨딩드레스 하우스 |
| MAKEUP | 뷰티 아뜰리에, 브라이덜 스튜디오 |
| HONEYMOON | 발리 허니문 투어, 유럽 웨딩 트래블 |
| ETC | 웨딩 플래너 스튜디오, 플라워 웨딩 데코 |

---

### 7. DB 스키마 재설계 — FK 전면 제거

**원인**: `weddy_refresh_tokens` collation 미지정(`utf8mb4_0900_ai_ci`)으로
나머지 테이블(`utf8mb4_unicode_ci`)과 충돌 → `[HY000][3780]` FK 에러

**변경 내용**
| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| FK 제약 | 9개 CONSTRAINT FOREIGN KEY | **전부 제거** |
| 참조 무결성 | DB 레벨 | 애플리케이션 레이어 관리 |
| 관계 컬럼 인덱스 | FK 자동 생성 | `INDEX idx_*` 명시 추가 |
| `role` 컬럼 | `ENUM('GROOM','BRIDE')` | `VARCHAR(10)` |
| vendor `category` | `ENUM(...)` | `VARCHAR(20)` |
| collation | 테이블마다 상이 | **전 테이블 `utf8mb4_unicode_ci` 통일** |

---

## DB 리셋 및 기동 방법

```bash
# 1. DB 초기화 (MySQL 클라이언트)
source scripts/schema.sql
source scripts/data.sql

# 2. 앱 기동 (dev 프로파일 필수)
./gradlew bootRun --args='--spring.profiles.active=dev'
# → DataInitializer: 사용자·커플·체크리스트·예산·즐겨찾기 자동 생성
```

---

## 현재 아키텍처 주요 결정사항

| 항목 | 결정 | 이유 |
|------|------|------|
| 비밀번호 해시 | BCrypt(strength=12) | OWASP 권고, GPU 브루트포스 방어 |
| JWT | accessToken 24h + refreshToken 7d | DB Rotation 방식 |
| SecurityContext principal | userOid (String) | userId 변경 가능성 고려 |
| PK 방식 | SecureRandom 14자리 숫자 문자열 | IDOR 공격 예측 불가, auto-increment 비사용 |
| DB FK | 미사용 | 참조 무결성은 Service 트랜잭션에서 관리 |
| Flutter 환경 설정 | flutter_dotenv | Dev/Prod .env 파일 분리 |

---

## 다음 구현 단계

- **3단계**: 커플 연결 (Couple 엔티티 + 초대코드 API + Flutter 커플 연결 화면)
- **4단계**: 체크리스트 → 예산 → 즐겨찾기 (CRUD API + Flutter 화면)

---

## 보안 백로그 (추후 적용 권고)

| 우선순위 | 항목 |
|----------|------|
| MEDIUM | `SignUpRequest` handPhone `@Pattern` 검증 추가 |
| MEDIUM | Swagger 운영 환경 비활성화 (`springdoc.enabled: false`) |
| LOW | `jwt.expiration` 30분으로 단축 (현재 24시간) |
| LOW | 로그인 성공 로그 userId 마스킹 |
| LOW | iOS Keychain 접근성 `first_unlock_this_device` 강화 |
