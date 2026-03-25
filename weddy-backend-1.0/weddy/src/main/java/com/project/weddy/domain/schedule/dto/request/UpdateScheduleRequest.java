package com.project.weddy.domain.schedule.dto.request;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 일정 수정 요청 DTO.
 * 모든 필드가 Optional이며, null인 필드는 기존 값을 유지한다.
 */
@Getter
@NoArgsConstructor
public class UpdateScheduleRequest {

    @Size(max = 100, message = "일정 제목은 100자 이하여야 합니다.")
    private String title;

    @Size(max = 1000, message = "설명은 1000자 이하여야 합니다.")
    private String description;

    @Pattern(
        regexp = "^[가-힣a-zA-Z0-9\\s_\\-\\.]{1,30}$",
        message = "카테고리는 한글, 영문, 숫자, 공백, _-. 만 허용됩니다."
    )
    private String category;

    private Boolean isAllDay;

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
