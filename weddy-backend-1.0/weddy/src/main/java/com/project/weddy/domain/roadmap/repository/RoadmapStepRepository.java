package com.project.weddy.domain.roadmap.repository;

import com.project.weddy.domain.roadmap.entity.RoadmapStep;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * 웨딩 로드맵 단계 데이터 접근 레이어.
 */
@Repository
public interface RoadmapStepRepository extends JpaRepository<RoadmapStep, String> {

    /**
     * 소유자의 전체 단계를 sort_order 오름차순으로 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @return 단계 목록
     */
    List<RoadmapStep> findByOwnerOidOrderBySortOrderAsc(String ownerOid);

    /**
     * 해당 단계가 지정된 소유자에 속하는지 확인한다.
     *
     * @param oid      단계 OID
     * @param ownerOid 소유자 OID
     * @return 존재하면 true
     */
    boolean existsByOidAndOwnerOid(String oid, String ownerOid);

    /**
     * 소유자의 단계 수를 반환한다.
     *
     * @param ownerOid 소유자 OID
     * @return 단계 수
     */
    long countByOwnerOid(String ownerOid);

    /**
     * 소유자 OID와 단계 OID로 단건 조회한다.
     *
     * @param oid      단계 OID
     * @param ownerOid 소유자 OID
     * @return 단계 Optional
     */
    Optional<RoadmapStep> findByOidAndOwnerOid(String oid, String ownerOid);
}
