package com.project.weddy.domain.guest.dto.response;

import lombok.Builder;
import lombok.Getter;

/**
 * 하객 집계 요약 응답 DTO (홈 화면 대시보드용).
 *
 * <p>모든 카운트는 companion_count + 1 기준 (본인 포함)으로 집계한다.
 * 예) 동반 1명이면 실제 2명으로 카운트.
 */
@Getter
@Builder
public class GuestSummaryResponse {

    /** 전체 하객 수 (SUM(companion_count + 1)) */
    private long totalCount;

    /** 참석 확정 하객 수 (attend_status = 'ATTEND') */
    private long attendCount;

    /** 불참 하객 수 (attend_status = 'ABSENT') */
    private long absentCount;

    /** 미정 하객 수 (attend_status = 'UNDECIDED') */
    private long undecidedCount;

    /** 총 축의금 합계 (원) */
    private long totalGiftAmount;
}
