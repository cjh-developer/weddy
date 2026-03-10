package com.project.weddy.domain.user.dto.response;

import lombok.Builder;
import lombok.Getter;

/**
 * 인증 응답 DTO.
 * 로그인, 회원가입, 토큰 갱신 후 클라이언트에 전달되는 데이터를 담는다.
 */
@Getter
@Builder
public class AuthResponse {

    /** JWT 액세스 토큰 */
    private String accessToken;

    /** JWT 리프레시 토큰 */
    private String refreshToken;

    /** 사용자 엔티티 PK (14자리 숫자 문자열) */
    private String userOid;

    /** 로그인 아이디 */
    private String userId;

    /** 사용자 이름 */
    private String name;

    /** 사용자 역할 (GROOM / BRIDE) */
    private String role;
}
