package com.project.weddy.domain.guest.dto.response;

import com.project.weddy.domain.guest.entity.Guest;
import lombok.Builder;
import lombok.Getter;

/**
 * 하객 응답 DTO.
 *
 * <p>ownerOid 등 내부 식별자는 클라이언트에 노출하지 않는다.
 * groupName은 서비스 레이어에서 그룹 목록을 조회하여 주입한다.
 */
@Getter
@Builder
public class GuestResponse {

    private String oid;
    private String groupOid;
    private String groupName;
    private String name;
    private int companionCount;
    private long giftAmount;
    private String invitationStatus;
    private String attendStatus;
    private String memo;

    /**
     * Guest 엔티티와 그룹명을 조합하여 응답 DTO를 생성한다.
     *
     * @param guest     하객 엔티티
     * @param groupName 소속 그룹명 (그룹 미분류 시 null)
     * @return 하객 응답 DTO
     */
    public static GuestResponse from(Guest guest, String groupName) {
        return GuestResponse.builder()
                .oid(guest.getOid())
                .groupOid(guest.getGroupOid())
                .groupName(groupName)
                .name(guest.getName())
                .companionCount(guest.getCompanionCount())
                .giftAmount(guest.getGiftAmount())
                .invitationStatus(guest.getInvitationStatus())
                .attendStatus(guest.getAttendStatus())
                .memo(guest.getMemo())
                .build();
    }
}
