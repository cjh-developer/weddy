package com.project.weddy.domain.vendor.dto.response;

import com.project.weddy.domain.vendor.entity.Vendor;
import lombok.Builder;
import lombok.Getter;

/**
 * 업체 상세 조회 응답 DTO.
 * 즐겨찾기 취소 시 필요한 favoriteOid를 포함한다.
 * ownerOid 등 내부 식별자는 절대 포함하지 않는다.
 */
@Getter
@Builder
public class VendorDetailResponse {

    private String oid;
    private String name;
    private String category;
    private String address;
    private String phone;
    private String description;
    private String homepageUrl;
    private boolean isFavorite;

    /** 즐겨찾기 OID. 즐겨찾기하지 않은 경우 null. */
    private String favoriteOid;

    /**
     * Vendor 엔티티와 즐겨찾기 OID를 조합하여 응답 DTO를 생성한다.
     *
     * @param vendor      업체 엔티티
     * @param favoriteOid 현재 사용자의 즐겨찾기 OID (즐겨찾기하지 않은 경우 null)
     * @return 업체 상세 응답 DTO
     */
    public static VendorDetailResponse from(Vendor vendor, String favoriteOid) {
        return VendorDetailResponse.builder()
                .oid(vendor.getOid())
                .name(vendor.getName())
                .category(vendor.getCategory())
                .address(vendor.getAddress())
                .phone(vendor.getPhone())
                .description(vendor.getDescription())
                .homepageUrl(vendor.getHomepageUrl())
                .isFavorite(favoriteOid != null)
                .favoriteOid(favoriteOid)
                .build();
    }
}
