package com.project.weddy.domain.couple.dto.response;

import com.project.weddy.domain.couple.entity.Couple;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

/**
 * 커플 정보 응답 DTO.
 *
 * <p>groomOid/brideOid 는 의도적으로 제외한다. 내부 식별자가 응답에 노출되면
 * 클라이언트가 타인의 OID를 추측하여 체크리스트·예산 API에 IDOR 공격을 시도할 수
 * 있기 때문이다. 이름(groomName/brideName)만으로 UI 표시에 충분하다.
 */
@Getter
@Builder
public class CoupleResponse {

    private String coupleOid;
    private String groomName;
    private String brideName;
    private LocalDate weddingDate;
    private Long totalBudget;

    public static CoupleResponse from(Couple couple, String groomName, String brideName) {
        return CoupleResponse.builder()
                .coupleOid(couple.getOid())
                .groomName(groomName)
                .brideName(brideName)
                .weddingDate(couple.getWeddingDate())
                .totalBudget(couple.getTotalBudget())
                .build();
    }
}
