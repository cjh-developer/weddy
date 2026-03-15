package com.project.weddy.domain.checklist.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 체크리스트 항목 수정 요청 DTO.
 * 모든 필드가 optional이므로 null인 필드는 기존 값을 유지한다.
 */
@Getter
@NoArgsConstructor
public class UpdateChecklistItemRequest {

    @Size(max = 500, message = "내용은 500자 이하여야 합니다.")
    private String content;

    // 래퍼 타입 사용 — null이면 기존 값 유지
    private Boolean isDone;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate dueDate;

    // 래퍼 타입 사용 — null이면 기존 값 유지
    private Integer sortOrder;
}
