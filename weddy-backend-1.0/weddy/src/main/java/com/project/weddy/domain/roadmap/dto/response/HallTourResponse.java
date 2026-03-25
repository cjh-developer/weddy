package com.project.weddy.domain.roadmap.dto.response;

import com.project.weddy.domain.roadmap.entity.HallTour;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

/**
 * 웨딩홀 투어 응답 DTO.
 * totalMealCost는 mealPrice × minGuests를 서비스 레이어에서 계산하여 반환한다.
 */
@Getter
@Builder
public class HallTourResponse {

    private String oid;
    private String stepOid;
    private String hallName;
    private LocalDate tourDate;
    private String location;
    private Long rentalFee;
    private Long mealPrice;
    private Integer minGuests;
    private String memo;
    /** mealPrice × minGuests 자동 계산값. 둘 중 하나라도 null이면 null 반환. */
    private Long totalMealCost;

    /**
     * HallTour 엔티티로부터 응답 DTO를 생성한다.
     * totalMealCost는 mealPrice와 minGuests가 모두 null이 아닌 경우에만 계산된다.
     *
     * @param tour 웨딩홀 투어 엔티티
     * @return 응답 DTO
     */
    public static HallTourResponse from(HallTour tour) {
        Long totalMealCost = null;
        if (tour.getMealPrice() != null && tour.getMinGuests() != null) {
            totalMealCost = tour.getMealPrice() * tour.getMinGuests();
        }
        return HallTourResponse.builder()
                .oid(tour.getOid())
                .stepOid(tour.getStepOid())
                .hallName(tour.getHallName())
                .tourDate(tour.getTourDate())
                .location(tour.getLocation())
                .rentalFee(tour.getRentalFee())
                .mealPrice(tour.getMealPrice())
                .minGuests(tour.getMinGuests())
                .memo(tour.getMemo())
                .totalMealCost(totalMealCost)
                .build();
    }
}
