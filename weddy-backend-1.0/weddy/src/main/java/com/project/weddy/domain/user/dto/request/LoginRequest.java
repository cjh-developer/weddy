package com.project.weddy.domain.user.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

/**
 * 로그인 요청 DTO.
 */
@Getter
public class LoginRequest {

    @NotBlank(message = "아이디는 필수입니다.")
    private String userId;

    @NotBlank(message = "비밀번호는 필수입니다.")
    private String password;
}
