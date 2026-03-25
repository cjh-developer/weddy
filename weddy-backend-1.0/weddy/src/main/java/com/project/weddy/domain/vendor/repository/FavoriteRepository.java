package com.project.weddy.domain.vendor.repository;

import com.project.weddy.domain.vendor.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 업체 즐겨찾기 데이터 접근 레이어.
 */
@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, String> {

    /**
     * 소유자의 즐겨찾기 목록을 등록일 내림차순으로 조회한다.
     *
     * @param ownerOid 소유자 OID (솔로=userOid, 커플=coupleOid)
     * @return 즐겨찾기 목록 (최신 등록 순)
     */
    List<Favorite> findByOwnerOidOrderByCreatedAtDesc(String ownerOid);

    /**
     * 소유자의 즐겨찾기 중 특정 업체 OID 목록에 해당하는 항목만 조회한다.
     * N+1 방지 목적의 IN 쿼리.
     *
     * @param ownerOid   소유자 OID
     * @param vendorOids 업체 OID 목록
     * @return 즐겨찾기 목록 (해당 업체 한정)
     */
    List<Favorite> findByOwnerOidAndVendorOidIn(String ownerOid, List<String> vendorOids);

    /**
     * 소유자 + 업체 OID로 특정 즐겨찾기를 조회한다.
     *
     * @param ownerOid  소유자 OID
     * @param vendorOid 업체 OID
     * @return 즐겨찾기 Optional
     */
    Optional<Favorite> findByOwnerOidAndVendorOid(String ownerOid, String vendorOid);

    /**
     * 소유자가 특정 업체를 이미 즐겨찾기했는지 확인한다.
     *
     * @param ownerOid  소유자 OID
     * @param vendorOid 업체 OID
     * @return 즐겨찾기 존재 여부
     */
    boolean existsByOwnerOidAndVendorOid(String ownerOid, String vendorOid);
}
