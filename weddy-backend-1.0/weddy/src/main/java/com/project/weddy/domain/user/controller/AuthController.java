package com.project.weddy.domain.user.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.user.dto.request.LoginRequest;
import com.project.weddy.domain.user.dto.request.SignUpRequest;
import com.project.weddy.domain.user.dto.request.TokenRefreshRequest;
import com.project.weddy.domain.user.dto.response.AuthResponse;
import com.project.weddy.domain.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * 인증 관련 공개 API 컨트롤러.
 * /api/v1/auth/** 경로는 SecurityConfig에서 인증 없이 접근 가능하다.
 */
@Tag(name = "Auth", description = "회원가입 / 로그인 / 토큰 갱신")
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    /**
     * 회원가입.
     * 성공 시 액세스/리프레시 토큰을 즉시 발급하여 반환한다.
     */
    @Operation(summary = "회원가입", description = "신규 사용자 등록 및 토큰 발급")
    @PostMapping("/signup")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<AuthResponse> signup(@Valid @RequestBody SignUpRequest request) {
        AuthResponse authResponse = userService.signup(request);
        return ApiResponse.success(authResponse);
    }

    /**
     * 로그인.
     * 아이디/비밀번호 검증 후 액세스/리프레시 토큰을 발급한다.
     */
    @Operation(summary = "로그인", description = "아이디/비밀번호 인증 및 토큰 발급")
    @PostMapping("/login")
    public ApiResponse<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse authResponse = userService.login(request);
        return ApiResponse.success(authResponse);
    }

    /**
     * 액세스 토큰 갱신.
     * 유효한 리프레시 토큰을 사용하여 새로운 액세스/리프레시 토큰을 발급한다.
     */
    @Operation(summary = "토큰 갱신", description = "리프레시 토큰으로 새 액세스/리프레시 토큰 발급")
    @PostMapping("/refresh")
    public ApiResponse<AuthResponse> refresh(@Valid @RequestBody TokenRefreshRequest request) {
        AuthResponse authResponse = userService.refreshToken(request.getRefreshToken());
        return ApiResponse.success(authResponse);
    }
}
