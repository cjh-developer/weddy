package com.project.weddy.domain.checklist.dto.response;

import com.project.weddy.domain.checklist.entity.Checklist;
import com.project.weddy.domain.checklist.entity.ChecklistItem;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 체크리스트 응답 DTO.
 * 체크리스트 메타 정보와 소속 항목 목록을 함께 반환한다.
 */
@Getter
@Builder
public class ChecklistResponse {

    private String oid;
    private String ownerOid;
    private String title;
    private String category;
    private LocalDateTime createdAt;
    private List<ChecklistItemResponse> items;

    /**
     * Checklist 엔티티와 항목 목록으로부터 응답 DTO를 생성한다.
     *
     * @param checklist 체크리스트 엔티티
     * @param items     소속 항목 목록
     * @return 응답 DTO
     */
    public static ChecklistResponse from(Checklist checklist, List<ChecklistItem> items) {
        return ChecklistResponse.builder()
                .oid(checklist.getOid())
                .ownerOid(checklist.getOwnerOid())
                .title(checklist.getTitle())
                .category(checklist.getCategory())
                .createdAt(checklist.getCreatedAt())
                .items(items.stream().map(ChecklistItemResponse::from).toList())
                .build();
    }
}
