package com.project.weddy.domain.roadmap.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 웨딩 관리 단계 순서 일괄 변경 요청 DTO.
 * orders 배열의 각 항목은 stepOid와 새 sortOrder를 포함한다.
 */
@Getter
@NoArgsConstructor
public class ReorderRequest {

    @NotNull
    @Valid
    private List<OrderItem> orders;

    @Getter
    @NoArgsConstructor
    public static class OrderItem {

        @NotBlank
        private String oid;

        @Min(1)
        private int sortOrder;
    }
}
