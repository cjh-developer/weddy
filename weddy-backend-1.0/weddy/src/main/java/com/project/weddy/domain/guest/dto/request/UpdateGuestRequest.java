package com.project.weddy.domain.guest.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 하객 수정 요청 DTO.
 *
 * <p>null 필드는 기존 값을 유지한다.
 * 그룹 해제가 필요한 경우 {@code clearGroup=true}를 전달한다.
 * {@code groupOid}와 {@code clearGroup=true}를 동시에 보내면 clearGroup이 우선한다.
 */
@Getter
@NoArgsConstructor
public class UpdateGuestRequest {

    /** 변경할 그룹 OID. null이면 현재 그룹 유지. clearGroup=true이면 무시된다. */
    @Pattern(regexp = "^[0-9]{14}$", message = "그룹 OID는 14자리 숫자여야 합니다.")
    private String groupOid;

    /** true이면 group_oid를 NULL로 초기화하여 미분류 상태로 전환한다. */
    private boolean clearGroup;

    @Size(max = 50, message = "하객 이름은 50자 이내여야 합니다.")
    private String name;

    @Min(value = 0, message = "동반 인원은 0 이상이어야 합니다.")
    @Max(value = 99, message = "동반 인원은 99명 이하여야 합니다.")
    private Integer companionCount;

    @Min(value = 0, message = "축의금은 0 이상이어야 합니다.")
    @Max(value = 9_999_999L, message = "축의금은 9,999,999원 이하여야 합니다.")
    private Long giftAmount;

    @Pattern(regexp = "^(PAPER|MOBILE|NONE)$", message = "청첩장 상태는 PAPER, MOBILE, NONE 중 하나여야 합니다.")
    private String invitationStatus;

    @Pattern(regexp = "^(ATTEND|ABSENT|UNDECIDED)$", message = "참석 여부는 ATTEND, ABSENT, UNDECIDED 중 하나여야 합니다.")
    private String attendStatus;

    @Size(max = 500, message = "메모는 500자 이내여야 합니다.")
    private String memo;
}
