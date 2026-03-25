package com.project.weddy.domain.roadmap.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 웨딩홀 투어 추가 요청 DTO.
 * scheduleTitle이 null이 아니면 tourDate를 기준으로 일정을 자동 등록한다.
 */
@Getter
@NoArgsConstructor
public class CreateHallTourRequest {

    @NotBlank(message = "웨딩홀 이름은 필수입니다.")
    @Size(max = 100, message = "웨딩홀 이름은 100자 이하여야 합니다.")
    private String hallName;

    private LocalDate tourDate;

    @Size(max = 200, message = "장소는 200자 이하여야 합니다.")
    private String location;

    @Max(value = 9_999_999_999L, message = "대관료는 99억 이하여야 합니다.")
    private Long rentalFee;

    @Max(value = 9_999_999_999L, message = "식대는 99억 이하여야 합니다.")
    private Long mealPrice;

    @Min(value = 1, message = "보증 인원은 1명 이상이어야 합니다.")
    @Max(value = 10000, message = "보증 인원은 10000명 이하여야 합니다.")
    private Integer minGuests;

    @Size(max = 500, message = "메모는 500자 이하여야 합니다.")
    private String memo;

    /**
     * 일정 자동 등록 시 사용할 일정 제목.
     * null이면 일정을 자동 등록하지 않는다.
     */
    @Size(max = 100, message = "일정 제목은 100자 이하여야 합니다.")
    private String scheduleTitle;
}
