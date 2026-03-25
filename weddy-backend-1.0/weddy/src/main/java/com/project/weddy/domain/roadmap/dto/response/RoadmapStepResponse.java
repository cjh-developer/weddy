package com.project.weddy.domain.roadmap.dto.response;

import com.project.weddy.domain.roadmap.entity.RoadmapStep;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 웨딩 로드맵 단계 응답 DTO.
 * ownerOid는 보안상 응답에서 제외한다.
 */
@Getter
@Builder
public class RoadmapStepResponse {

    private String oid;
    private String stepType;
    private String title;
    private Boolean isDone;
    private LocalDate dueDate;
    private Boolean hasDueDate;
    private int sortOrder;
    private String details;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * RoadmapStep 엔티티로부터 응답 DTO를 생성한다.
     *
     * @param step 로드맵 단계 엔티티
     * @return 응답 DTO
     */
    public static RoadmapStepResponse from(RoadmapStep step) {
        return RoadmapStepResponse.builder()
                .oid(step.getOid())
                .stepType(step.getStepType())
                .title(step.getTitle())
                .isDone(step.isDone())
                .dueDate(step.getDueDate())
                .hasDueDate(step.isHasDueDate())
                .sortOrder(step.getSortOrder())
                .details(step.getDetails())
                .createdAt(step.getCreatedAt())
                .updatedAt(step.getUpdatedAt())
                .build();
    }
}
