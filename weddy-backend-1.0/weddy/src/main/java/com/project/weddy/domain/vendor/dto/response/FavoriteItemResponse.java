package com.project.weddy.domain.vendor.dto.response;

import com.project.weddy.domain.vendor.entity.Favorite;
import com.project.weddy.domain.vendor.entity.Vendor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

/**
 * 즐겨찾기 목록 항목 응답 DTO.
 * 즐겨찾기 OID와 업체 정보를 함께 포함한다.
 * ownerOid 등 내부 식별자는 절대 포함하지 않는다.
 */
@Getter
@Builder
public class FavoriteItemResponse {

    private String favoriteOid;
    private VendorResponse vendor;
    private LocalDateTime createdAt;

    /**
     * Favorite 엔티티와 Vendor 엔티티를 조합하여 응답 DTO를 생성한다.
     *
     * @param favorite 즐겨찾기 엔티티
     * @param vendor   업체 엔티티
     * @return 즐겨찾기 항목 응답 DTO
     */
    public static FavoriteItemResponse from(Favorite favorite, Vendor vendor) {
        return FavoriteItemResponse.builder()
                .favoriteOid(favorite.getOid())
                .vendor(VendorResponse.from(vendor, true))
                .createdAt(favorite.getCreatedAt())
                .build();
    }
}
