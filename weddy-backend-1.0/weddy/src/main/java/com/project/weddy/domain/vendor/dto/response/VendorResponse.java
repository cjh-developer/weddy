package com.project.weddy.domain.vendor.dto.response;

import com.project.weddy.domain.vendor.entity.Vendor;
import lombok.Builder;
import lombok.Getter;

/**
 * 업체 목록/검색 조회 응답 DTO.
 * ownerOid 등 내부 식별자는 절대 포함하지 않는다.
 */
@Getter
@Builder
public class VendorResponse {

    private String oid;
    private String name;
    private String category;
    private String address;
    private String phone;
    private String description;
    private String homepageUrl;
    private boolean isFavorite;

    /**
     * Vendor 엔티티와 즐겨찾기 여부를 조합하여 응답 DTO를 생성한다.
     *
     * @param vendor     업체 엔티티
     * @param isFavorite 현재 사용자의 즐겨찾기 여부
     * @return 업체 응답 DTO
     */
    public static VendorResponse from(Vendor vendor, boolean isFavorite) {
        return VendorResponse.builder()
                .oid(vendor.getOid())
                .name(vendor.getName())
                .category(vendor.getCategory())
                .address(vendor.getAddress())
                .phone(vendor.getPhone())
                .description(vendor.getDescription())
                .homepageUrl(vendor.getHomepageUrl())
                .isFavorite(isFavorite)
                .build();
    }
}
