package com.project.weddy.domain.budget.dto.response;

import com.project.weddy.domain.budget.entity.BudgetSettings;
import lombok.Builder;
import lombok.Getter;

/**
 * 전체 예산 설정 응답 DTO.
 *
 * <p>설정이 없거나 totalAmount가 0이면 totalBudget을 null로 반환한다.
 * 클라이언트는 null 여부로 설정 완료 여부를 판단할 수 있다.
 */
@Getter
@Builder
public class BudgetSettingsResponse {

    /** 전체 예산 금액. 미설정이면 null. */
    private Long totalBudget;

    /**
     * 예산 미설정 응답을 생성한다.
     *
     * @return totalBudget=null인 응답
     */
    public static BudgetSettingsResponse notConfigured() {
        return BudgetSettingsResponse.builder().totalBudget(null).build();
    }

    /**
     * 엔티티로부터 응답 DTO를 생성한다.
     * totalAmount가 0 이하이면 null을 반환한다.
     *
     * @param settings 예산 설정 엔티티
     * @return 응답 DTO
     */
    public static BudgetSettingsResponse from(BudgetSettings settings) {
        return BudgetSettingsResponse.builder()
                .totalBudget(settings.getTotalAmount() > 0 ? settings.getTotalAmount() : null)
                .build();
    }
}
