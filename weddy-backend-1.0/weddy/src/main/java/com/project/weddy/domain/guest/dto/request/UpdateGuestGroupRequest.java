package com.project.weddy.domain.guest.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 하객 그룹 수정 요청 DTO.
 * is_default=false 그룹의 이름만 변경할 수 있다.
 */
@Getter
@NoArgsConstructor
public class UpdateGuestGroupRequest {

    @NotBlank(message = "그룹명은 필수입니다.")
    @Size(max = 50, message = "그룹명은 50자 이내여야 합니다.")
    private String name;
}
