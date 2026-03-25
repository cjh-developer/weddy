package com.project.weddy.domain.schedule.dto.response;

import com.project.weddy.domain.schedule.entity.Schedule;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

/**
 * 일정 응답 DTO.
 * ownerOid는 보안상 응답에서 제외한다.
 */
@Getter
@Builder
public class ScheduleResponse {

    private String oid;
    private String title;
    private String description;
    private String category;
    private Boolean isAllDay;
    private LocalDateTime startAt;
    private LocalDateTime endAt;
    private String location;
    private String alertBefore;
    private String sourceType;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * Schedule 엔티티로부터 응답 DTO를 생성한다.
     *
     * @param schedule 일정 엔티티
     * @return 응답 DTO
     */
    public static ScheduleResponse from(Schedule schedule) {
        return ScheduleResponse.builder()
                .oid(schedule.getOid())
                .title(schedule.getTitle())
                .description(schedule.getDescription())
                .category(schedule.getCategory())
                .isAllDay(schedule.isAllDay())
                .startAt(schedule.getStartAt())
                .endAt(schedule.getEndAt())
                .location(schedule.getLocation())
                .alertBefore(schedule.getAlertBefore())
                .sourceType(schedule.getSourceType())
                .createdAt(schedule.getCreatedAt())
                .updatedAt(schedule.getUpdatedAt())
                .build();
    }
}
