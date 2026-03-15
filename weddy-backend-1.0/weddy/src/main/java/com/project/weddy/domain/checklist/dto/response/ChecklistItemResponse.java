package com.project.weddy.domain.checklist.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.project.weddy.domain.checklist.entity.ChecklistItem;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 체크리스트 항목 응답 DTO.
 */
@Getter
@Builder
public class ChecklistItemResponse {

    private String oid;
    private String checklistOid;
    private String content;
    @JsonProperty("isDone")
    private boolean isDone;
    private LocalDate dueDate;
    private int sortOrder;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    /**
     * ChecklistItem 엔티티로부터 응답 DTO를 생성한다.
     *
     * @param item 체크리스트 항목 엔티티
     * @return 응답 DTO
     */
    public static ChecklistItemResponse from(ChecklistItem item) {
        return ChecklistItemResponse.builder()
                .oid(item.getOid())
                .checklistOid(item.getChecklistOid())
                .content(item.getContent())
                .isDone(item.isDone())
                .dueDate(item.getDueDate())
                .sortOrder(item.getSortOrder())
                .createdAt(item.getCreatedAt())
                .updatedAt(item.getUpdatedAt())
                .build();
    }
}
