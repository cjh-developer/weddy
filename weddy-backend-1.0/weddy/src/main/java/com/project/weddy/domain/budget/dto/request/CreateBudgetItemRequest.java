package com.project.weddy.domain.budget.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 예산 항목 생성 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class CreateBudgetItemRequest {

    @NotBlank(message = "항목명은 필수입니다.")
    @Size(max = 200, message = "항목명은 200자 이하여야 합니다.")
    @Pattern(regexp = "^[가-힣a-zA-Z0-9\\s\\p{Punct}]+$", message = "항목명에 허용되지 않는 문자가 포함되어 있습니다.")
    private String title;

    @NotNull(message = "금액은 필수입니다.")
    @Min(value = 0, message = "금액은 0 이상이어야 합니다.")
    @Max(value = 9_999_999_999L, message = "금액은 99억 9천만원을 초과할 수 없습니다.")
    private Long amount;

    @Size(max = 500, message = "메모는 500자 이하여야 합니다.")
    private String memo;

    @PastOrPresent(message = "결제일은 오늘 이전 날짜여야 합니다.")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate paidAt;
}
