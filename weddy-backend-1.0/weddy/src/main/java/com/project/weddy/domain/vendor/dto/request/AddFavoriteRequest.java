package com.project.weddy.domain.vendor.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 즐겨찾기 추가 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class AddFavoriteRequest {

    @NotBlank(message = "업체 OID는 필수입니다.")
    @Pattern(regexp = "^[0-9]{14}$", message = "업체 OID는 14자리 숫자여야 합니다.")
    private String vendorOid;
}
