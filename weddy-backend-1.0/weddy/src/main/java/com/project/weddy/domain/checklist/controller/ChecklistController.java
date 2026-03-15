package com.project.weddy.domain.checklist.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.checklist.dto.request.CreateChecklistItemRequest;
import com.project.weddy.domain.checklist.dto.request.CreateChecklistRequest;
import com.project.weddy.domain.checklist.dto.request.UpdateChecklistItemRequest;
import com.project.weddy.domain.checklist.dto.response.ChecklistItemResponse;
import com.project.weddy.domain.checklist.dto.response.ChecklistResponse;
import com.project.weddy.domain.checklist.service.ChecklistService;
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
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 체크리스트 CRUD API 컨트롤러.
 * 모든 엔드포인트는 유효한 JWT 액세스 토큰이 필요하다.
 * 커플에 연결된 사용자만 접근 가능하다.
 */
@Tag(name = "Checklists", description = "체크리스트 CRUD")
@SecurityRequirement(name = "Bearer Authentication")
@RestController
@RequestMapping("/api/v1/checklists")
@RequiredArgsConstructor
public class ChecklistController {

    private final ChecklistService checklistService;

    @Operation(summary = "체크리스트 목록 조회", description = "커플의 전체 체크리스트와 항목을 조회합니다.")
    @GetMapping
    public ApiResponse<List<ChecklistResponse>> getChecklists(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("체크리스트 조회 성공", checklistService.getChecklists(userOid));
    }

    @Operation(summary = "체크리스트 생성", description = "새 체크리스트를 생성합니다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ChecklistResponse> createChecklist(
            @AuthenticationPrincipal String userOid,
            @Valid @RequestBody CreateChecklistRequest req) {
        return ApiResponse.success("체크리스트 생성 성공", checklistService.createChecklist(userOid, req));
    }

    @Operation(summary = "체크리스트 삭제", description = "체크리스트와 소속 항목을 모두 삭제합니다.")
    @DeleteMapping("/{checklistOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteChecklist(
            @AuthenticationPrincipal String userOid,
            @PathVariable String checklistOid) {
        checklistService.deleteChecklist(userOid, checklistOid);
    }

    @Operation(summary = "항목 추가", description = "체크리스트에 항목을 추가합니다.")
    @PostMapping("/{checklistOid}/items")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ChecklistItemResponse> addItem(
            @AuthenticationPrincipal String userOid,
            @PathVariable String checklistOid,
            @Valid @RequestBody CreateChecklistItemRequest req) {
        return ApiResponse.success("항목 추가 성공", checklistService.addItem(userOid, checklistOid, req));
    }

    @Operation(summary = "항목 수정", description = "체크리스트 항목을 부분 수정합니다. null 필드는 기존 값 유지.")
    @PatchMapping("/{checklistOid}/items/{itemOid}")
    public ApiResponse<ChecklistItemResponse> updateItem(
            @AuthenticationPrincipal String userOid,
            @PathVariable String checklistOid,
            @PathVariable String itemOid,
            @Valid @RequestBody UpdateChecklistItemRequest req) {
        return ApiResponse.success("항목 수정 성공",
                checklistService.updateItem(userOid, checklistOid, itemOid, req));
    }

    @Operation(summary = "항목 삭제", description = "체크리스트 항목을 삭제합니다.")
    @DeleteMapping("/{checklistOid}/items/{itemOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteItem(
            @AuthenticationPrincipal String userOid,
            @PathVariable String checklistOid,
            @PathVariable String itemOid) {
        checklistService.deleteItem(userOid, checklistOid, itemOid);
    }

    @Operation(summary = "홈 프리뷰 조회", description = "홈 화면용 미완료 항목 최대 3개를 반환합니다.")
    @GetMapping("/home-preview")
    public ApiResponse<List<ChecklistItemResponse>> getHomePreview(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("홈 프리뷰 조회 성공", checklistService.getHomePreview(userOid, 3));
    }
}
