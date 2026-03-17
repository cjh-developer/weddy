package com.project.weddy.domain.budget.dto.response;

import com.project.weddy.domain.budget.entity.BudgetItem;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 예산 항목 응답 DTO.
 */
@Getter
@Builder
public class BudgetItemResponse {

    private String oid;
    private String title;
    private long amount;
    private String memo;
    private LocalDate paidAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * BudgetItem 엔티티로부터 응답 DTO를 생성한다.
     *
     * @param item 예산 항목 엔티티
     * @return 응답 DTO
     */
    public static BudgetItemResponse from(BudgetItem item) {
        return BudgetItemResponse.builder()
                .oid(item.getOid())
                .title(item.getTitle())
                .amount(item.getAmount())
                .memo(item.getMemo())
                .paidAt(item.getPaidAt())
                .createdAt(item.getCreatedAt())
                .updatedAt(item.getUpdatedAt())
                .build();
    }
}
