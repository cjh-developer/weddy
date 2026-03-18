package com.project.weddy.domain.budget.dto.response;

import lombok.Builder;
import lombok.Getter;

/**
 * 홈 화면용 예산 요약 응답 DTO.
 * 전체 계획 금액, 실제 지출 금액, 예산 사용률, 전체 예산 설정값을 반환한다.
 *
 * <p>usageRate는 0~100 범위의 퍼센트 값(소수 포함)이다.
 * totalBudget이 설정된 경우 usageRate는 totalBudget 기준으로 계산된다.
 * 그렇지 않으면 totalPlanned 기준으로 계산된다.
 * 분모가 0이면 usageRate는 0으로 처리한다.
 */
@Getter
@Builder
public class BudgetSummaryResponse {

    /** 전체 계획 금액 합산 */
    private long totalPlanned;

    /** 실제 지출 금액 합산 (모든 예산 항목의 amount 합산) */
    private long totalSpent;

    /** 예산 사용률 (totalSpent / totalBudget(또는 totalPlanned) × 100, 소수 1자리) */
    private double usageRate;

    /** 전체 예산 설정값. 미설정이면 null. */
    private Long totalBudget;
}
