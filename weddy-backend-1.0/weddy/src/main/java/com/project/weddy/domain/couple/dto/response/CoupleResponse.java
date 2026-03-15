package com.project.weddy.domain.couple.dto.response;

import com.project.weddy.domain.couple.entity.Couple;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

/**
 * 커플 정보 응답 DTO.
 */
@Getter
@Builder
public class CoupleResponse {

    private String coupleOid;
    private String groomOid;
    private String groomName;
    private String brideOid;
    private String brideName;
    private LocalDate weddingDate;
    private Long totalBudget;

    public static CoupleResponse from(Couple couple, String groomName, String brideName) {
        return CoupleResponse.builder()
                .coupleOid(couple.getOid())
                .groomOid(couple.getGroomOid())
                .groomName(groomName)
                .brideOid(couple.getBrideOid())
                .brideName(brideName)
                .weddingDate(couple.getWeddingDate())
                .totalBudget(couple.getTotalBudget())
                .build();
    }
}
