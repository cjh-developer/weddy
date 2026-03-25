package com.project.weddy.domain.vendor.service;

import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.domain.couple.entity.Couple;
import com.project.weddy.domain.couple.repository.CoupleRepository;
import com.project.weddy.domain.vendor.dto.request.AddFavoriteRequest;
import com.project.weddy.domain.vendor.dto.response.AddFavoriteResponse;
import com.project.weddy.domain.vendor.dto.response.FavoriteItemResponse;
import com.project.weddy.domain.vendor.dto.response.VendorDetailResponse;
import com.project.weddy.domain.vendor.dto.response.VendorResponse;
import com.project.weddy.domain.vendor.entity.Favorite;
import com.project.weddy.domain.vendor.entity.Vendor;
import com.project.weddy.domain.vendor.repository.FavoriteRepository;
import com.project.weddy.domain.vendor.repository.VendorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * 업체 검색 및 즐겨찾기 서비스.
 *
 * <p>솔로 사용자도 즐겨찾기를 사용할 수 있다.
 * 커플 연결 전에는 owner_oid = 사용자 OID, 커플 연결 후에는 owner_oid = 커플 OID로 동작한다.
 * 모든 즐겨찾기 쓰기 연산은 소유권을 검증하여 IDOR 공격을 방지한다.
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class VendorService {

    private final VendorRepository vendorRepository;
    private final FavoriteRepository favoriteRepository;
    private final CoupleRepository coupleRepository;

    /**
     * 사용자의 소유자 OID를 반환한다.
     * 커플에 연결된 경우 커플 OID를, 솔로인 경우 사용자 OID를 반환한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 소유자 OID (커플 OID 또는 사용자 OID)
     */
    private String getOwnerOid(String userOid) {
        return coupleRepository.findByGroomOidOrBrideOid(userOid, userOid)
                .map(Couple::getOid)
                .orElse(userOid);
    }

    /**
     * 업체 목록을 카테고리·키워드로 검색한다.
     * 현재 사용자의 즐겨찾기 여부를 isFavorite 필드로 반영한다.
     *
     * <p>N+1 방지: 조회된 vendorOid 목록으로 즐겨찾기를 단일 IN 쿼리로 조회한다.
     *
     * @param userOid  현재 사용자 OID
     * @param category 카테고리 필터 (null이면 전체)
     * @param keyword  업체명·주소 검색어 (null이면 전체)
     * @return 업체 목록 (isFavorite 포함)
     */
    @Transactional(readOnly = true)
    public List<VendorResponse> getVendors(String userOid, String category, String keyword) {
        String ownerOid = getOwnerOid(userOid);
        List<Vendor> vendors = vendorRepository.search(category, keyword);

        if (vendors.isEmpty()) {
            return List.of();
        }

        // N+1 방지: vendorOid 목록으로 즐겨찾기를 한 번에 조회
        List<String> vendorOids = vendors.stream().map(Vendor::getOid).toList();
        Set<String> favoritedOids = favoriteRepository
                .findByOwnerOidAndVendorOidIn(ownerOid, vendorOids)
                .stream()
                .map(Favorite::getVendorOid)
                .collect(Collectors.toSet());

        return vendors.stream()
                .map(v -> VendorResponse.from(v, favoritedOids.contains(v.getOid())))
                .toList();
    }

    /**
     * 업체 상세 정보를 조회한다.
     * 현재 사용자의 즐겨찾기 OID를 함께 반환하여 클라이언트가 즐겨찾기 취소에 사용할 수 있도록 한다.
     *
     * @param userOid   현재 사용자 OID
     * @param vendorOid 조회할 업체 OID
     * @return 업체 상세 응답 (favoriteOid 포함)
     * @throws CustomException VENDOR_NOT_FOUND
     */
    @Transactional(readOnly = true)
    public VendorDetailResponse getVendor(String userOid, String vendorOid) {
        String ownerOid = getOwnerOid(userOid);
        Vendor vendor = vendorRepository.findById(vendorOid)
                .orElseThrow(() -> new CustomException(ErrorCode.VENDOR_NOT_FOUND));

        String favoriteOid = favoriteRepository
                .findByOwnerOidAndVendorOid(ownerOid, vendorOid)
                .map(Favorite::getOid)
                .orElse(null);

        return VendorDetailResponse.from(vendor, favoriteOid);
    }

    /**
     * 현재 사용자(또는 커플)의 즐겨찾기 목록을 최신 등록 순으로 조회한다.
     *
     * <p>N+1 방지: vendorOid 목록으로 업체를 단일 findAllById 호출로 조회한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 즐겨찾기 목록 (업체 정보 포함, 최신 등록 순)
     */
    @Transactional(readOnly = true)
    public List<FavoriteItemResponse> getFavorites(String userOid) {
        String ownerOid = getOwnerOid(userOid);
        List<Favorite> favorites = favoriteRepository.findByOwnerOidOrderByCreatedAtDesc(ownerOid);

        if (favorites.isEmpty()) {
            return List.of();
        }

        // N+1 방지: vendorOid 목록으로 업체를 한 번에 조회
        List<String> vendorOids = favorites.stream().map(Favorite::getVendorOid).toList();
        Map<String, Vendor> vendorMap = vendorRepository.findAllById(vendorOids)
                .stream()
                .collect(Collectors.toMap(Vendor::getOid, v -> v));

        return favorites.stream()
                .filter(f -> vendorMap.containsKey(f.getVendorOid()))
                .map(f -> FavoriteItemResponse.from(f, vendorMap.get(f.getVendorOid())))
                .toList();
    }

    /**
     * 업체를 즐겨찾기에 추가한다.
     *
     * @param userOid 현재 사용자 OID
     * @param request 즐겨찾기 추가 요청 (vendorOid 포함)
     * @return 생성된 즐겨찾기 응답 (favoriteOid, vendorOid)
     * @throws CustomException VENDOR_NOT_FOUND, FAVORITE_ALREADY_EXISTS
     */
    public AddFavoriteResponse addFavorite(String userOid, AddFavoriteRequest request) {
        String ownerOid = getOwnerOid(userOid);
        String vendorOid = request.getVendorOid();

        if (!vendorRepository.existsById(vendorOid)) {
            throw new CustomException(ErrorCode.VENDOR_NOT_FOUND);
        }
        if (favoriteRepository.existsByOwnerOidAndVendorOid(ownerOid, vendorOid)) {
            throw new CustomException(ErrorCode.FAVORITE_ALREADY_EXISTS);
        }

        Favorite favorite = Favorite.builder()
                .ownerOid(ownerOid)
                .vendorOid(vendorOid)
                .build();
        Favorite saved = favoriteRepository.save(favorite);
        log.info("즐겨찾기 추가 - favoriteOid: {}, ownerOid: {}, vendorOid: {}",
                saved.getOid(), ownerOid, vendorOid);

        return AddFavoriteResponse.builder()
                .favoriteOid(saved.getOid())
                .vendorOid(saved.getVendorOid())
                .build();
    }

    /**
     * 즐겨찾기를 삭제한다.
     * IDOR 방어를 위해 favoriteOid의 ownerOid가 현재 사용자와 일치하는지 검증한다.
     *
     * @param userOid     현재 사용자 OID
     * @param favoriteOid 삭제할 즐겨찾기 OID
     * @throws CustomException FAVORITE_NOT_FOUND, UNAUTHORIZED
     */
    public void removeFavorite(String userOid, String favoriteOid) {
        String ownerOid = getOwnerOid(userOid);
        Favorite favorite = favoriteRepository.findById(favoriteOid)
                .orElseThrow(() -> new CustomException(ErrorCode.FAVORITE_NOT_FOUND));

        // IDOR 방어: 즐겨찾기 소유자와 현재 사용자 일치 여부 확인
        if (!favorite.getOwnerOid().equals(ownerOid)) {
            throw new CustomException(ErrorCode.UNAUTHORIZED);
        }

        favoriteRepository.delete(favorite);
        log.info("즐겨찾기 삭제 - favoriteOid: {}, ownerOid: {}", favoriteOid, ownerOid);
    }
}
