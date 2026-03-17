package com.project.weddy.domain.budget.dto.response;

import com.project.weddy.domain.budget.entity.Budget;
import com.project.weddy.domain.budget.entity.BudgetItem;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 예산 카테고리 응답 DTO.
 * 예산 메타 정보와 소속 항목 목록, 집계 금액을 함께 반환한다.
 *
 * <p>spentAmount는 소속 항목 amount의 합산이다.
 * remainingAmount는 plannedAmount - spentAmount이며 음수 가능(초과 지출).
 */
@Getter
@Builder
public class BudgetResponse {

    private String oid;
    private String category;
    private long plannedAmount;
    private long spentAmount;
    private long remainingAmount;
    private LocalDateTime createdAt;
    private List<BudgetItemResponse> items;

    /**
     * Budget 엔티티와 항목 목록으로부터 응답 DTO를 생성한다.
     * spentAmount와 remainingAmount는 항목 목록으로부터 인메모리 집계한다.
     *
     * @param budget 예산 카테고리 엔티티
     * @param items  소속 항목 목록
     * @return 응답 DTO
     */
    public static BudgetResponse from(Budget budget, List<BudgetItem> items) {
        long spentAmount = items.stream().mapToLong(BudgetItem::getAmount).sum();
        return BudgetResponse.builder()
                .oid(budget.getOid())
                .category(budget.getCategory())
                .plannedAmount(budget.getPlannedAmount())
                .spentAmount(spentAmount)
                .remainingAmount(budget.getPlannedAmount() - spentAmount)
                .createdAt(budget.getCreatedAt())
                .items(items.stream().map(BudgetItemResponse::from).toList())
                .build();
    }
}
