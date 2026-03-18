package com.project.weddy.domain.budget.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 전체 예산 설정 upsert 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class UpsertBudgetSettingsRequest {

    @NotNull(message = "totalAmount는 필수입니다.")
    @Min(value = 1, message = "전체 예산은 1원 이상이어야 합니다.")
    @Max(value = 9_999_999_999L, message = "전체 예산은 9,999,999,999원 이하여야 합니다.")
    private Long totalAmount;
}
