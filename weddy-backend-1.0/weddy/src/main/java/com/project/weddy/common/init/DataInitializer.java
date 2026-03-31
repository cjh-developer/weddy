package com.project.weddy.common.init;

import com.project.weddy.domain.user.entity.User;
import com.project.weddy.domain.user.entity.UserRole;
import com.project.weddy.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * 개발 환경 전용 테스트 데이터 초기화 컴포넌트.
 *
 * <p>앱 기동 시 테스트 데이터가 없으면 자동으로 생성한다. (멱등 보장)
 *
 * <h3>생성되는 테스트 계정 (비밀번호 모두 "1234")</h3>
 * <ul>
 *   <li>groom_kim / 김지훈 (GROOM) — oid 10000000000001</li>
 *   <li>bride_lee / 이수연 (BRIDE) — oid 10000000000002</li>
 *   <li>solo_park / 박민지 (BRIDE, 커플 미연결) — oid 10000000000003</li>
 * </ul>
 *
 * <h3>생성되는 커플 데이터</h3>
 * <ul>
 *   <li>김지훈 + 이수연 커플 (2026-10-15 예식, 예산 5천만원)</li>
 *   <li>체크리스트 3개 카테고리, 항목 12개</li>
 *   <li>예산 4개 카테고리, 지출 항목 10개</li>
 *   <li>즐겨찾기 3개 (커플), 1개 (솔로)</li>
 * </ul>
 *
 * <p>{@code @Profile("dev")} 로 개발 환경에서만 실행된다.
 */
