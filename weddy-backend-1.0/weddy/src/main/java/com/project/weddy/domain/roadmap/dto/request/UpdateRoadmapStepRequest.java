package com.project.weddy.domain.roadmap.dto.request;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 웨딩 로드맵 단계 수정 요청 DTO.
 * 모든 필드가 Optional이며, null인 필드는 기존 값을 유지한다.
 *
 * <p>dueDate를 명시적으로 null로 지우려면 clearDueDate=true를 함께 전달한다.
 * dueDate=null이면서 clearDueDate=false이면 기존 값이 유지된다.
 */
@Getter
@NoArgsConstructor
public class UpdateRoadmapStepRequest {

    @Size(max = 100, message = "단계 제목은 100자 이하여야 합니다.")
    private String title;

    private Boolean isDone;

    private LocalDate dueDate;

    private Boolean hasDueDate;

    /** 단계별 특화 데이터 (JSON 문자열). null이면 기존 값 유지. */
    @Size(max = 2000, message = "단계 상세 정보는 2000자 이하여야 합니다.")
    private String details;

    /**
     * true이면 dueDate를 명시적으로 null(삭제)로 설정한다.
     * false(기본값)이면 dueDate 필드 값으로 판단한다.
     */
    private boolean clearDueDate = false;
}
