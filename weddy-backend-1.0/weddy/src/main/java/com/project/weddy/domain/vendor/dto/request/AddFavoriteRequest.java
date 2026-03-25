package com.project.weddy.domain.vendor.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 즐겨찾기 추가 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class AddFavoriteRequest {

    @NotBlank(message = "업체 OID는 필수입니다.")
    @Size(min = 14, max = 14, message = "업체 OID는 14자리여야 합니다.")
    private String vendorOid;
}
