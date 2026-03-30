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
     * 소유자의 전체 단계 수(기본 + 직접 로드맵 포함)를 반환한다.
     * initDefaultRoadmap()의 중복 생성 방지에 사용한다.
     *
     * @param ownerOid 소유자 OID
     * @return 전체 단계 수
     */
    long countByOwnerOid(String ownerOid);

    /**
     * 소유자의 기본 로드맵 단계 수(group_oid IS NULL)를 반환한다.
     * createStep() 의 20개 제한 검증에 사용한다.
     *
     * @param ownerOid 소유자 OID
     * @return 기본 로드맵 단계 수
     */
    long countByOwnerOidAndGroupOidIsNull(String ownerOid);

    /**
     * 특정 직접 로드맵 그룹 내 단계 수를 반환한다.
     * createStep() 에서 직접 로드맵 단계의 sort_order 계산에 사용한다.
     *
     * @param ownerOid 소유자 OID
     * @param groupOid 직접 로드맵 OID
     * @return 해당 그룹 내 단계 수
     */
    long countByOwnerOidAndGroupOid(String ownerOid, String groupOid);

    /**
     * 소유자 OID와 단계 OID로 단건 조회한다.
     *
     * @param oid      단계 OID
     * @param ownerOid 소유자 OID
     * @return 단계 Optional
     */
    Optional<RoadmapStep> findByOidAndOwnerOid(String oid, String ownerOid);

    /**
     * OID 목록과 소유자 OID로 복수 단계를 조회한다.
     * 순서 변경 시 소유권 일괄 검증에 사용한다.
     *
     * @param oids     단계 OID 목록
     * @param ownerOid 소유자 OID
     * @return 단계 목록
     */
    List<RoadmapStep> findAllByOidInAndOwnerOid(List<String> oids, String ownerOid);

    /**
     * 기본 로드맵 단계 목록을 sort_order 오름차순으로 조회한다.
     * group_oid가 NULL인 단계만 반환한다.
     *
     * @param ownerOid 소유자 OID
     * @return 기본 로드맵 단계 목록
     */
    List<RoadmapStep> findByOwnerOidAndGroupOidIsNullOrderBySortOrderAsc(String ownerOid);

    /**
     * 특정 직접 로드맵 그룹에 속한 단계 목록을 sort_order 오름차순으로 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @param groupOid 직접 로드맵 OID
     * @return 그룹 소속 단계 목록
     */
    List<RoadmapStep> findByOwnerOidAndGroupOidOrderBySortOrderAsc(String ownerOid, String groupOid);
}
