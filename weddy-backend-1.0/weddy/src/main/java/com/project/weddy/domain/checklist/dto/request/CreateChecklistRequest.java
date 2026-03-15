package com.project.weddy.domain.checklist.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 체크리스트 생성 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class CreateChecklistRequest {

    @NotBlank(message = "체크리스트 제목은 필수입니다.")
    @Size(max = 100, message = "제목은 100자 이하여야 합니다.")
    private String title;

    @Size(max = 50, message = "카테고리는 50자 이하여야 합니다.")
    private String category;
}