@Slf4j
@Component
@Profile("dev")
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JdbcTemplate jdbc;

    @Override
    @Transactional
    public void run(String... args) {
        log.info("[DataInitializer] 테스트 데이터 초기화 시작...");

        createUsers();
        createCouple();
        createChecklists();
        createBudgets();
        createBudgetSettings();
        createVendors();   // 즐겨찾기보다 먼저 (FK 없지만 논리적 순서)
        createFavorites();
        createRoadmapSteps();
        createSchedules();
        createGuestGroups();
        createGuests();

        log.info("[DataInitializer] 테스트 데이터 초기화 완료.");
    }

    // =========================================================
    // 사용자
    // =========================================================

    private void createUsers() {
        createUserIfAbsent("10000000000001", "groom_kim", "1234",
                "김지훈", "010-1234-5678", "jh.kim@weddy.com", UserRole.GROOM, "WED-GRM001");
        createUserIfAbsent("10000000000002", "bride_lee", "1234",
                "이수연", "010-9876-5432", "sy.lee@weddy.com", UserRole.BRIDE, "WED-BRD001");
        createUserIfAbsent("10000000000003", "solo_park", "1234",
                "박민지", "010-5555-7777", "mj.park@weddy.com", UserRole.BRIDE, "WED-SLO001");
    }

    private void createUserIfAbsent(String oid, String userId, String rawPassword,
                                    String name, String handPhone, String email,
                                    UserRole role, String inviteCode) {
        if (userRepository.existsByUserId(userId)) {
            log.debug("[DataInitializer] 기존 계정 건너뜀: {}", userId);
            return;
        }
        User user = User.builder()
                .oid(oid)
                .userId(userId)
                .password(passwordEncoder.encode(rawPassword))
                .name(name)
                .handPhone(handPhone)
                .email(email)
                .role(role)
                .inviteCode(inviteCode)
                .build();
        userRepository.save(user);
        log.info("[DataInitializer] 계정 생성: {} ({})", userId, oid);
    }

    // =========================================================
    // 커플
    // =========================================================

    private void createCouple() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_couples WHERE oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 커플 데이터 이미 존재, 건너뜀.");
            return;
        }
        jdbc.update("""
                INSERT INTO weddy_couples (oid, groom_oid, bride_oid, wedding_date, total_budget)
                VALUES (?, ?, ?, ?, ?)
                """,
                "20000000000001",
                "10000000000001",   // groom_kim
                "10000000000002",   // bride_lee
                "2026-10-15",
                50_000_000L);
        log.info("[DataInitializer] 커플 생성: 김지훈 + 이수연 (2026-10-15)");
    }

    // =========================================================
    // 체크리스트
    // =========================================================

    private void createChecklists() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_checklists WHERE owner_oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 체크리스트 데이터 이미 존재, 건너뜀.");
            return;
        }

        // --- 체크리스트: 예식장 준비 ---
        insertChecklist("30000000000001", "예식장 준비", "HALL");
        insertChecklistItem("31000000000001", "30000000000001", "웨딩홀 후보 견적 받기",         true,  null,           1);
        insertChecklistItem("31000000000002", "30000000000001", "웨딩홀 계약 완료",              true,  null,           2);
        insertChecklistItem("31000000000003", "30000000000001", "청첩장 디자인 선택",            false, "2026-06-01",   3);
        insertChecklistItem("31000000000004", "30000000000001", "청첩장 발송 명단 작성",         false, "2026-07-01",   4);
        insertChecklistItem("31000000000005", "30000000000001", "식순 및 사회자 섭외",           false, "2026-08-01",   5);

        // --- 체크리스트: 스드메 ---
        insertChecklist("30000000000002", "스드메 준비", "BEAUTY");
        insertChecklistItem("31000000000006", "30000000000002", "스튜디오 촬영 예약",            true,  null,           1);
        insertChecklistItem("31000000000007", "30000000000002", "드레스 1차 핏팅",               true,  null,           2);
        insertChecklistItem("31000000000008", "30000000000002", "드레스 2차 핏팅",               false, "2026-05-15",   3);
        insertChecklistItem("31000000000009", "30000000000002", "메이크업 트라이얼",             false, "2026-09-01",   4);

        // --- 체크리스트: 신혼여행 ---
        insertChecklist("30000000000003", "신혼여행 준비", "HONEYMOON");
        insertChecklistItem("31000000000010", "30000000000003", "여행지 결정 (발리)",            true,  null,           1);
        insertChecklistItem("31000000000011", "30000000000003", "항공권 예약",                   false, "2026-08-01",   2);
        insertChecklistItem("31000000000012", "30000000000003", "호텔·리조트 예약",              false, "2026-08-15",   3);

        log.info("[DataInitializer] 체크리스트 3개, 항목 12개 생성 완료.");
    }

    private void insertChecklist(String oid, String title, String category) {
        jdbc.update("""
                INSERT INTO weddy_checklists (oid, owner_oid, title, category)
                VALUES (?, ?, ?, ?)
                """, oid, "20000000000001", title, category);
    }

    private void insertChecklistItem(String oid, String checklistOid, String content,
                                     boolean isDone, String dueDate, int sortOrder) {
        jdbc.update("""
                INSERT INTO weddy_checklist_items
                    (oid, checklist_oid, content, is_done, due_date, sort_order)
                VALUES (?, ?, ?, ?, ?, ?)
                """, oid, checklistOid, content, isDone ? 1 : 0, dueDate, sortOrder);
    }

    // =========================================================
    // 예산
    // =========================================================

    private void createBudgets() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_budgets WHERE owner_oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 예산 데이터 이미 존재, 건너뜀.");
            return;
        }

        // --- 예산: 예식비 ---
        insertBudget("40000000000001", "예식비", 15_000_000L);
        insertBudgetItem("41000000000001", "40000000000001", "웨딩홀 대관료",        12_000_000L, "2026-03-01", "계약금 포함 전액 납부");
        insertBudgetItem("41000000000002", "40000000000001", "답례품",                1_500_000L, null,         "100개 주문 예정");
        insertBudgetItem("41000000000003", "40000000000001", "사회자 섭외비",          500_000L, null,         null);

        // --- 예산: 스드메 ---
        insertBudget("40000000000002", "스드메", 10_000_000L);
        insertBudgetItem("41000000000004", "40000000000002", "스튜디오 촬영비",       3_500_000L, "2026-02-15", "야외 촬영 포함 패키지");
        insertBudgetItem("41000000000005", "40000000000002", "웨딩드레스",            4_200_000L, "2026-02-20", "본식 드레스 + 촬영 드레스");
        insertBudgetItem("41000000000006", "40000000000002", "헤어·메이크업",         1_800_000L, null,         "트라이얼 1회 포함");

        // --- 예산: 신혼여행 ---
        insertBudget("40000000000003", "신혼여행", 8_000_000L);
        insertBudgetItem("41000000000007", "40000000000003", "항공권 (발리 왕복 2인)", 2_400_000L, null,         "직항 비즈니스석");
        insertBudgetItem("41000000000008", "40000000000003", "숙소 (7박)",             3_500_000L, null,         "풀빌라 리조트");

        // --- 예산: 기타 ---
        insertBudget("40000000000004", "기타", 5_000_000L);
        insertBudgetItem("41000000000009", "40000000000004", "예복 (신랑)",           1_200_000L, "2026-04-10", null);
        insertBudgetItem("41000000000010", "40000000000004", "혼수 가전",             3_200_000L, null,         "냉장고, 세탁기");

        log.info("[DataInitializer] 예산 4개 카테고리, 항목 10개 생성 완료.");
    }

    private void insertBudget(String oid, String category, long plannedAmount) {
        jdbc.update("""
                INSERT INTO weddy_budgets (oid, owner_oid, category, planned_amount)
                VALUES (?, ?, ?, ?)
                """, oid, "20000000000001", category, plannedAmount);
    }

    private void insertBudgetItem(String oid, String budgetOid, String title,
                                  long amount, String paidAt, String memo) {
        jdbc.update("""
                INSERT INTO weddy_budget_items (oid, budget_oid, title, amount, paid_at, memo)
                VALUES (?, ?, ?, ?, ?, ?)
                """, oid, budgetOid, title, amount, paidAt, memo);
    }

    // =========================================================
    // 전체 예산 설정
    // =========================================================

    private void createBudgetSettings() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_budget_settings WHERE owner_oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 예산 설정 데이터 이미 존재, 건너뜀.");
            return;
        }
        jdbc.update("""
                INSERT INTO weddy_budget_settings (oid, owner_oid, total_amount)
                VALUES (?, ?, ?)
                """,
                "50000000000001",
                "20000000000001",
                50_000_000L);
        log.info("[DataInitializer] 예산 설정 생성: ownerOid=20000000000001, 5천만원");
    }

    // =========================================================
    // 웨딩 업체
    // =========================================================

    private void createVendors() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_vendors",
                Integer.class);
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 업체 데이터 이미 존재, 건너뜀.");
            return;
        }

        // HALL (예식장) — 3개
        insertVendor("70000000000001", "HALL",      "그랜드 웨딩홀",
                "서울 강남구 논현동 123",       "02-1234-5678",
                "강남 최대 규모 웨딩홀. 최대 500명 수용 가능. 야외 정원 포함.");
        insertVendor("70000000000009", "HALL",      "로얄 가든 웨딩",
                "서울 서초구 반포동 55",        "02-9988-7766",
                "한강 조망 루프탑 예식장. 소규모 단독 예식 특화.");
        insertVendor("70000000000010", "HALL",      "블루밍 웨딩홀",
                "경기 성남시 분당구 정자동 88", "031-888-9900",
                "분당 신도시 대형 웨딩홀. 200~600명 규모 수용 가능.");

        // STUDIO (스튜디오) — 2개
        insertVendor("70000000000002", "STUDIO",    "스튜디오 아이엘",
                "서울 마포구 합정동 56",        "02-3456-7890",
                "자연광 스튜디오 + 야외 공원 촬영 패키지. 원판 필름 제공.");
        insertVendor("70000000000011", "STUDIO",    "포레스트 스튜디오",
                "서울 성동구 성수동 12",        "02-7777-1234",
                "성수 감성 스튜디오. 필름 감성 · 미니멀 컨셉 특화.");

        // DRESS (드레스) — 2개
        insertVendor("70000000000003", "DRESS",     "로맨티크 드레스샵",
                "서울 강남구 청담동 78",        "02-2345-6789",
                "수입 드레스 200벌 이상 보유. 무료 핏팅 2회 제공.");
        insertVendor("70000000000012", "DRESS",     "화이트 아뜰리에",
                "서울 서초구 방배동 33",        "02-6655-4433",
                "국내 자체 제작 드레스 전문. 3D 체형 맞춤 드레스 제공.");

        // MAKEUP (메이크업) — 2개
        insertVendor("70000000000004", "MAKEUP",    "뷰티 아뜰리에",
                "서울 강남구 압구정동 90",      "02-3456-1234",
                "연예인 전담 메이크업 아티스트 팀. 트라이얼 1회 포함 패키지.");
        insertVendor("70000000000013", "MAKEUP",    "글로우 메이크업",
                "서울 마포구 홍대입구 44",      "02-5544-6677",
                "내추럴 · 글로우 메이크업 특화. 당일 파우더룸 서비스 제공.");

        // HONEYMOON (허니문) — 2개
        insertVendor("70000000000005", "HONEYMOON", "발리 허니문 패키지",
                "서울 중구 을지로 100",         "02-4567-8901",
                "발리 풀빌라 7박 + 항공 포함 패키지. 스파·조식 포함.");
        insertVendor("70000000000006", "HONEYMOON", "몰디브 프리미엄 투어",
                "서울 강남구 역삼동 200",       "02-5678-9012",
                "몰디브 수상 방갈로 5박 패키지. 스노클링 투어 포함.");

        // ETC (기타) — 2개
        insertVendor("70000000000007", "ETC",       "웨딩 플래너 A팀",
                "서울 서초구 서초동 300",       "02-6789-0123",
                "토탈 웨딩 플래닝 서비스. 계약 시작 ~ 본식 당일까지 1:1 전담.");
        insertVendor("70000000000008", "ETC",       "청첩장 공방",
                "서울 마포구 연남동 400",       "02-7890-1234",
                "수제 청첩장 제작 공방. 레터프레스 · 금박 · 캘리그라피 특화.");

        log.info("[DataInitializer] 업체 13개 생성 완료.");
    }

    private void insertVendor(String oid, String category, String name,
                               String address, String phone, String description) {
        jdbc.update("""
                INSERT INTO weddy_vendors (oid, name, category, address, phone, description)
                VALUES (?, ?, ?, ?, ?, ?)
                """, oid, name, category, address, phone, description);
    }

    // =========================================================
    // 즐겨찾기
    // =========================================================

    private void createFavorites() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_favorites WHERE owner_oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 즐겨찾기 데이터 이미 존재, 건너뜀.");
            return;
        }

        // 커플(20000000000001) → 그랜드 웨딩홀, 스튜디오 아이엘, 뷰티 아뜰리에
        insertFavorite("61000000000001", "20000000000001", "70000000000001");
        insertFavorite("61000000000002", "20000000000001", "70000000000002");
        insertFavorite("61000000000003", "20000000000001", "70000000000004");

        // 솔로(10000000000003) → 로맨티크 드레스샵
        insertFavorite("61000000000004", "10000000000003", "70000000000003");

        log.info("[DataInitializer] 즐겨찾기 4개 생성 완료.");
    }

    private void insertFavorite(String oid, String ownerOid, String vendorOid) {
        jdbc.update("""
                INSERT INTO weddy_favorites (oid, owner_oid, vendor_oid)
                VALUES (?, ?, ?)
                """, oid, ownerOid, vendorOid);
    }

    // =========================================================
    // 웨딩 관리 로드맵
    // =========================================================

    private void createRoadmapSteps() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_roadmap_steps WHERE owner_oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 로드맵 단계 데이터 이미 존재, 건너뜀.");
            return;
        }

        // stepType, title, sortOrder, details
        insertRoadmapStep("80000000000001", "BUDGET",       "결혼 예산 설정",  1,
                "{\"totalBudget\":50000000}");
        insertRoadmapStep("80000000000002", "HALL",         "웨딩홀 투어",     2,
                "{\"totalFee\":0,\"guestCount\":0}");
        insertRoadmapStep("80000000000003", "PLANNER",      "웨딩 플래너 선정",3,
                "{\"vendors\":[]}");
        insertRoadmapStep("80000000000004", "DRESS",        "드레스·예복 준비",4,
                "{\"fittingFee\":0,\"vendors\":[],\"balance\":0}");
        insertRoadmapStep("80000000000005", "HOME",         "신혼집 마련",     5,
                "{\"type\":\"JEONSE\",\"agency\":\"\",\"phone\":\"\",\"price\":0,\"location\":\"\"}");
        insertRoadmapStep("80000000000006", "TRAVEL",       "신혼여행 예약",   6,
                "{\"purchaseSource\":\"\",\"departure\":\"ICN\",\"destination\":\"\",\"stopovers\":[],\"flightInfo\":\"\",\"airline\":\"\"}");
        insertRoadmapStep("80000000000007", "GIFT",         "예물·예단 준비",  7,
                "{\"items\":[]}");
        insertRoadmapStep("80000000000008", "SANGGYEONRYE", "상견례 준비",     8,
                "{\"restaurantName\":\"\",\"pricePerPerson\":0,\"guestCount\":0,\"totalAmount\":0,\"extraItems\":[]}");
        insertRoadmapStep("80000000000009", "ETC",          "기타 준비사항",   9,
                "{\"items\":[]}");

        log.info("[DataInitializer] 로드맵 단계 9개 생성 완료.");
    }

    private void insertRoadmapStep(String oid, String stepType, String title,
                                   int sortOrder, String details) {
        jdbc.update("""
                INSERT INTO weddy_roadmap_steps
                    (oid, owner_oid, step_type, title, is_done, status, due_date, has_due_date, sort_order, details)
                VALUES (?, ?, ?, ?, 0, 'NOT_STARTED', NULL, 0, ?, ?)
                """, oid, "20000000000001", stepType, title, sortOrder, details);
    }

    // =========================================================
    // 테스트 일정
    // =========================================================

    private void createSchedules() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_schedules WHERE owner_oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 일정 데이터 이미 존재, 건너뜀.");
            return;
        }

        insertSchedule("60000000000001", "웨딩홀 투어 — 그랜드 웨딩홀",
                "예식장", "2026-05-10 14:00:00", "2026-05-10 16:00:00",
                "서울 강남구 논현동 123", "MANUAL", null);
        insertSchedule("60000000000002", "드레스 1차 피팅",
                "드레스", "2026-05-20 11:00:00", "2026-05-20 13:00:00",
                "서울 서초구 방배동 드레스 아뜰리에", "MANUAL", null);
        insertSchedule("60000000000003", "스튜디오 촬영",
                "스튜디오", "2026-06-15 10:00:00", "2026-06-15 18:00:00",
                "서울 마포구 합정동 스튜디오 아이엘", "MANUAL", null);

        log.info("[DataInitializer] 테스트 일정 3개 생성 완료.");
    }

    private void insertSchedule(String oid, String title, String category,
                                 String startAt, String endAt, String location,
                                 String sourceType, String sourceOid) {
        jdbc.update("""
                INSERT INTO weddy_schedules
                    (oid, owner_oid, title, category, is_all_day, start_at, end_at, location, source_type, source_oid)
                VALUES (?, ?, ?, ?, 0, ?, ?, ?, ?, ?)
                """, oid, "20000000000001", title, category, startAt, endAt,
                location, sourceType, sourceOid);
    }

    // =========================================================
    // 하객 그룹 (커플 소유)
    // =========================================================

    private void createGuestGroups() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_guest_groups WHERE owner_oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 하객 그룹 데이터 이미 존재, 건너뜀.");
            return;
        }

        // 커플(20000000000001) 기본 그룹 5개 (is_default=1, 삭제 불가)
        insertGuestGroup("90000000000001", "20000000000001", "고교", true,  0);
        insertGuestGroup("90000000000002", "20000000000001", "대학", true,  1);
        insertGuestGroup("90000000000003", "20000000000001", "직장", true,  2);
        insertGuestGroup("90000000000004", "20000000000001", "가족", true,  3);
        insertGuestGroup("90000000000005", "20000000000001", "기타", true,  4);

        log.info("[DataInitializer] 하객 그룹 5개 생성 완료.");
    }

    private void insertGuestGroup(String oid, String ownerOid, String name,
                                   boolean isDefault, int sortOrder) {
        jdbc.update("""
                INSERT INTO weddy_guest_groups (oid, owner_oid, name, is_default, sort_order)
                VALUES (?, ?, ?, ?, ?)
                """, oid, ownerOid, name, isDefault ? 1 : 0, sortOrder);
    }

    // =========================================================
    // 하객 샘플 데이터
    // =========================================================

    private void createGuests() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_guests WHERE owner_oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 하객 데이터 이미 존재, 건너뜀.");
            return;
        }

        // oid, ownerOid, groupOid, name, companionCount, giftAmount, invitationStatus, attendStatus, memo
        insertGuest("91000000000001", "20000000000001", "90000000000001",
                "김민준", 1, 100_000L, "PAPER",  "ATTEND",    null);
        insertGuest("91000000000002", "20000000000001", "90000000000001",
                "이서연", 0,  50_000L, "MOBILE", "UNDECIDED", null);
        insertGuest("91000000000003", "20000000000001", "90000000000003",
                "박준호", 1, 100_000L, "PAPER",  "ATTEND",    "팀장님");
        insertGuest("91000000000004", "20000000000001", "90000000000003",
                "정수아", 0,  50_000L, "NONE",   "ABSENT",    null);
        insertGuest("91000000000005", "20000000000001", null,
                "최지훈", 0,       0L, "NONE",   "UNDECIDED", null);

        log.info("[DataInitializer] 하객 5명 생성 완료.");
    }

    private void insertGuest(String oid, String ownerOid, String groupOid,
                              String name, int companionCount, long giftAmount,
                              String invitationStatus, String attendStatus, String memo) {
        jdbc.update("""
                INSERT INTO weddy_guests
                    (oid, owner_oid, group_oid, name, companion_count, gift_amount,
                     invitation_status, attend_status, memo)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, oid, ownerOid, groupOid, name, companionCount, giftAmount,
                invitationStatus, attendStatus, memo);
    }
}
