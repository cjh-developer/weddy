package com.project.weddy.domain.roadmap.repository;

import com.project.weddy.domain.roadmap.entity.CustomRoadmap;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 직접 로드맵 데이터 접근 레이어.
 */
@Repository
public interface CustomRoadmapRepository extends JpaRepository<CustomRoadmap, String> {

    /**
     * 소유자의 직접 로드맵 목록을 sort_order 오름차순으로 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @return 직접 로드맵 목록
     */
    List<CustomRoadmap> findByOwnerOidOrderBySortOrderAsc(String ownerOid);

    /**
     * 소유자의 직접 로드맵 수를 반환한다.
     * 10개 제한 검증에 사용한다.
     *
     * @param ownerOid 소유자 OID
     * @return 직접 로드맵 수
     */
    long countByOwnerOid(String ownerOid);

    /**
     * OID와 소유자 OID로 직접 로드맵을 조회한다.
     * 소유권 검증을 겸한 단건 조회에 사용한다.
     *
     * @param oid      직접 로드맵 OID
     * @param ownerOid 소유자 OID
     * @return 직접 로드맵 Optional
     */
    Optional<CustomRoadmap> findByOidAndOwnerOid(String oid, String ownerOid);
}
