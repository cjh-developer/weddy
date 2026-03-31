package com.project.weddy.domain.guest.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.guest.dto.request.CreateGuestGroupRequest;
import com.project.weddy.domain.guest.dto.request.CreateGuestRequest;
import com.project.weddy.domain.guest.dto.request.UpdateGuestGroupRequest;
import com.project.weddy.domain.guest.dto.request.UpdateGuestRequest;
import com.project.weddy.domain.guest.dto.response.GuestGroupResponse;
import com.project.weddy.domain.guest.dto.response.GuestResponse;
import com.project.weddy.domain.guest.dto.response.GuestSummaryResponse;
import com.project.weddy.domain.guest.service.GuestService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 하객 관리 API 컨트롤러.
 *
 * <p>모든 엔드포인트는 유효한 JWT 액세스 토큰이 필요하다.
 * /summary 경로는 /{guestOid} 보다 먼저 선언되어야 경로 충돌이 발생하지 않는다.
 */
@Tag(name = "Guests", description = "하객 관리 (그룹 CRUD + 하객 CRUD + 집계)")
@SecurityRequirement(name = "Bearer Authentication")
@Validated
@RestController
@RequestMapping("/api/v1/guests")
@RequiredArgsConstructor
public class GuestController {

    private final GuestService guestService;

    // =========================================================================
    // 하객 그룹 CRUD
    // =========================================================================

    @Operation(summary = "하객 그룹 목록 조회",
               description = "소유자의 하객 그룹 목록을 sort_order 순으로 반환한다. 각 그룹에 소속된 하객 수를 포함한다.")
    @GetMapping("/groups")
    public ApiResponse<List<GuestGroupResponse>> getGroups(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("하객 그룹 조회 성공", guestService.getGroups(userOid));
    }

    @Operation(summary = "하객 그룹 생성",
               description = "새로운 하객 그룹을 생성한다. 그룹은 최대 20개까지 생성할 수 있다.")
    @PostMapping("/groups")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<GuestGroupResponse> createGroup(
            @AuthenticationPrincipal String userOid,
            @Valid @RequestBody CreateGuestGroupRequest request) {
        return ApiResponse.success("하객 그룹 생성 성공", guestService.createGroup(userOid, request));
    }

    @Operation(summary = "하객 그룹 수정",
               description = "하객 그룹명을 수정한다. is_default=true 기본 그룹은 수정할 수 없다.")
    @PatchMapping("/groups/{groupOid}")
    public ApiResponse<GuestGroupResponse> updateGroup(
            @AuthenticationPrincipal String userOid,
            @PathVariable
            @Pattern(regexp = "^[0-9]{14}$", message = "그룹 OID는 14자리 숫자여야 합니다.")
            String groupOid,
            @Valid @RequestBody UpdateGuestGroupRequest request) {
        return ApiResponse.success("하객 그룹 수정 성공", guestService.updateGroup(userOid, groupOid, request));
    }

    @Operation(summary = "하객 그룹 삭제",
               description = "하객 그룹을 삭제한다. is_default=true 기본 그룹은 삭제할 수 없다. 소속 하객의 group_oid는 NULL로 초기화된다.")
    @DeleteMapping("/groups/{groupOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteGroup(
            @AuthenticationPrincipal String userOid,
            @PathVariable
            @Pattern(regexp = "^[0-9]{14}$", message = "그룹 OID는 14자리 숫자여야 합니다.")
            String groupOid) {
        guestService.deleteGroup(userOid, groupOid);
    }

    // =========================================================================
    // 하객 집계 + 목록 + CRUD
    // 중요: /summary는 /{guestOid}보다 먼저 선언되어야 Spring이 정적 경로를 우선 처리한다.
    // =========================================================================

    /**
     * GET /summary — 정적 경로이므로 /{guestOid} 보다 먼저 선언해야 한다.
     * 순서가 바뀌면 Spring이 "summary"를 guestOid PathVariable로 매핑하여
     * 14자리 숫자 Pattern 검증에 실패하거나 잘못된 메서드로 라우팅된다.
     */
    @Operation(summary = "하객 집계 요약",
               description = "전체/참석/불참/미정 하객 수와 총 축의금을 반환한다. 모든 카운트는 companion_count + 1 기준이다.")
    @GetMapping("/summary")
    public ApiResponse<GuestSummaryResponse> getSummary(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("하객 집계 조회 성공", guestService.getSummary(userOid));
    }

    @Operation(summary = "하객 목록 조회",
               description = "하객 목록을 조회한다. groupOid 파라미터로 특정 그룹만 필터링할 수 있다. " +
                             "sort: NAME_ASC(기본)|ATTEND_STATUS|INVITATION_STATUS|GIFT_HIGH|GIFT_LOW")
    @GetMapping
    public ApiResponse<List<GuestResponse>> getGuests(
            @AuthenticationPrincipal String userOid,
            @RequestParam(required = false)
            @Pattern(regexp = "^[0-9]{14}$", message = "그룹 OID는 14자리 숫자여야 합니다.")
            String groupOid,
            @RequestParam(required = false, defaultValue = "NAME_ASC")
            @Pattern(regexp = "^(NAME_ASC|ATTEND_STATUS|INVITATION_STATUS|GIFT_HIGH|GIFT_LOW)$",
                     message = "유효하지 않은 정렬 기준입니다.")
            String sort) {
        return ApiResponse.success("하객 목록 조회 성공", guestService.getGuests(userOid, groupOid, sort));
    }

    @Operation(summary = "하객 추가",
               description = "하객을 추가한다. 하객은 최대 500명까지 등록할 수 있다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<GuestResponse> createGuest(
            @AuthenticationPrincipal String userOid,
            @Valid @RequestBody CreateGuestRequest request) {
        return ApiResponse.success("하객 추가 성공", guestService.createGuest(userOid, request));
    }

    @Operation(summary = "하객 수정",
               description = "하객 정보를 수정한다. null 필드는 기존 값을 유지한다. clearGroup=true이면 group_oid를 NULL로 초기화한다.")
    @PatchMapping("/{guestOid}")
    public ApiResponse<GuestResponse> updateGuest(
            @AuthenticationPrincipal String userOid,
            @PathVariable
            @Pattern(regexp = "^[0-9]{14}$", message = "하객 OID는 14자리 숫자여야 합니다.")
            String guestOid,
            @Valid @RequestBody UpdateGuestRequest request) {
        return ApiResponse.success("하객 수정 성공", guestService.updateGuest(userOid, guestOid, request));
    }

    @Operation(summary = "하객 삭제",
               description = "하객을 삭제한다.")
    @DeleteMapping("/{guestOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteGuest(
            @AuthenticationPrincipal String userOid,
            @PathVariable
            @Pattern(regexp = "^[0-9]{14}$", message = "하객 OID는 14자리 숫자여야 합니다.")
            String guestOid) {
        guestService.deleteGuest(userOid, guestOid);
    }
}
