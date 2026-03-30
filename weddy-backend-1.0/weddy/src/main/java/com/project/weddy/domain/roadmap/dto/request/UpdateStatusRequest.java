package com.project.weddy.domain.roadmap.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 웨딩 관리 단계 상태 변경 요청 DTO.
 * status는 NOT_STARTED, IN_PROGRESS, DONE 중 하나여야 한다.
 */
@Getter
@NoArgsConstructor
public class UpdateStatusRequest {

    @NotBlank
    @Pattern(regexp = "NOT_STARTED|IN_PROGRESS|DONE",
             message = "status는 NOT_STARTED, IN_PROGRESS, DONE 중 하나여야 합니다.")
    private String status;
}
