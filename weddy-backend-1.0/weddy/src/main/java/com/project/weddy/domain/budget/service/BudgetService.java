package com.project.weddy.domain.budget.service;

import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.domain.budget.dto.request.CreateBudgetItemRequest;
import com.project.weddy.domain.budget.dto.request.CreateBudgetRequest;
import com.project.weddy.domain.budget.dto.request.UpdateBudgetItemRequest;
import com.project.weddy.domain.budget.dto.request.UpsertBudgetSettingsRequest;
import com.project.weddy.domain.budget.dto.response.BudgetItemResponse;
import com.project.weddy.domain.budget.dto.response.BudgetResponse;
import com.project.weddy.domain.budget.dto.response.BudgetSettingsResponse;
import com.project.weddy.domain.budget.dto.response.BudgetSummaryResponse;
import com.project.weddy.domain.budget.entity.Budget;
import com.project.weddy.domain.budget.entity.BudgetItem;
import com.project.weddy.domain.budget.entity.BudgetSettings;
import com.project.weddy.domain.budget.repository.BudgetItemRepository;
import com.project.weddy.domain.budget.repository.BudgetRepository;
import com.project.weddy.domain.budget.repository.BudgetSettingsRepository;
import com.project.weddy.domain.couple.entity.Couple;
import com.project.weddy.domain.couple.repository.CoupleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 예산 CRUD 서비스.
 *
 * <p>솔로 사용자도 예산을 사용할 수 있다.
 * 커플 연결 전에는 owner_oid = 사용자 OID, 커플 연결 후에는 owner_oid = 커플 OID로 동작한다.
 * 모든 쓰기 연산은 소유권을 검증하여 IDOR 공격을 방지한다.
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class BudgetService {

    private final BudgetRepository budgetRepository;
    private final BudgetItemRepository budgetItemRepository;
    private final BudgetSettingsRepository budgetSettingsRepository;
    private final CoupleRepository coupleRepository;

    /**
     * 사용자의 소유자 OID를 반환한다.
     * 커플에 연결된 경우 커플 OID를, 솔로인 경우 사용자 OID를 반환한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 소유자 OID (커플 OID 또는 사용자 OID)
     */
    private String getOwnerOid(String userOid) {
        return coupleRepository.findByGroomOidOrBrideOid(userOid, userOid)
                .map(Couple::getOid)
                .orElse(userOid);
    }

    /**
     * 예산 소유권을 검증한다.
     * 지정된 소유자에 속하지 않는 예산 접근 시 예외를 던진다.
     *
     * @param budgetOid 예산 OID
     * @param ownerOid  소유자 OID
     * @throws CustomException BUDGET_NOT_FOUND
     */
    private void validateBudgetOwnership(String budgetOid, String ownerOid) {
        if (!budgetRepository.existsByOidAndOwnerOid(budgetOid, ownerOid)) {
            throw new CustomException(ErrorCode.BUDGET_NOT_FOUND);
        }
    }

    /**
     * 항목 소유권을 검증한다.
     * 지정된 예산에 속하지 않는 항목 접근 시 예외를 던진다.
     *
     * @param itemOid   항목 OID
     * @param budgetOid 예산 OID
     * @throws CustomException BUDGET_ITEM_NOT_FOUND
     */
    private void validateItemOwnership(String itemOid, String budgetOid) {
        if (!budgetItemRepository.existsByOidAndBudgetOid(itemOid, budgetOid)) {
            throw new CustomException(ErrorCode.BUDGET_ITEM_NOT_FOUND);
        }
    }

    /**
     * 소유자의 전체 예산 목록과 각 예산의 항목을 조회한다.
     * spentAmount는 항목 amount 합산으로 인메모리 계산된다.
     *
     * @param userOid 현재 사용자 OID
     * @return 예산 목록 (항목 포함)
     */
    @Transactional(readOnly = true)
    public List<BudgetResponse> getBudgets(String userOid) {
        String ownerOid = getOwnerOid(userOid);
        List<Budget> budgets = budgetRepository.findByOwnerOidOrderByCreatedAtAsc(ownerOid);
        return budgets.stream().map(budget -> {
            List<BudgetItem> items =
                    budgetItemRepository.findByBudgetOidOrderByCreatedAtAsc(budget.getOid());
            return BudgetResponse.from(budget, items);
        }).toList();
    }

    /**
     * 예산 카테고리를 생성한다.
     *
     * @param userOid 현재 사용자 OID
     * @param req     예산 생성 요청
     * @return 생성된 예산 응답
     */
    public BudgetResponse createBudget(String userOid, CreateBudgetRequest req) {
        String ownerOid = getOwnerOid(userOid);
        if (budgetRepository.countByOwnerOid(ownerOid) >= 20) {
            throw new CustomException(ErrorCode.BUDGET_LIMIT_EXCEEDED);
        }
        Budget budget = Budget.builder()
                .ownerOid(ownerOid)
                .category(req.getCategory())
                .plannedAmount(req.getPlannedAmount())
                .build();
        budget = budgetRepository.save(budget);
        log.info("예산 생성 - budgetOid: {}, ownerOid: {}", budget.getOid(), ownerOid);
        return BudgetResponse.from(budget, List.of());
    }

    /**
     * 예산 카테고리와 소속 항목을 모두 삭제한다.
     *
     * @param userOid   현재 사용자 OID
     * @param budgetOid 삭제할 예산 OID
     */
    public void deleteBudget(String userOid, String budgetOid) {
        String ownerOid = getOwnerOid(userOid);
        validateBudgetOwnership(budgetOid, ownerOid);
        budgetItemRepository.deleteByBudgetOid(budgetOid);
        budgetRepository.deleteById(budgetOid);
        log.info("예산 삭제 - budgetOid: {}, ownerOid: {}", budgetOid, ownerOid);
    }

    /**
     * 예산 카테고리에 항목을 추가한다.
     *
     * @param userOid   현재 사용자 OID
     * @param budgetOid 대상 예산 OID
     * @param req       항목 생성 요청
     * @return 생성된 항목 응답
     */
    public BudgetItemResponse addItem(
            String userOid, String budgetOid, CreateBudgetItemRequest req) {
        String ownerOid = getOwnerOid(userOid);
        validateBudgetOwnership(budgetOid, ownerOid);
        BudgetItem item = BudgetItem.builder()
                .budgetOid(budgetOid)
                .title(req.getTitle())
                .amount(req.getAmount())
                .memo(req.getMemo())
                .paidAt(req.getPaidAt())
                .build();
        BudgetItem saved = budgetItemRepository.save(item);
        log.info("예산 항목 추가 - itemOid: {}, budgetOid: {}", saved.getOid(), budgetOid);
        return BudgetItemResponse.from(saved);
    }

    /**
     * 예산 항목을 부분 수정한다.
     * null인 필드는 기존 값을 유지한다.
     *
     * @param userOid   현재 사용자 OID
     * @param budgetOid 예산 OID
     * @param itemOid   수정할 항목 OID
     * @param req       수정 요청
     * @return 수정된 항목 응답
     */
    public BudgetItemResponse updateItem(
            String userOid, String budgetOid, String itemOid, UpdateBudgetItemRequest req) {
        String ownerOid = getOwnerOid(userOid);
        validateBudgetOwnership(budgetOid, ownerOid);
        BudgetItem item = budgetItemRepository.findById(itemOid)
                .orElseThrow(() -> new CustomException(ErrorCode.BUDGET_ITEM_NOT_FOUND));
        // 추가 DB 조회 없이 인메모리에서 소유권 확인
        if (!item.getBudgetOid().equals(budgetOid)) {
            throw new CustomException(ErrorCode.BUDGET_ITEM_NOT_FOUND);
        }
        item.update(req.getTitle(), req.getAmount(), req.getMemo(), req.getPaidAt());
        return BudgetItemResponse.from(item);
    }

    /**
     * 예산 항목을 삭제한다.
     *
     * @param userOid   현재 사용자 OID
     * @param budgetOid 예산 OID
     * @param itemOid   삭제할 항목 OID
     */
    public void deleteItem(String userOid, String budgetOid, String itemOid) {
        String ownerOid = getOwnerOid(userOid);
        validateBudgetOwnership(budgetOid, ownerOid);
        validateItemOwnership(itemOid, budgetOid);
        budgetItemRepository.deleteById(itemOid);
        log.info("예산 항목 삭제 - itemOid: {}, budgetOid: {}", itemOid, budgetOid);
    }

    /**
     * 홈 화면용 예산 요약 정보를 조회한다.
     * 소유자의 전체 계획 금액, 지출 금액, 예산 사용률, 전체 예산 설정값을 반환한다.
     *
     * <p>usageRate 분모: totalBudget 설정 시 totalBudget, 미설정 시 totalPlanned.
     * 분모가 0이면 usageRate = 0.0 처리.
     *
     * @param userOid 현재 사용자 OID
     * @return 예산 요약 (totalPlanned, totalSpent, usageRate, totalBudget)
     */
    @Transactional(readOnly = true)
    public BudgetSummaryResponse getSummary(String userOid) {
        String ownerOid = getOwnerOid(userOid);
        List<Budget> budgets = budgetRepository.findByOwnerOidOrderByCreatedAtAsc(ownerOid);

        long totalPlanned = budgets.stream().mapToLong(Budget::getPlannedAmount).sum();

        // N+1 방지: 소유자 소속 모든 예산의 항목을 한 번의 IN 쿼리로 조회
        long totalSpent = 0L;
        if (!budgets.isEmpty()) {
            List<String> budgetOids = budgets.stream().map(Budget::getOid).toList();
            totalSpent = budgetItemRepository.findAllByBudgetOidIn(budgetOids)
                    .stream().mapToLong(BudgetItem::getAmount).sum();
        }

        // 전체 예산 설정값 조회 (미설정이면 null)
        Long totalBudget = budgetSettingsRepository.findByOwnerOid(ownerOid)
                .map(s -> s.getTotalAmount() > 0 ? s.getTotalAmount() : null)
                .orElse(null);

        // usageRate 분모: totalBudget 우선, 없으면 totalPlanned
        long denominator = totalBudget != null ? totalBudget : totalPlanned;
        double usageRate = denominator == 0 ? 0.0
                : Math.round((double) totalSpent / denominator * 1000.0) / 10.0;

        return BudgetSummaryResponse.builder()
                .totalPlanned(totalPlanned)
                .totalSpent(totalSpent)
                .usageRate(usageRate)
                .totalBudget(totalBudget)
                .build();
    }

    /**
     * 전체 예산 설정을 조회한다.
     * 설정이 없으면 totalBudget=null인 응답을 반환한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 전체 예산 설정 응답
     */
    @Transactional(readOnly = true)
    public BudgetSettingsResponse getSettings(String userOid) {
        String ownerOid = getOwnerOid(userOid);
        return budgetSettingsRepository.findByOwnerOid(ownerOid)
                .map(BudgetSettingsResponse::from)
                .orElseGet(BudgetSettingsResponse::notConfigured);
    }

    /**
     * 전체 예산 설정을 저장(upsert)한다.
     * 기존 설정이 있으면 금액을 갱신하고, 없으면 신규 생성한다.
     *
     * @param userOid 현재 사용자 OID
     * @param req     전체 예산 upsert 요청
     * @return 저장된 전체 예산 설정 응답
     */
    @Transactional
    public BudgetSettingsResponse upsertSettings(String userOid, UpsertBudgetSettingsRequest req) {
        String ownerOid = getOwnerOid(userOid);
        BudgetSettings settings = budgetSettingsRepository.findByOwnerOid(ownerOid)
                .orElseGet(() -> BudgetSettings.builder()
                        .ownerOid(ownerOid)
                        .build());
        settings.updateTotalAmount(req.getTotalAmount());
        BudgetSettings saved = budgetSettingsRepository.save(settings);
        log.info("예산 설정 upsert: ownerOid={}", ownerOid);
        return BudgetSettingsResponse.from(saved);
    }

    /**
     * 내부 호출용 전체 예산 설정 upsert.
     * 이미 ownerOid가 결정된 상태에서 RoadmapService 등 내부 서비스가 직접 호출한다.
     * totalAmount가 null이거나 1 미만이면 아무 처리도 하지 않는다.
     *
     * @param ownerOid    소유자 OID (커플 OID 또는 사용자 OID)
     * @param totalAmount 전체 예산 금액 (null이면 스킵)
     */
    @Transactional
    public void upsertSettingsInternal(String ownerOid, Long totalAmount) {
        if (totalAmount == null || totalAmount < 1) {
            log.debug("예산 설정 내부 upsert 스킵: ownerOid={}, totalAmount={}", ownerOid, totalAmount);
            return;
        }
        BudgetSettings settings = budgetSettingsRepository.findByOwnerOid(ownerOid)
                .orElseGet(() -> BudgetSettings.builder()
                        .ownerOid(ownerOid)
                        .build());
        settings.updateTotalAmount(totalAmount);
        budgetSettingsRepository.save(settings);
        log.info("예산 설정 내부 upsert: ownerOid={}, totalAmount={}", ownerOid, totalAmount);
    }
}
