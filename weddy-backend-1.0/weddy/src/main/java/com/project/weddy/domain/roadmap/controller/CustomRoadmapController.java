package com.project.weddy.domain.roadmap.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.roadmap.dto.request.CreateCustomRoadmapRequest;
import com.project.weddy.domain.roadmap.dto.request.RenameCustomRoadmapRequest;
import com.project.weddy.domain.roadmap.dto.response.CustomRoadmapResponse;
import com.project.weddy.domain.roadmap.service.RoadmapService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 직접 로드맵 CRUD 컨트롤러.
 *
 * <p>기본 로드맵(9단계 고정 템플릿)과 달리 사용자가 자유롭게 이름을 지정하여
 * 생성하는 로드맵 컨테이너를 관리한다.
 * 각 직접 로드맵에는 RoadmapStep(group_oid 비 NULL)이 소속될 수 있다.
 *
 * <p>엔드포인트 요약:
 * <ul>
 *   <li>GET  /api/v1/roadmap/custom          — 목록 조회 (단계 포함)</li>
 *   <li>POST /api/v1/roadmap/custom          — 생성 (최대 10개)</li>
 *   <li>PATCH /api/v1/roadmap/custom/{groupOid} — 이름 변경</li>
 *   <li>DELETE /api/v1/roadmap/custom/{groupOid} — 삭제 (소속 단계 연쇄 삭제)</li>
 * </ul>
 */
@Tag(name = "Custom Roadmap", description = "직접 로드맵 CRUD")
@SecurityRequirement(name = "Bearer Authentication")
@RestController
@RequestMapping("/api/v1/roadmap/custom")
@RequiredArgsConstructor
public class CustomRoadmapController {

    private final RoadmapService roadmapService;

    /**
     * 소유자의 직접 로드맵 목록을 단계와 함께 조회한다.
     *
     * @param userOid JWT 인증 사용자 OID
     * @return 직접 로드맵 목록 (각 로드맵에 소속 단계 포함)
     */
    @Operation(summary = "직접 로드맵 목록 조회 (단계 포함)")
    @GetMapping
    public ApiResponse<List<CustomRoadmapResponse>> getCustomRoadmaps(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("직접 로드맵 조회 성공", roadmapService.getCustomRoadmaps(userOid));
    }

    /**
     * 직접 로드맵을 생성한다.
     * 소유자당 최대 10개까지 생성 가능하다.
     *
     * @param userOid JWT 인증 사용자 OID
     * @param req     생성 요청 (name 필수)
     * @return 생성된 직접 로드맵 (steps는 빈 리스트)
     */
    @Operation(summary = "직접 로드맵 생성 (최대 10개)")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<CustomRoadmapResponse> createCustomRoadmap(
            @AuthenticationPrincipal String userOid,
            @Valid @RequestBody CreateCustomRoadmapRequest req) {
        return ApiResponse.success("직접 로드맵 생성 성공", roadmapService.createCustomRoadmap(userOid, req));
    }

    /**
     * 직접 로드맵의 이름을 변경한다.
     *
     * @param userOid  JWT 인증 사용자 OID
     * @param groupOid 변경할 직접 로드맵 OID
     * @param req      이름 변경 요청
     * @return 변경된 직접 로드맵 (steps는 빈 리스트)
     */
    @Operation(summary = "직접 로드맵 이름 변경")
    @PatchMapping("/{groupOid}")
    public ApiResponse<CustomRoadmapResponse> renameCustomRoadmap(
            @AuthenticationPrincipal String userOid,
            @PathVariable String groupOid,
            @Valid @RequestBody RenameCustomRoadmapRequest req) {
        return ApiResponse.success("로드맵 이름 변경 성공",
                roadmapService.renameCustomRoadmap(userOid, groupOid, req));
    }

    /**
     * 직접 로드맵과 소속된 모든 단계(및 연관 데이터)를 삭제한다.
     *
     * @param userOid  JWT 인증 사용자 OID
     * @param groupOid 삭제할 직접 로드맵 OID
     */
    @Operation(summary = "직접 로드맵 삭제 (소속 단계 포함 연쇄 삭제)")
    @DeleteMapping("/{groupOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteCustomRoadmap(
            @AuthenticationPrincipal String userOid,
            @PathVariable String groupOid) {
        roadmapService.deleteCustomRoadmap(userOid, groupOid);
    }
}
