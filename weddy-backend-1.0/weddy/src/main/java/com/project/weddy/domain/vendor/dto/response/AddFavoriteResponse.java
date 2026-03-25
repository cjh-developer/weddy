package com.project.weddy.domain.vendor.dto.response;

import lombok.Builder;
import lombok.Getter;

/**
 * 즐겨찾기 추가 응답 DTO.
 * 클라이언트가 즐겨찾기 취소 시 favoriteOid로 직접 DELETE 호출할 수 있도록 포함한다.
 */
@Getter
@Builder
public class AddFavoriteResponse {

    private String favoriteOid;
    private String vendorOid;
}
