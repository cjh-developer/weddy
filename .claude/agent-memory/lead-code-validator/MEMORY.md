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

## Files Reviewed
- `lib/main.dart` - WidgetsFlutterBinding.ensureInitialized() 추가됨, unauthorizedCallbackProvider override 추가됨
- `lib/core/network/api_response.dart` - copyWith clearData flag 추가됨
- `lib/core/network/page_response.dart` - isLast 경계 조건 명확화됨
- `lib/core/network/api_exception.dart` - unused param 주석 추가됨
- `lib/core/network/dio_client.dart` - sendTimeout, 환경분리, onUnauthorized 콜백 패턴, unauthorizedCallbackProvider 추가됨
- `lib/core/storage/token_storage.dart` - static const 제거, iOSOptions 추가됨
- `lib/core/router/app_router.dart` - ref.onDispose로 GoRouter+_AuthStateListenable dispose 추가됨
- `lib/features/auth/presentation/notifier/auth_notifier.dart` - DioException catch 제거, dio import 제거, authLogoutCallbackProvider 추가됨
- `lib/features/auth/presentation/screen/sign_up_screen.dart` - 중복 역할 null 체크 제거됨

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
