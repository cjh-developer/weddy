# Security Advisor Memory - Weddy Project
# 상세 내용: security-findings.md 참조

## 핵심 보안 패턴 (확인됨)
- refreshToken 검증 순서: isTokenExpired -> validateToken 나중 (올바름)
- JWT SecurityContext principal = userOid (String)
- 토큰 저장: flutter_secure_storage + EncryptedSharedPreferences + Keychain
- BCrypt(cost=12), JWT Secret 환경변수 필수화, RateLimitFilter(분당 10회) 적용 완료
- 타이밍 공격 방지: user==null 시에도 passwordEncoder.encode() 실행

## 미해결 취약점 요약 (상세: security-findings.md)
### HIGH
- AttachmentService.list() IDOR 소유권 검증 완전 부재 (7단계)
- application.yml 기본 프로파일에 평문 자격증명 하드코딩 (7단계)
### MEDIUM (미수정 누적)
- /couples/connect Rate Limit 미적용, 커플 Race Condition, ChecklistService TOCTOU
- 각종 DTO @Pattern 미적용(category/title/memo), 금액 상한 미설정
- AttachmentService: 파일명 미정제, Race Condition, 경계 미검증, Rate Limit 미적용
- 6단계: CreateScheduleRequest/RoadmapStepRequest/HallTour 입력 검증 누락
- [10단계 신규] GuestResponse.groupOid 평문 노출 (MEDIUM)
- [10단계 신규] GuestSummaryResponse.totalGiftAmount 정수 오버플로우 위험 (MEDIUM)
- [10단계 신규] DataInitializer 하객 그룹 5개 모두 is_default=true: createGroup API에서 기본 그룹 생성 시에도 isDefault=false 강제됨 — 실제 보안 문제 없음(서비스에서 강제 false), INFO
### LOW
- accessToken 만료 24시간 (OWASP 권고 15-30분)
- guestSummaryProvider autoDispose — 로그아웃 시 invalidate 미수행 (데이터 잔존 가능, LOW)
- 하객 이름 name @Pattern 미적용 — 특수문자/이모지/스크립트 태그 허용 (LOW)

## 잘 구현된 보안 패턴 (10단계 추가)
- [10단계] findGroupWithOwnerCheck / findGuestWithOwnerCheck 단일 findById+소유권검증 일관 적용
- [10단계] getOwnerOid() 패턴 — 커플/솔로 분기 일관 적용
- [10단계] @Transactional 클래스 레벨 + readOnly 조회 메서드 적절히 분리
- [10단계] deleteGroup() clearGroupOid() 후 delete() — @Transactional 보장
- [10단계] PathVariable @Pattern(^[0-9]{14}$) 전 엔드포인트 적용
- [10단계] sort @Pattern 화이트리스트 컨트롤러에서 검증
- [10단계] GuestGroupResponse 에 ownerOid 미포함, GuestResponse에 ownerOid 미포함
- [10단계] 그룹 최대 20개 / 하객 최대 500명 제한 구현
- [10단계] auth_notifier.dart 로그아웃 시 guestGroupNotifier + guestNotifier reset() 모두 연결됨
- [10단계] 기본 그룹 수정/삭제 차단 로직 구현됨

## 반복 패턴 경고
- 조회 GET API에서 소유권 검증 누락 반복 발생 (list API 주의)
- application.yml 기본 프로파일에 평문 자격증명 잔존 패턴 반복
- 새 API 추가 시 RateLimitFilter.RATE_LIMITED_PATHS 업데이트 누락 위험
- FK 없는 아키텍처에서 check-then-act 패턴 → Race Condition 위험
- 응답 DTO에 내부 관계 컬럼(OID류) 노출 반복 발생

## 파일 위치 참조
- Backend: D:/workspace/weddy/weddy-backend-1.0/weddy
- Frontend: D:/workspace/weddy/weddy-frontend-1.0/weddy
- 핵심 파일: common/security/{JwtTokenProvider,JwtAuthenticationFilter,RateLimitFilter,SecurityConfig}.java
- 상세 보안 부채 목록: security-findings.md
