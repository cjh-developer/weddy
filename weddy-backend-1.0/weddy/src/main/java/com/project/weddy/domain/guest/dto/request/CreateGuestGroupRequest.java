package com.project.weddy.domain.guest.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 하객 그룹 생성 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class CreateGuestGroupRequest {

    @NotBlank(message = "그룹명은 필수입니다.")
    @Size(max = 50, message = "그룹명은 50자 이내여야 합니다.")
    @Pattern(regexp = "^[가-힣a-zA-Z0-9\\s\\-\\_]{1,50}$", message = "그룹명은 한글, 영문, 숫자, 공백, 하이픈, 언더스코어만 허용됩니다.")
    private String name;
}
