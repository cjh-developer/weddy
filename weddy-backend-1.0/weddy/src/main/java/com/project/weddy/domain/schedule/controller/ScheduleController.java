package com.project.weddy.domain.schedule.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.schedule.dto.request.CreateScheduleRequest;
import com.project.weddy.domain.schedule.dto.request.UpdateScheduleRequest;
import com.project.weddy.domain.schedule.dto.response.ScheduleResponse;
import com.project.weddy.domain.schedule.service.ScheduleService;
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
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 일정 CRUD API 컨트롤러.
 * 모든 엔드포인트는 유효한 JWT 액세스 토큰이 필요하다.
 * 솔로/커플 모두 접근 가능하다.
 */
@Tag(name = "Schedules", description = "일정 CRUD")
@SecurityRequirement(name = "Bearer Authentication")
@RestController
@RequestMapping("/api/v1/schedules")
@RequiredArgsConstructor
public class ScheduleController {

    private final ScheduleService scheduleService;

    @Operation(summary = "일정 목록 조회",
               description = "year, month 파라미터 지정 시 해당 월의 일정만 반환한다. 미지정 시 전체 반환.")
    @GetMapping
    public ApiResponse<List<ScheduleResponse>> getSchedules(
            @AuthenticationPrincipal String userOid,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        return ApiResponse.success("일정 조회 성공",
                scheduleService.getSchedules(userOid, year, month));
    }

    @Operation(summary = "일정 생성", description = "새 일정을 생성한다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ScheduleResponse> createSchedule(
            @AuthenticationPrincipal String userOid,
            @Valid @RequestBody CreateScheduleRequest req) {
        return ApiResponse.success("일정 생성 성공", scheduleService.createSchedule(userOid, req));
    }

    @Operation(summary = "일정 단건 조회", description = "일정 OID로 단건 조회한다.")
    @GetMapping("/{scheduleOid}")
    public ApiResponse<ScheduleResponse> getSchedule(
            @AuthenticationPrincipal String userOid,
            @PathVariable String scheduleOid) {
        return ApiResponse.success("일정 조회 성공",
                scheduleService.getSchedule(userOid, scheduleOid));
    }

    @Operation(summary = "일정 수정", description = "일정을 부분 수정한다. null 필드는 기존 값 유지.")
    @PutMapping("/{scheduleOid}")
    public ApiResponse<ScheduleResponse> updateSchedule(
            @AuthenticationPrincipal String userOid,
            @PathVariable String scheduleOid,
            @Valid @RequestBody UpdateScheduleRequest req) {
        return ApiResponse.success("일정 수정 성공",
                scheduleService.updateSchedule(userOid, scheduleOid, req));
    }

    @Operation(summary = "일정 삭제", description = "일정을 삭제한다.")
    @DeleteMapping("/{scheduleOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteSchedule(
            @AuthenticationPrincipal String userOid,
            @PathVariable String scheduleOid) {
        scheduleService.deleteSchedule(userOid, scheduleOid);
    }
}
