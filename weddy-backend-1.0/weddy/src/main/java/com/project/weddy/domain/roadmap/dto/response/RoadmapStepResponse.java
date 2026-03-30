package com.project.weddy.domain.roadmap.dto.response;

import com.project.weddy.domain.roadmap.entity.RoadmapStep;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 웨딩 로드맵 단계 응답 DTO.
 * ownerOid는 보안상 응답에서 제외한다.
 * groupOid가 null이면 기본 로드맵 단계이고, 값이 있으면 직접 로드맵 소속 단계이다.
 */
@Getter
@Builder
public class RoadmapStepResponse {

    private String oid;
    private String stepType;
    /** 소속 직접 로드맵 OID. null이면 기본 로드맵 단계. */
    private String groupOid;
    private String title;
    private Boolean isDone;
    private String status;
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
                .groupOid(step.getGroupOid())
                .title(step.getTitle())
                .isDone(step.isDone())
                .status(step.getStatus())
                .dueDate(step.getDueDate())
                .hasDueDate(step.isHasDueDate())
                .sortOrder(step.getSortOrder())
                .details(step.getDetails())
                .createdAt(step.getCreatedAt())
                .updatedAt(step.getUpdatedAt())
                .build();
    }
}
