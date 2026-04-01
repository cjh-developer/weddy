package com.project.weddy.domain.guest.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 하객 추가 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class CreateGuestRequest {

    /** 소속 그룹 OID (null이면 미분류) */
    @Pattern(regexp = "^[0-9]{14}$", message = "그룹 OID는 14자리 숫자여야 합니다.")
    private String groupOid;

    @NotBlank(message = "하객 이름은 필수입니다.")
    @Size(max = 50, message = "하객 이름은 50자 이내여야 합니다.")
    @Pattern(regexp = "^[가-힣a-zA-Z0-9\\s\\-\\.]{1,50}$", message = "이름은 한글, 영문, 숫자, 공백, 하이픈, 점만 허용됩니다.")
    private String name;

    @Min(value = 0, message = "동반 인원은 0 이상이어야 합니다.")
    @Max(value = 99, message = "동반 인원은 99명 이하여야 합니다.")
    private int companionCount;

    @Min(value = 0, message = "축의금은 0 이상이어야 합니다.")
    @Max(value = 9_999_999L, message = "축의금은 9,999,999원 이하여야 합니다.")
    private long giftAmount;

    @Pattern(regexp = "^(PAPER|MOBILE|NONE)$", message = "청첩장 상태는 PAPER, MOBILE, NONE 중 하나여야 합니다.")
    private String invitationStatus = "NONE";

    @Pattern(regexp = "^(ATTEND|ABSENT|UNDECIDED)$", message = "참석 여부는 ATTEND, ABSENT, UNDECIDED 중 하나여야 합니다.")
    private String attendStatus = "UNDECIDED";

    @Size(max = 500, message = "메모는 500자 이내여야 합니다.")
    private String memo;
}
