package com.project.weddy.domain.couple.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 커플 연결 요청 DTO.
 * 파트너의 초대 코드를 입력하여 커플을 연결한다.
 *
 * <p>초대 코드 형식: {@code WED-XXXXXX} (X는 대문자 알파벳 또는 숫자, 6자리)
 * 예시: {@code WED-A3B7CX}
 */
@Getter
@NoArgsConstructor
public class ConnectCoupleRequest {

    @NotBlank(message = "파트너 초대 코드는 필수입니다.")
    @Pattern(regexp = "^WED-[A-Z0-9]{6}$", message = "초대 코드 형식이 올바르지 않습니다. (예: WED-A3B7CX)")
    private String partnerInviteCode;
}
