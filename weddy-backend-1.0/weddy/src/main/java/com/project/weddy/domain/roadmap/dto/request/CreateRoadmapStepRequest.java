package com.project.weddy.domain.roadmap.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 웨딩 로드맵 단계 생성 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class CreateRoadmapStepRequest {

    @NotBlank(message = "단계 유형은 필수입니다.")
    @Pattern(
        regexp = "^(BUDGET|HALL|PLANNER|DRESS|HOME|TRAVEL|GIFT|SANGGYEONRYE|ETC)$",
        message = "유효하지 않은 단계 유형입니다."
    )
    private String stepType;

    @NotBlank(message = "단계 제목은 필수입니다.")
    @Size(max = 100, message = "단계 제목은 100자 이하여야 합니다.")
    private String title;

    private LocalDate dueDate;

    private boolean hasDueDate;

    /** 단계별 특화 데이터 (JSON 문자열). 클라이언트가 직렬화하여 전달한다. */
    @Size(max = 2000, message = "단계 상세 정보는 2000자 이하여야 합니다.")
    private String details;
}
