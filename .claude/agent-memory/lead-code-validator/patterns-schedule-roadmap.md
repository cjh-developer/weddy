# 일정/웨딩관리 도메인 패턴 (6단계 검증 결과)

## Details JSON key 규칙 (반드시 준수)
- BUDGET: `totalBudget` (syncBudgetSettings, DataInitializer, FE 모두 통일)
- SANGGYEONRYE: `restaurantName`, `pricePerPerson`, `guestCount`, `totalAmount`, `extraItems`, `date`
- TRAVEL: `purchaseSource`, `departure`, `destination`, `stopovers`, `flightInfo`, `airline`
- HALL: details는 서버에 저장되지만 FE에서 읽지 않음 (투어 목록은 별도 API)
- 위 key 불일치는 DataInitializer 초기 데이터와 실제 앱 데이터 간 혼선 유발

## [CRITICAL] RoadmapStep.update() dueDate 명시적 null 처리
- update() 메서드에서 dueDate가 null이면 기존 값 유지 → hasDueDate=false 설정 후 dueDate를 null로 지울 방법 없음
- 해결: clearDueDate boolean 파라미터 추가 → true이면 null 설정, false이면 기존 로직
- UpdateRoadmapStepRequest에 clearDueDate 필드 추가, FE에서 !_hasDueDate를 clearDueDate로 전달

## [PATTERN] countByOwnerOid 이중 호출 주의
- createStep()에서 제한 체크와 sortOrder 계산에 countByOwnerOid()를 두 번 호출하면 매번 쿼리 실행
- 반드시 결과를 지역 변수에 캐시하여 재사용

## [PATTERN] 에러코드 세분화 — 경유지 NotFound 오류
- TravelStop 미존재 시 ROADMAP_STEP_NOT_FOUND로 반환하면 클라이언트가 잘못된 메시지를 표시
- ROADMAP_TRAVEL_STOP_NOT_FOUND(ROADMAP_004) 추가됨

## [PATTERN] alertBefore 값 형식 (FE/BE 통일)
- FE alertOptions: 10MINUTES | 30MINUTES | 1HOUR | 1DAY | 3DAYS | 1WEEK | 빈 문자열(없음)
- BE Entity/Schema에 NONE|WEEK|THREE_DAYS 형식이 있었으나 FE 기준으로 수정됨
- alert_before 컬럼 길이 VARCHAR(20) — 충분

## [PATTERN] _onSave에서 toggleDone 비동기 호출 시 mounted 체크
- updateStep 완료 후 toggleDone을 연속으로 호출할 때 ok 확인 + mounted 체크 필수
- updateStep 실패 시 toggleDone이 실행되어서는 안 됨

## ScheduleNotifier deleteSchedule 낙관적 삭제 패턴
- 낙관적 삭제 후 성공 시 loadSchedules() 추가 호출 → 서버 데이터와 동기화 (정상)
- 실패 시 state = current → state = Error 두 번 할당하여 Error 상태 노출 (정상)

## RoadmapService syncBudgetSettings 트랜잭션 예외 무시 설계
- BUDGET 단계 details 파싱 실패 시 경고 로그만 남기고 전체 트랜잭션 유지
- 의도적 설계이므로 catch(JsonProcessingException) 절 유지가 올바름
