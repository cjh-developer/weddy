package com.project.weddy.domain.checklist.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 체크리스트 항목 생성 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class CreateChecklistItemRequest {

    @NotBlank(message = "항목 내용은 필수입니다.")
    @Size(max = 500, message = "내용은 500자 이하여야 합니다.")
    private String content;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate dueDate;

    private int sortOrder = 0;
}
