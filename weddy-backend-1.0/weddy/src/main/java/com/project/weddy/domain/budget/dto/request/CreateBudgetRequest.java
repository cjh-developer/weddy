package com.project.weddy.domain.budget.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 예산 카테고리 생성 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class CreateBudgetRequest {

    @NotBlank(message = "카테고리명은 필수입니다.")
    @Size(max = 50, message = "카테고리명은 50자 이하여야 합니다.")
    @Pattern(regexp = "^[가-힣a-zA-Z0-9\\s_\\-]+$", message = "카테고리명에 허용되지 않는 문자가 포함되어 있습니다.")
    private String category;

    @NotNull(message = "계획 금액은 필수입니다.")
    @Min(value = 0, message = "계획 금액은 0 이상이어야 합니다.")
    @Max(value = 9_999_999_999L, message = "계획 금액은 99억 9천만원을 초과할 수 없습니다.")
    private Long plannedAmount;
}
