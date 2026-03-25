# 6단계 — 일정 관리 & 웨딩 관리(로드맵) BE 구현

## 구현 완료 (2026-03-20)

### Schema
- weddy_schedules: oid PK, owner_oid, title, category, is_all_day, start_at, end_at, location, alert_before, source_type, source_oid
- weddy_roadmap_steps: oid PK, owner_oid, step_type, title, is_done, due_date, has_due_date, sort_order, details(TEXT/JSON)
- weddy_roadmap_hall_tours: oid PK, step_oid INDEX, hall_name, tour_date, rental_fee, meal_price, min_guests, memo
- weddy_roadmap_travel_stops: oid PK, step_oid INDEX, stop_order, city

### ErrorCode 추가
- SCHEDULE_NOT_FOUND("SCHEDULE_001")
- ROADMAP_STEP_NOT_FOUND("ROADMAP_001")
- ROADMAP_HALL_TOUR_NOT_FOUND("ROADMAP_002")
- ROADMAP_STEP_LIMIT_EXCEEDED("ROADMAP_003")

### 일정 도메인
- domain/schedule/entity/Schedule.java
- domain/schedule/repository/ScheduleRepository.java (deleteBySourceOid 포함)
- domain/schedule/dto/request: CreateScheduleRequest, UpdateScheduleRequest
- domain/schedule/dto/response/ScheduleResponse.java (from() 팩토리)
- domain/schedule/service/ScheduleService.java
  - getOwnerOid() 패턴 동일
  - getSchedules(year, month) — null이면 전체, 지정 시 YearMonth 범위 쿼리
  - createScheduleInternal(ownerOid, title, category, startAt, sourceType, sourceOid) — 내부 자동 생성
- domain/schedule/controller/ScheduleController.java (/api/v1/schedules)

### 로드맵 도메인
- domain/roadmap/entity: RoadmapStep, HallTour, TravelStop
- domain/roadmap/repository: RoadmapStepRepository, HallTourRepository, TravelStopRepository
- domain/roadmap/dto/request: CreateRoadmapStepRequest, UpdateRoadmapStepRequest, CreateHallTourRequest, AddTravelStopRequest
- domain/roadmap/dto/response: RoadmapStepResponse, HallTourResponse (totalMealCost 자동계산), TravelStopResponse
- domain/roadmap/service/RoadmapService.java
  - BUDGET 단계 생성/수정 시 details JSON에서 totalBudget 파싱 → BudgetService.upsertSettingsInternal() 자동 연동
  - addHallTour: scheduleTitle != null && tourDate != null 이면 scheduleService.createScheduleInternal() 자동 호출
  - deleteHallTour: scheduleRepository.deleteBySourceOid(tourOid) 연쇄 삭제
  - deleteStep: hallTourRepo.deleteByStepOid → travelStopRepo.deleteByStepOid → scheduleRepo.deleteBySourceOid(stepOid) → stepRepo.delete 순서
- domain/roadmap/controller/RoadmapController.java (/api/v1/roadmap) — 11개 엔드포인트

### BudgetService 추가
- upsertSettingsInternal(ownerOid, totalAmount) — RoadmapService 내부 호출용

### DataInitializer 추가
- createRoadmapSteps(): 커플(20000000000001) 로드맵 9단계 (OID 8000000000000X)
- createSchedules(): 테스트 일정 3개 (OID 6000000000000X)

### 테스트 데이터 OID
| 엔티티 | OID 범위 |
|--------|---------|
| 로드맵 단계 | 80000000000001 ~ 80000000000009 |
| 일정 | 60000000000001 ~ 60000000000003 |

### 핵심 패턴
- UpdateScheduleRequest: Boolean isAllDay (박싱 타입) → Lombok이 getIsAllDay() 생성
- syncBudgetSettings(): JsonProcessingException catch → warn 로그만, 트랜잭션 유지
- TravelStop.stopOrder 자동 증가: countByStepOid() + 1
- SecurityConfig: anyRequest().authenticated() 이미 적용 — 별도 경로 등록 불필요
