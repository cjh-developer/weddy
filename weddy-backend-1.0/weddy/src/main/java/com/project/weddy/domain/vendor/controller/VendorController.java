package com.project.weddy.domain.vendor.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.vendor.dto.request.AddFavoriteRequest;
import com.project.weddy.domain.vendor.dto.response.AddFavoriteResponse;
import com.project.weddy.domain.vendor.dto.response.FavoriteItemResponse;
import com.project.weddy.domain.vendor.dto.response.VendorDetailResponse;
import com.project.weddy.domain.vendor.dto.response.VendorResponse;
import com.project.weddy.domain.vendor.service.VendorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 업체 검색 및 즐겨찾기 API 컨트롤러.
 *
 * <p>모든 엔드포인트는 유효한 JWT 액세스 토큰이 필요하다.
 * /favorites 경로는 /{vendorOid}보다 먼저 선언되어 Spring이 정적 경로를 우선 처리한다.
 */
@Tag(name = "Vendors", description = "업체 검색 및 즐겨찾기")
@SecurityRequirement(name = "Bearer Authentication")
@RestController
@RequestMapping("/api/v1/vendors")
@RequiredArgsConstructor
public class VendorController {

    private final VendorService vendorService;

    @Operation(summary = "업체 목록 조회/검색",
               description = "카테고리(HALL|STUDIO|DRESS|MAKEUP|HONEYMOON|ETC)와 키워드(업체명·주소)로 업체를 검색합니다. " +
                             "파라미터를 생략하면 전체 목록을 반환합니다.")
    @GetMapping
    public ApiResponse<List<VendorResponse>> getVendors(
            @AuthenticationPrincipal String userOid,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String keyword) {
        return ApiResponse.success("업체 조회 성공", vendorService.getVendors(userOid, category, keyword));
    }

    /**
     * /favorites 가 /{vendorOid} 보다 먼저 선언되어 있어야 경로 충돌이 발생하지 않는다.
     * Spring MVC는 정적 경로 세그먼트를 PathVariable보다 우선 매핑한다.
     */
    @Operation(summary = "즐겨찾기 목록 조회",
               description = "현재 사용자(또는 커플)의 즐겨찾기 업체 목록을 최신 등록 순으로 반환합니다.")
    @GetMapping("/favorites")
    public ApiResponse<List<FavoriteItemResponse>> getFavorites(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("즐겨찾기 조회 성공", vendorService.getFavorites(userOid));
    }

    @Operation(summary = "업체 상세 조회",
               description = "업체 상세 정보와 현재 사용자의 즐겨찾기 OID를 반환합니다.")
    @GetMapping("/{vendorOid}")
    public ApiResponse<VendorDetailResponse> getVendor(
            @AuthenticationPrincipal String userOid,
            @PathVariable String vendorOid) {
        return ApiResponse.success("업체 상세 조회 성공", vendorService.getVendor(userOid, vendorOid));
    }

    @Operation(summary = "즐겨찾기 추가",
               description = "업체를 즐겨찾기에 추가합니다. 이미 즐겨찾기한 업체는 409를 반환합니다.")
    @PostMapping("/favorites")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<AddFavoriteResponse> addFavorite(
            @AuthenticationPrincipal String userOid,
            @Valid @RequestBody AddFavoriteRequest request) {
        return ApiResponse.success("즐겨찾기 추가 성공", vendorService.addFavorite(userOid, request));
    }

    @Operation(summary = "즐겨찾기 삭제",
               description = "즐겨찾기를 삭제합니다. 본인 소유가 아닌 즐겨찾기 접근 시 401을 반환합니다.")
    @DeleteMapping("/favorites/{favoriteOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeFavorite(
            @AuthenticationPrincipal String userOid,
            @PathVariable String favoriteOid) {
        vendorService.removeFavorite(userOid, favoriteOid);
    }
}
