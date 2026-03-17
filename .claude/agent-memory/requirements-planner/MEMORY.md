# Weddy Project - Requirements Planner Memory

## 프로젝트 기본 정보
- 앱명: Weddy (결혼 준비 앱)
- Backend 경로: D:\workspace\weddy\weddy-backend-1.0\weddy
- Frontend 경로: D:\workspace\weddy\weddy-frontend-1.0\weddy
- Backend: Spring Boot 3.2.3, Java 17, Gradle, JPA, Spring Security, MySQL
- Frontend: Flutter SDK 3.5.4, Riverpod (StateNotifier) + GoRouter + Dio
- 패키지명(BE): com.project.weddy
- DB: MySQL 8.x

## MVP 핵심 기능 (확정)
1. 사용자 로그인 및 파트너 연결 (신랑-신부 연결, 초대 코드 방식)
2. 웨딩 체크리스트 (할 일 관리) — 구현 완료
3. 예산 관리 (지출 내역 기록) — 5단계 구현 대상
4. 업체(홀, 스튜디오 등) 즐겨찾기 — 6단계 구현 대상

## 실제 코드 구조 (파일 직접 확인 완료, 2026-03-17)

### 백엔드 패키지 구조 (domain, features 아님)
```
com.project.weddy.domain.{checklist|couple|user|budget}/
  controller/, dto/request/, dto/response/, entity/, repository/, service/
com.project.weddy.common.{exception|init|response|security|util}/
```

### 프론트엔드 디렉터리 구조
```
lib/features/{feature}/
  data/model/{feature}_model.dart, {feature}_item_model.dart
  presentation/notifier/{feature}_notifier.dart
  presentation/screen/{feature}_screen.dart
lib/core/network/, lib/core/storage/, lib/core/router/app_router.dart
```

## 설계 결정 사항 (2026-03-10 이후 확인 완료)
- 인증: JWT (AccessToken 24h / RefreshToken 7일)
- API 인증: Bearer Token 방식
- 커플 연결: 초대 코드 (WED-XXXXXX 형식)
- 공통 응답: ApiResponse<T> 래퍼 (success, message, data, errorCode)
- 금액 단위: 원(KRW), BIGINT → Java long → Dart int (64비트)
- 다크 글래스모피즘 테마: #0D0D1A→#1B0929, BackdropFilter blur:20

## 주요 테이블 구조 (schema.sql 확인 완료)
- weddy_users, weddy_couples(total_budget BIGINT), weddy_checklists(owner_oid)
- weddy_checklist_items(is_done, due_date, sort_order)
- weddy_budgets(couple_oid, category, planned_amount) — 커플 전용
- weddy_budget_items(budget_oid, title, amount, paid_at, memo)
- weddy_vendors, weddy_couple_favorites, weddy_refresh_tokens

## 예산 기능 설계 결정 (2026-03-17)
- 예산은 커플 전용 (솔로 지원 안 함) → 커플 미연결 시 403 BUDGET_COUPLE_REQUIRED
- spentAmount 집계: 인메모리 스트림 합산 (MVP 규모 충분)
- summary 엔드포인트: GET /api/v1/budgets/summary
  응답: totalBudget(couples.total_budget), plannedAmount합산, spentAmount합산, usageRate
- JPQL JOIN 대신 Native Query로 SUM 집계 (FK 없는 구조 때문)
- /summary 경로가 /{oid} 보다 먼저 매핑되는지 확인 필요

## 미결 사항 (향후 확인 필요)
- Couple.java 엔티티에 totalBudget 필드 매핑 여부 확인 필요
- intl 패키지 pubspec.yaml 추가 여부 (금액 포매팅용)
- OAuth2 소셜 로그인 범위 (Kakao/Google) 구현 여부
- 파일 업로드 (영수증 이미지) 스토리지 선택: S3 vs 로컬
