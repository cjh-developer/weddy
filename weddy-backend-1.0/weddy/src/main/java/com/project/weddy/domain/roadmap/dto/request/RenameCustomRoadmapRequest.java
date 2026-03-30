package com.project.weddy.domain.roadmap.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 직접 로드맵 이름 변경 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class RenameCustomRoadmapRequest {

    @NotBlank(message = "로드맵 이름은 필수입니다.")
    @Size(max = 100, message = "로드맵 이름은 100자 이하여야 합니다.")
    private String name;
}
