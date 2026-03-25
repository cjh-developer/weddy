package com.project.weddy.domain.roadmap.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 항공권 경유지 추가 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class AddTravelStopRequest {

    @NotBlank(message = "도시명은 필수입니다.")
    @Size(max = 100, message = "도시명은 100자 이하여야 합니다.")
    private String city;
}
