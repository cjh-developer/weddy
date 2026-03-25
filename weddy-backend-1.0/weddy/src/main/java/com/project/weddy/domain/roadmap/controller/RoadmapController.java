package com.project.weddy.domain.roadmap.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.roadmap.dto.request.AddTravelStopRequest;
import com.project.weddy.domain.roadmap.dto.request.CreateHallTourRequest;
import com.project.weddy.domain.roadmap.dto.request.CreateRoadmapStepRequest;
import com.project.weddy.domain.roadmap.dto.request.UpdateRoadmapStepRequest;
import com.project.weddy.domain.roadmap.dto.response.HallTourResponse;
import com.project.weddy.domain.roadmap.dto.response.RoadmapStepResponse;
import com.project.weddy.domain.roadmap.dto.response.TravelStopResponse;
import com.project.weddy.domain.roadmap.service.RoadmapService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 웨딩 관리(로드맵) API 컨트롤러.
 * 모든 엔드포인트는 유효한 JWT 액세스 토큰이 필요하다.
 * 솔로/커플 모두 접근 가능하다.
 */
@Tag(name = "Roadmap", description = "웨딩 관리(로드맵) CRUD")
@SecurityRequirement(name = "Bearer Authentication")
@RestController
@RequestMapping("/api/v1/roadmap")
@RequiredArgsConstructor
public class RoadmapController {

    private final RoadmapService roadmapService;

    // =========================================================
    // 단계 CRUD
    // =========================================================

    @Operation(summary = "웨딩 관리 단계 목록 조회", description = "sortOrder 오름차순으로 단계 목록을 반환한다.")
    @GetMapping
    public ApiResponse<List<RoadmapStepResponse>> getSteps(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("웨딩 관리 단계 조회 성공", roadmapService.getSteps(userOid));
    }

    @Operation(summary = "웨딩 관리 단계 생성", description = "새 단계를 생성한다. 최대 20개까지 생성 가능.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<RoadmapStepResponse> createStep(
            @AuthenticationPrincipal String userOid,
            @Valid @RequestBody CreateRoadmapStepRequest req) {
        return ApiResponse.success("단계 생성 성공", roadmapService.createStep(userOid, req));
    }

    @Operation(summary = "웨딩 관리 단계 단건 조회", description = "단계 OID로 단건 조회한다.")
    @GetMapping("/{stepOid}")
    public ApiResponse<RoadmapStepResponse> getStep(
            @AuthenticationPrincipal String userOid,
            @PathVariable String stepOid) {
        return ApiResponse.success("단계 조회 성공", roadmapService.getStep(userOid, stepOid));
    }

    @Operation(summary = "웨딩 관리 단계 수정", description = "단계를 부분 수정한다. null 필드는 기존 값 유지.")
    @PutMapping("/{stepOid}")
    public ApiResponse<RoadmapStepResponse> updateStep(
            @AuthenticationPrincipal String userOid,
            @PathVariable String stepOid,
            @Valid @RequestBody UpdateRoadmapStepRequest req) {
        return ApiResponse.success("단계 수정 성공", roadmapService.updateStep(userOid, stepOid, req));
    }

    @Operation(summary = "웨딩 관리 단계 완료 토글", description = "단계의 완료 여부를 토글한다.")
    @PatchMapping("/{stepOid}/toggle")
    public ApiResponse<RoadmapStepResponse> toggleDone(
            @AuthenticationPrincipal String userOid,
            @PathVariable String stepOid) {
        return ApiResponse.success("단계 토글 성공", roadmapService.toggleDone(userOid, stepOid));
    }

    @Operation(summary = "웨딩 관리 단계 삭제",
               description = "단계와 연관된 투어, 경유지, 일정을 모두 삭제한다.")
    @DeleteMapping("/{stepOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteStep(
            @AuthenticationPrincipal String userOid,
            @PathVariable String stepOid) {
        roadmapService.deleteStep(userOid, stepOid);
    }

    // =========================================================
    // 웨딩홀 투어
    // =========================================================

    @Operation(summary = "웨딩홀 투어 목록 조회", description = "특정 단계의 투어 목록을 조회한다.")
    @GetMapping("/{stepOid}/hall-tours")
    public ApiResponse<List<HallTourResponse>> getHallTours(
            @AuthenticationPrincipal String userOid,
            @PathVariable String stepOid) {
        return ApiResponse.success("투어 조회 성공", roadmapService.getHallTours(userOid, stepOid));
    }

    @Operation(summary = "웨딩홀 투어 추가",
               description = "투어를 추가한다. scheduleTitle 지정 시 tourDate 기준 일정이 자동 등록된다.")
    @PostMapping("/{stepOid}/hall-tours")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<HallTourResponse> addHallTour(
            @AuthenticationPrincipal String userOid,
            @PathVariable String stepOid,
            @Valid @RequestBody CreateHallTourRequest req) {
        return ApiResponse.success("투어 추가 성공", roadmapService.addHallTour(userOid, stepOid, req));
    }

    @Operation(summary = "웨딩홀 투어 삭제", description = "투어와 연관 일정을 삭제한다.")
    @DeleteMapping("/{stepOid}/hall-tours/{tourOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteHallTour(
            @AuthenticationPrincipal String userOid,
            @PathVariable String stepOid,
            @PathVariable String tourOid) {
        roadmapService.deleteHallTour(userOid, stepOid, tourOid);
    }

    // =========================================================
    // 항공권 경유지
    // =========================================================

    @Operation(summary = "항공권 경유지 추가", description = "경유지를 추가한다. stopOrder는 자동 증가한다.")
    @PostMapping("/{stepOid}/travel-stops")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<TravelStopResponse> addTravelStop(
            @AuthenticationPrincipal String userOid,
            @PathVariable String stepOid,
            @Valid @RequestBody AddTravelStopRequest req) {
        return ApiResponse.success("경유지 추가 성공",
                roadmapService.addTravelStop(userOid, stepOid, req));
    }

    @Operation(summary = "항공권 경유지 삭제", description = "경유지를 삭제한다.")
    @DeleteMapping("/{stepOid}/travel-stops/{stopOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteTravelStop(
            @AuthenticationPrincipal String userOid,
            @PathVariable String stepOid,
            @PathVariable String stopOid) {
        roadmapService.deleteTravelStop(userOid, stepOid, stopOid);
    }
}
