package com.project.weddy.domain.couple.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.couple.dto.request.ConnectCoupleRequest;
import com.project.weddy.domain.couple.dto.response.CoupleResponse;
import com.project.weddy.domain.couple.service.CoupleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * 커플 연결 및 조회 API 컨트롤러.
 * 모든 엔드포인트는 유효한 JWT 액세스 토큰이 필요하다.
 */
@Tag(name = "Couples", description = "커플 연결 및 조회")
@SecurityRequirement(name = "Bearer Authentication")
@RestController
@RequestMapping("/api/v1/couples")
@RequiredArgsConstructor
public class CoupleController {

    private final CoupleService coupleService;

    @Operation(summary = "커플 연결", description = "파트너의 초대 코드를 입력하여 커플을 연결합니다.")
    @PostMapping("/connect")
    public ApiResponse<CoupleResponse> connectCouple(
            @AuthenticationPrincipal String userOid,
            @RequestBody @Valid ConnectCoupleRequest request) {
        CoupleResponse response = coupleService.connectCouple(userOid, request.getPartnerInviteCode());
        return ApiResponse.success("파트너 연결이 완료되었습니다.", response);
    }

    @Operation(summary = "내 커플 정보 조회", description = "현재 로그인 사용자의 커플 정보를 반환합니다.")
    @GetMapping("/me")
    public ApiResponse<CoupleResponse> getMyCouple(@AuthenticationPrincipal String userOid) {
        CoupleResponse response = coupleService.getMyCouple(userOid);
        return ApiResponse.success(response);
    }

    @Operation(summary = "커플 연결 해제", description = "현재 로그인 사용자의 커플 연결을 해제합니다.")
    @DeleteMapping("/me")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void disconnectCouple(@AuthenticationPrincipal String userOid) {
        coupleService.disconnectCouple(userOid);
    }
}
