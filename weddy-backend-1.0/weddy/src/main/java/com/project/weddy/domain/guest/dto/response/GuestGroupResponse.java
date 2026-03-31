package com.project.weddy.domain.guest.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.project.weddy.domain.guest.entity.GuestGroup;
import lombok.Builder;
import lombok.Getter;

/**
 * 하객 그룹 응답 DTO.
 *
 * <p>{@code isDefault} 필드: Lombok boolean getter isDefault() → Jackson이 "default" 키로 직렬화하는 문제 방지.
 * {@code @JsonProperty("isDefault")} 명시로 키를 고정한다.
 */
@Getter
@Builder
public class GuestGroupResponse {

    private String oid;
    private String name;

    /** @JsonProperty 명시: Lombok boolean isDefault() → Jackson "isDefault"로 직렬화 고정 */
    @JsonProperty("isDefault")
    private boolean isDefault;

    private int sortOrder;
    private int guestCount;

    /**
     * GuestGroup 엔티티와 하객 수를 조합하여 응답 DTO를 생성한다.
     *
     * @param group      하객 그룹 엔티티
     * @param guestCount 해당 그룹의 하객 수
     * @return 하객 그룹 응답 DTO
     */
    public static GuestGroupResponse from(GuestGroup group, int guestCount) {
        return GuestGroupResponse.builder()
                .oid(group.getOid())
                .name(group.getName())
                .isDefault(group.isDefault())
                .sortOrder(group.getSortOrder())
                .guestCount(guestCount)
                .build();
    }
}
