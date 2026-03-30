package com.project.weddy.domain.roadmap.dto.response;

import com.project.weddy.domain.roadmap.entity.CustomRoadmap;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 직접 로드맵 응답 DTO.
 * ownerOid는 보안상 응답에서 제외한다.
 * steps 필드는 해당 그룹에 속한 로드맵 단계 목록이다.
 */
@Getter
@Builder
public class CustomRoadmapResponse {

    private String oid;
    private String name;
    private int sortOrder;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * 해당 직접 로드맵에 속한 단계 목록 (sort_order 오름차순).
     * 생성/이름 변경 응답 시에는 빈 리스트를 반환한다.
     */
    private List<RoadmapStepResponse> steps;

    /**
     * 엔티티와 단계 목록으로부터 응답 DTO를 생성한다.
     *
     * @param cr    직접 로드맵 엔티티
     * @param steps 소속 단계 응답 목록
     * @return 응답 DTO
     */
    public static CustomRoadmapResponse from(CustomRoadmap cr, List<RoadmapStepResponse> steps) {
        return CustomRoadmapResponse.builder()
                .oid(cr.getOid())
                .name(cr.getName())
                .sortOrder(cr.getSortOrder())
                .createdAt(cr.getCreatedAt())
                .updatedAt(cr.getUpdatedAt())
                .steps(steps)
                .build();
    }

    /**
     * 엔티티만으로 응답 DTO를 생성한다. steps는 빈 리스트로 채운다.
     * 생성 또는 이름 변경 직후 응답에 사용한다.
     *
     * @param cr 직접 로드맵 엔티티
     * @return 응답 DTO
     */
    public static CustomRoadmapResponse from(CustomRoadmap cr) {
        return from(cr, List.of());
    }
}
