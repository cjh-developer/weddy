package com.project.weddy.domain.roadmap.dto.response;

import com.project.weddy.domain.roadmap.entity.TravelStop;
import lombok.Builder;
import lombok.Getter;

/**
 * 항공권 경유지 응답 DTO.
 */
@Getter
@Builder
public class TravelStopResponse {

    private String oid;
    private int stopOrder;
    private String city;

    /**
     * TravelStop 엔티티로부터 응답 DTO를 생성한다.
     *
     * @param stop 경유지 엔티티
     * @return 응답 DTO
     */
    public static TravelStopResponse from(TravelStop stop) {
        return TravelStopResponse.builder()
                .oid(stop.getOid())
                .stopOrder(stop.getStopOrder())
                .city(stop.getCity())
                .build();
    }
}
