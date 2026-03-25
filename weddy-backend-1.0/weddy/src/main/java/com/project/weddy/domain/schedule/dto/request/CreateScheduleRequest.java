package com.project.weddy.domain.schedule.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 일정 생성 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class CreateScheduleRequest {

    @NotBlank(message = "일정 제목은 필수입니다.")
    @Size(max = 100, message = "일정 제목은 100자 이하여야 합니다.")
    private String title;

    @Size(max = 1000, message = "설명은 1000자 이하여야 합니다.")
    private String description;

    @NotBlank(message = "카테고리는 필수입니다.")
    @Pattern(
        regexp = "^[가-힣a-zA-Z0-9\\s_\\-\\.]{1,30}$",
        message = "카테고리는 한글, 영문, 숫자, 공백, _-. 만 허용됩니다."
    )
    private String category;

    private boolean isAllDay;

    @NotNull(message = "시작 일시는 필수입니다.")
    private LocalDateTime startAt;

    private LocalDateTime endAt;

    @Size(max = 200, message = "장소는 200자 이하여야 합니다.")
    private String location;

    @Pattern(
        regexp = "^(|10MINUTES|30MINUTES|1HOUR|1DAY|3DAYS|1WEEK)$",
        message = "유효하지 않은 알림 설정값입니다."
    )
    private String alertBefore;
}
