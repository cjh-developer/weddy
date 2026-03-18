package com.project.weddy.domain.budget.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.budget.dto.request.CreateBudgetItemRequest;
import com.project.weddy.domain.budget.dto.request.CreateBudgetRequest;
import com.project.weddy.domain.budget.dto.request.UpdateBudgetItemRequest;
import com.project.weddy.domain.budget.dto.request.UpsertBudgetSettingsRequest;
import com.project.weddy.domain.budget.dto.response.BudgetItemResponse;
import com.project.weddy.domain.budget.dto.response.BudgetResponse;
import com.project.weddy.domain.budget.dto.response.BudgetSettingsResponse;
import com.project.weddy.domain.budget.dto.response.BudgetSummaryResponse;
import com.project.weddy.domain.budget.service.BudgetService;
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
 * 예산 CRUD API 컨트롤러.
 * 모든 엔드포인트는 유효한 JWT 액세스 토큰이 필요하다.
 * 커플에 연결된 사용자만 접근 가능하다. 미연결 시 403 BUDGET_003 반환.
 */
@Tag(name = "Budgets", description = "예산 CRUD")
@SecurityRequirement(name = "Bearer Authentication")
@RestController
@RequestMapping("/api/v1/budgets")
@RequiredArgsConstructor
public class BudgetController {

    private final BudgetService budgetService;

    @Operation(summary = "예산 목록 조회", description = "커플의 전체 예산 카테고리와 항목, 집계 금액을 조회합니다.")
    @GetMapping
    public ApiResponse<List<BudgetResponse>> getBudgets(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("예산 조회 성공", budgetService.getBudgets(userOid));
    }

    @Operation(summary = "예산 카테고리 생성", description = "새 예산 카테고리를 생성합니다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<BudgetResponse> createBudget(
            @AuthenticationPrincipal String userOid,
            @Valid @RequestBody CreateBudgetRequest req) {
        return ApiResponse.success("예산 생성 성공", budgetService.createBudget(userOid, req));
    }

    @Operation(summary = "예산 카테고리 삭제", description = "예산 카테고리와 소속 항목을 모두 삭제합니다.")
    @DeleteMapping("/{budgetOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteBudget(
            @AuthenticationPrincipal String userOid,
            @PathVariable String budgetOid) {
        budgetService.deleteBudget(userOid, budgetOid);
    }

    @Operation(summary = "예산 항목 추가", description = "예산 카테고리에 지출 항목을 추가합니다.")
    @PostMapping("/{budgetOid}/items")
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<BudgetItemResponse> addItem(
            @AuthenticationPrincipal String userOid,
            @PathVariable String budgetOid,
            @Valid @RequestBody CreateBudgetItemRequest req) {
        return ApiResponse.success("항목 추가 성공", budgetService.addItem(userOid, budgetOid, req));
    }

    @Operation(summary = "예산 항목 수정", description = "예산 항목을 부분 수정합니다. null 필드는 기존 값 유지.")
    @PatchMapping("/{budgetOid}/items/{itemOid}")
    public ApiResponse<BudgetItemResponse> updateItem(
            @AuthenticationPrincipal String userOid,
            @PathVariable String budgetOid,
            @PathVariable String itemOid,
            @Valid @RequestBody UpdateBudgetItemRequest req) {
        return ApiResponse.success("항목 수정 성공",
                budgetService.updateItem(userOid, budgetOid, itemOid, req));
    }

    @Operation(summary = "예산 항목 삭제", description = "예산 항목을 삭제합니다.")
    @DeleteMapping("/{budgetOid}/items/{itemOid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteItem(
            @AuthenticationPrincipal String userOid,
            @PathVariable String budgetOid,
            @PathVariable String itemOid) {
        budgetService.deleteItem(userOid, budgetOid, itemOid);
    }

    @Operation(summary = "전체 예산 설정 조회", description = "전체 예산 설정값을 조회합니다. 미설정이면 totalBudget=null을 반환합니다.")
    @GetMapping("/settings")
    public ApiResponse<BudgetSettingsResponse> getSettings(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("예산 설정 조회 성공", budgetService.getSettings(userOid));
    }

    @Operation(summary = "전체 예산 설정 저장", description = "전체 예산을 설정합니다. 기존 설정이 있으면 갱신합니다.")
    @PutMapping("/settings")
    public ApiResponse<BudgetSettingsResponse> upsertSettings(
            @AuthenticationPrincipal String userOid,
            @Valid @RequestBody UpsertBudgetSettingsRequest req) {
        return ApiResponse.success("예산 설정 저장 성공", budgetService.upsertSettings(userOid, req));
    }

    @Operation(summary = "예산 요약 조회", description = "홈 화면용 총 계획 금액, 사용 금액, 사용률, 전체 예산 설정값을 반환합니다.")
    @GetMapping("/summary")
    public ApiResponse<BudgetSummaryResponse> getSummary(
            @AuthenticationPrincipal String userOid) {
        return ApiResponse.success("예산 요약 조회 성공", budgetService.getSummary(userOid));
    }
}
