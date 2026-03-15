# 💍 Weddy — 당신의 완벽한 결혼 준비 파트너

> 커플이 함께 결혼 준비를 체계적으로 관리할 수 있는 모바일 앱

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.2.3-6DB33F?style=flat-square&logo=springboot)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-17-ED8B00?style=flat-square&logo=openjdk)](https://openjdk.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.x-4479A1?style=flat-square&logo=mysql&logoColor=white)](https://mysql.com)

---

## 📱 화면 미리보기

<table>
  <tr>
    <td align="center"><b>로그인</b></td>
    <td align="center"><b>회원가입</b></td>
    <td align="center"><b>결혼 예정일 입력</b></td>
    <td align="center"><b>홈 화면 — 파트너 연결 및 진행률</b></td>
    <td align="center"><b>웨딩 타임라인</b></td>
    <td align="center"><b>추천업체 및 인기글</b></td>
  </tr>
  <tr>
    <td><img src="images/01_loginPage.jpg" width="160"/></td>
    <td><img src="images/02_signPage.jpg" width="160"/></td>
    <td><img src="images/03_SelectDataPage.jpg" width="160"/></td>
    <td><img src="images/04_afterLoginPage1.jpg" width="160"/></td>
    <td><img src="images/05_afterLoginPage2.jpg" width="160"/></td>
    <td><img src="images/06_afterLoginPage3.jpg" width="160"/></td>
  </tr>
</table>

---

## ✨ 주요 기능

| 기능 | 설명 | 상태 |
|------|------|------|
| 회원가입 · 로그인 | ID/PW 인증, JWT AccessToken + RefreshToken | ✅ 완료 |
| 소셜 로그인 | Google · Naver · Kakao (UI 구현) | 🔜 연동 예정 |
| 결혼 예정일 설정 | 로그인 후 D-DAY 카운트다운 설정 | ✅ 완료 |
| 커플 연결 | 6자리 초대코드로 파트너와 계정 연동 | ✅ 완료 |
| 웨딩 체크리스트 | 카테고리별 항목 관리, 완료 토글, D-DAY 표시 | ✅ 완료 |
| 예산 관리 | 카테고리별 예산 계획 및 지출 내역 관리 | 🔜 구현 예정 |
| 업체 관리 | 스튜디오·드레스·메이크업 등 웨딩 업체 즐겨찾기 | 🔜 구현 예정 |
| 하객 관리 | 하객 목록 관리 및 좌석 배치 | 🔜 구현 예정 |
| 커뮤니티 | 웨딩 준비 팁·인기글 공유 | 🔜 구현 예정 |

---

## 🛠 기술 스택

### Backend
- **Framework**: Spring Boot 3.2.3 (Java 17)
- **보안**: Spring Security + JWT (jjwt 0.12.3), BCrypt(strength=12)
- **Rate Limiting**: Bucket4j + Caffeine (분당 10회, IP 기반)
- **DB**: MySQL 8.x (FK 없음 — 참조 무결성은 Service 레이어 관리)
- **ORM**: Spring Data JPA (Hibernate)
- **API 문서**: SpringDoc OpenAPI (개발 환경에서만 활성화)

### Frontend
- **Framework**: Flutter (Dart ^3.5.4)
- **상태 관리**: Flutter Riverpod 2.x
- **HTTP 클라이언트**: Dio (인터셉터 기반 자동 토큰 갱신)
- **라우팅**: go_router
- **토큰 저장**: flutter_secure_storage (네이티브) / localStorage (웹)
- **환경 설정**: flutter_dotenv (.env / .env.production)
- **폰트**: google_fonts (Playfair Display)
- **디자인**: Dark Glassmorphism (`#0D0D1A → #1B0929`, BackdropFilter blur:20)

---

## 📁 프로젝트 구조

```
weddy/
├── weddy-backend-1.0/weddy/
│   └── src/main/java/com/project/weddy/
│       ├── common/
│       │   ├── response/       # ApiResponse 공통 응답
│       │   ├── exception/      # GlobalExceptionHandler, ErrorCode
│       │   ├── security/       # JWT, SecurityConfig, RateLimitFilter
│       │   └── init/           # DataInitializer (@Profile("dev"))
│       └── domain/
│           ├── user/           # 인증 (회원가입, 로그인, 토큰 갱신)
│           ├── couple/         # 커플 연결 (초대코드)
│           └── checklist/      # 체크리스트 CRUD
│
└── weddy-frontend-1.0/weddy/
    └── lib/
        ├── core/
        │   ├── network/        # DioClient, ApiResponse, TokenStorage
        │   └── router/         # AppRouter (go_router)
        └── features/
            ├── auth/           # 로그인, 회원가입, AuthNotifier
            ├── home/           # 홈 화면
            ├── couple/         # 커플 연결 화면
            ├── checklist/      # 체크리스트 화면
            └── wedding_setup/  # 결혼 예정일 설정
```

---

## 🗃 DB 설계 원칙

- **PK**: auto-increment 금지 → `SecureRandom` 14자리 숫자 문자열 (`oid`)
- **FK**: 전부 제거 → 관계 컬럼에 `INDEX`만 부여, 참조 무결성은 Service 트랜잭션으로 관리
- **테이블 접두사**: `weddy_`
- **문자셋**: 전 테이블 `utf8mb4_unicode_ci` 통일

---

## 🚀 시작하기

### 사전 요구사항

- Java 17+
- MySQL 8.x
- Flutter SDK 3.x
- Dart SDK ^3.5.4

### Backend 실행

```bash
# 1. DB 초기화 (MySQL 클라이언트)
cd weddy-backend-1.0/weddy
source scripts/schema.sql
source scripts/data.sql

# 2. 개발 서버 실행
./gradlew bootRun --args='--spring.profiles.active=dev'
```

> `application-dev.yml` 기준: DB `weddy/weddy01`, JWT secret 내장값, `show-sql=true`

### Frontend 실행

```bash
cd weddy-frontend-1.0/weddy

# .env 파일 생성 (예시)
echo "API_BASE_URL=http://10.0.2.2:8080/api/v1" > .env

# 의존성 설치 및 실행
flutter pub get
flutter run
```

---

## 🔑 테스트 계정 (dev 환경 자동 생성)

| 아이디 | 비밀번호 | 역할 | 상태 |
|--------|----------|------|------|
| `groom_kim` | `1234` | 신랑 | 커플 연결됨 |
| `bride_lee` | `1234` | 신부 | 커플 연결됨 |
| `solo_park` | `1234` | 신부 | 미연결 |

---

## 📡 주요 API 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/api/v1/auth/signup` | 회원가입 |
| POST | `/api/v1/auth/login` | 로그인 |
| POST | `/api/v1/auth/refresh` | 토큰 갱신 |
| POST | `/api/v1/auth/logout` | 로그아웃 |
| GET | `/api/v1/users/me` | 내 정보 조회 |
| PATCH | `/api/v1/users/me/wedding-date` | 결혼 예정일 설정 |
| POST | `/api/v1/couples/connect` | 커플 연결 (초대코드) |
| GET | `/api/v1/couples/me` | 커플 정보 조회 |
| DELETE | `/api/v1/couples/me` | 커플 해제 |
| GET | `/api/v1/checklists` | 체크리스트 전체 조회 |
| POST | `/api/v1/checklists` | 체크리스트 생성 |
| DELETE | `/api/v1/checklists/{oid}` | 체크리스트 삭제 |
| POST | `/api/v1/checklists/{oid}/items` | 항목 추가 |
| PATCH | `/api/v1/checklists/{oid}/items/{itemOid}` | 항목 수정 |
| DELETE | `/api/v1/checklists/{oid}/items/{itemOid}` | 항목 삭제 |

> 모든 API는 `{ "success": true/false, "message": "...", "data": {...} }` 형식으로 응답합니다.

---

## 🔒 보안

- **비밀번호**: BCrypt(strength=12)
- **JWT**: AccessToken 24h + RefreshToken 7d (DB Rotation)
- **Rate Limiting**: IP 기반 분당 최대 10회 (로그인·회원가입·토큰갱신)
- **CORS**: 명시적 오리진 허용 (와일드카드 미사용)
- **사용자 열거 방지**: 로그인 실패 시 ID·비밀번호 구분 없이 `UNAUTHORIZED` 반환

---

## 📝 라이선스

© 2025 CJH. All rights reserved.
