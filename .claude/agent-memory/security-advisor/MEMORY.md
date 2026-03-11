# Security Advisor Memory - Weddy Project

## 핵심 보안 패턴 (확인됨)
- refreshToken 검증 순서: isTokenExpired 먼저 -> validateToken 나중 (UserService.refreshToken에서 올바르게 구현됨)
- JWT SecurityContext principal = userOid (String) - JwtAuthenticationFilter에서 설정
- 토큰 저장: flutter_secure_storage + EncryptedSharedPreferences(Android) + Keychain(iOS) - 올바르게 구현됨
- 401 강제 로그아웃: unauthorizedCallbackProvider -> AuthNotifier.logout() 연결 - 올바르게 구현됨
- GlobalExceptionHandler에서 스택트레이스 미노출 - 올바르게 구현됨
- BCrypt(cost=12) 적용 완료 (2026-03-12 패치) - Sha512PasswordEncoder.java 완전히 제거됨
- JWT Secret 폴백 제거 완료 (2026-03-12 패치) - ${JWT_SECRET} 환경변수 필수화, JwtTokenProvider에서 32자 미만 시 IllegalStateException
- RateLimitFilter 구현 완료 (2026-03-12 패치) - Bucket4j + Caffeine, 분당 10회, login/signup/refresh 적용
- CORS 명시적 오리진 완료 (2026-03-12 패치) - ${CORS_ALLOWED_ORIGINS} 환경변수 기반
- 사용자 열거 방지 완료 (2026-03-12 패치) - login()에서 user==null/password불일치 동일 UNAUTHORIZED 응답, 타이밍공격 방어

## 현재 미해결 취약점 (2026-03-12 패치 검토 후 잔여)

### HIGH
- RateLimitFilter IP 스푸핑: X-Forwarded-For 헤더 조작으로 Rate Limit 우회 가능
  - clientKey = getClientIp() + ":" + path 에서 X-Forwarded-For 첫 번째 값을 신뢰
  - Caffeine expireAfterWrite(1분) 버킷 만료 후 분당 10회 리셋 → 1분마다 10회 = 600회/시간 허용
  - 운영환경 인프라 레벨 제어(주석 존재)로 보완 필요

### MEDIUM
- DataInitializer 약한 비밀번호 "1234" - @Profile("!test") 이므로 dev/staging/prod 모두 실행됨
  - BCrypt로 해시되어 저장되나 비밀번호 자체가 예측 가능 - 운영환경 배포 전 제거 또는 @Profile("dev") 전환 필요
- application-dev.yml DB 평문 자격증명: weddy/weddy01 하드코딩 (개발 환경 한정이므로 MEDIUM)
- application-dev.yml show-sql: true - 개발 환경 전용이나 운영 프로파일 실수 적용 위험
- Swagger UI 인증 없이 노출: PUBLIC_PATHS에 /swagger-ui/**, /v3/api-docs/** 포함 (운영 배포 전 조치 필요)
- SignUpRequest handPhone 형식 검증 없음: @Pattern(regexp="^01[016789]-?\\d{3,4}-?\\d{4}$") 미적용
- userId 허용문자 미제한: 영숫자+언더스코어 외 문자 허용 가능성

### LOW
- accessToken 만료시간 24시간(86400000ms): OWASP 권고 15-30분 대비 너무 김
- 도메인 정보 로그 노출: userId, userOid를 INFO 레벨로 로깅 (가명정보이나 운영 로그 관리 주의)
- DataInitializer 테스트 계정 OID 고정값(10000000000001 등): 순차적 예측 가능성 있음

### INFO (미해결, 백로그)
- .env 파일 gitignore 미적용 상태 미확인 (Flutter 쪽 재검토 필요)
- iOS Keychain accessibility: first_unlock -> after_first_unlock_this_device_only 권고
- 인증서 피닝 (Flutter - 운영 배포 전)

## 보안 부채 항목 (2026-03-12 업데이트)
- [x] 비밀번호 해시 알고리즘 BCrypt(12) 마이그레이션 완료
- [x] Rate Limiting 구현 완료 (Bucket4j + Caffeine)
- [x] 운영환경 JWT Secret 환경변수 주입 강제화 완료
- [x] 운영환경 CORS 화이트리스트 구성 완료
- [ ] DataInitializer @Profile("dev") 전환 필요
- [ ] Swagger UI 운영환경 비활성화 또는 인증 적용
- [ ] handPhone 입력 검증 패턴 추가
- [ ] accessToken 만료시간 단축 (24시간 → 15-30분)
- [ ] 인증서 피닝 (Flutter - 운영 배포 전)

## 잘 구현된 패턴
- RefreshToken DB 저장 + 재발급 시 기존 토큰 무효화 (토큰 탈취 방어)
- OidGenerator SecureRandom 사용 - IDOR 예측 불가
- GlobalExceptionHandler 스택트레이스 미노출 (500 에러 메시지 일반화)
- flutter_secure_storage EncryptedSharedPreferences + Keychain 올바른 사용
- JPA 사용으로 SQL Injection 기본 방어
- BCrypt(cost=12) 비밀번호 해시 - 성능/보안 균형 적절
- 타이밍 공격 방지: 사용자 미존재 시에도 passwordEncoder.encode() 실행
- JwtTokenProvider 생성자에서 32자 미만 secret 즉시 실패 처리
- application.yml에서 JWT_SECRET 환경변수 폴백 없이 필수화
- RateLimitFilter @Order(1)로 SecurityFilterChain 앞에서 실행
- isTokenExpired -> validateToken 순서 올바르게 유지됨

## 파일 위치 참조
- Backend: D:/workspace/weddy/weddy-backend-1.0/weddy
- Frontend: D:/workspace/weddy/weddy-frontend-1.0/weddy
- 핵심 보안 파일들:
  - JwtTokenProvider.java: common/security/ (Sha512PasswordEncoder.java 삭제됨)
  - JwtAuthenticationFilter.java: common/security/
  - RateLimitFilter.java: common/security/ (신규 추가됨)
  - SecurityConfig.java: common/security/
  - UserService.java: domain/user/service/
  - DataInitializer.java: common/init/
  - application.yml: src/main/resources/
  - application-dev.yml: src/main/resources/
  - token_storage.dart: lib/core/storage/
  - dio_client.dart: lib/core/network/
