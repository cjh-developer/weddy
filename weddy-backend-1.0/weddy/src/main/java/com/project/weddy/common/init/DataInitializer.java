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
 *   <li>체크리스트 3개 카테고리, 항목 11개</li>
 *   <li>예산 4개 카테고리, 지출 항목 10개</li>
 *   <li>즐겨찾기 업체 3개</li>
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
        createFavorites();

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

        log.info("[DataInitializer] 체크리스트 3개, 항목 13개 생성 완료.");
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
                "SELECT COUNT(*) FROM weddy_budgets WHERE couple_oid = ?",
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
                INSERT INTO weddy_budgets (oid, couple_oid, category, planned_amount)
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
    // 즐겨찾기
    // =========================================================

    private void createFavorites() {
        Integer count = jdbc.queryForObject(
                "SELECT COUNT(*) FROM weddy_couple_favorites WHERE couple_oid = ?",
                Integer.class, "20000000000001");
        if (count != null && count > 0) {
            log.debug("[DataInitializer] 즐겨찾기 데이터 이미 존재, 건너뜀.");
            return;
        }

        insertFavorite("20000000000001", "70000000000001"); // 그랜드 웨딩홀
        insertFavorite("20000000000001", "70000000000002"); // 스튜디오 아이엘
        insertFavorite("20000000000001", "70000000000004"); // 뷰티 아뜰리에

        log.info("[DataInitializer] 즐겨찾기 3개 생성 완료.");
    }

    private void insertFavorite(String coupleOid, String vendorOid) {
        jdbc.update("""
                INSERT INTO weddy_couple_favorites (couple_oid, vendor_oid)
                VALUES (?, ?)
                """, coupleOid, vendorOid);
    }
}
