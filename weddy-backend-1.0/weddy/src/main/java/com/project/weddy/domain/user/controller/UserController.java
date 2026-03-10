package com.project.weddy.domain.user.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.user.dto.response.UserResponse;
import com.project.weddy.domain.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 사용자 정보 API 컨트롤러.
 * 모든 엔드포인트는 유효한 JWT 액세스 토큰이 필요하다.
 *
 * <p>{@code @AuthenticationPrincipal}은 {@link com.project.weddy.common.security.JwtAuthenticationFilter}에서
 * SecurityContext에 설정한 principal(userOid 문자열)을 주입받는다.
 */
@Tag(name = "Users", description = "사용자 정보 조회")
@SecurityRequirement(name = "Bearer Authentication")
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * 내 정보 조회.
     * JWT 토큰의 sub 클레임(userOid)으로 사용자 정보를 반환한다.
     */
    @Operation(summary = "내 정보 조회", description = "JWT 토큰 기반 현재 로그인 사용자 정보 반환")
    @GetMapping("/me")
    public ApiResponse<UserResponse> getMyInfo(@AuthenticationPrincipal String userOid) {
        UserResponse userResponse = userService.getMyInfo(userOid);
        return ApiResponse.success(userResponse);
    }
}
