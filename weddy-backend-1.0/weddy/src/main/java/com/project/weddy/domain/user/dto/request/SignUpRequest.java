package com.project.weddy.domain.user.dto.request;

import com.project.weddy.domain.user.entity.UserRole;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;

/**
 * 회원가입 요청 DTO.
 * Bean Validation 어노테이션으로 입력값을 검증한다.
 */
@Getter
public class SignUpRequest {

    @NotBlank(message = "아이디는 필수입니다.")
    @Size(min = 4, max = 20, message = "아이디는 4~20자 사이여야 합니다.")
    private String userId;

    @NotBlank(message = "비밀번호는 필수입니다.")
    @Size(min = 8, max = 30, message = "비밀번호는 8~30자 사이여야 합니다.")
    private String password;

    @NotBlank(message = "이름은 필수입니다.")
    private String name;

    @NotBlank(message = "휴대폰 번호는 필수입니다.")
    private String handPhone;

    @NotBlank(message = "이메일은 필수입니다.")
    @Email(message = "올바른 이메일 형식이 아닙니다.")
    private String email;

    @NotNull(message = "역할(GROOM/BRIDE)은 필수입니다.")
    private UserRole role;
}
