# Weddy Project - Requirements Planner Memory

## 프로젝트 기본 정보
- 앱명: Weddy (결혼 준비 앱)
- Backend 경로: D:\workspace\weddy\weddy-backend-1.0\weddy
- Frontend 경로: D:\workspace\weddy\weddy-frontend-1.0\weddy
- Backend: Spring Boot 3.2.3, Java 17, Gradle, JPA, Spring Security, MySQL
- Frontend: Flutter SDK 3.5.4, Riverpod 상태관리 예정
- 패키지명(BE): com.project.weddy
- DB: MySQL 8.x

## MVP 핵심 기능 (확정)
1. 사용자 로그인 및 파트너 연결 (신랑-신부 연결, 초대 코드 방식)
2. 웨딩 체크리스트 (할 일 관리)
3. 예산 관리 (지출 내역 기록)
4. 업체(홀, 스튜디오 등) 즐겨찾기

## 설계 결정 사항 (2026-03-10)
- 인증: JWT (AccessToken 30분 / RefreshToken 7일)
- API 인증: Bearer Token 방식
- 커플 연결: 초대 코드 6자리 (WED-XXXXXX 형식)
- 공통 응답: ApiResponse<T> 래퍼 (success, message, data, errorCode)
- 페이지네이션: 0-based page, content/page/size/totalElements/totalPages/isFirst/isLast
- 금액 단위: 원(KRW), BIGINT 타입
- Soft Delete: users 테이블에 is_deleted 컬럼

## 주요 테이블 목록
users, couples, checklists, checklist_items, budgets, budget_items, vendors, couple_favorites

## 상세 설계 문서 참조
- 아키텍처 전체 설계: 2026-03-10 대화에서 제공 (DB ERD, BE 구조, FE 구조, API 명세, 공통 응답 규격)

## 미결 사항 (향후 확인 필요)
- OAuth2 소셜 로그인 범위 (Kakao/Google) 구현 여부
- 파일 업로드 (영수증 이미지) 스토리지 선택: S3 vs 로컬
- 푸시 알림 (체크리스트 마감일 알림) 포함 여부
- 다국어 지원 여부
