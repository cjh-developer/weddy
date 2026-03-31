package com.project.weddy.domain.guest.repository;

import com.project.weddy.domain.guest.entity.GuestGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 하객 그룹 데이터 접근 레이어.
 */
@Repository
public interface GuestGroupRepository extends JpaRepository<GuestGroup, String> {

    /**
     * 소유자의 하객 그룹 목록을 sort_order 오름차순으로 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @return 그룹 목록 (sort_order 순)
     */
    List<GuestGroup> findByOwnerOidOrderBySortOrderAsc(String ownerOid);

    /**
     * 소유자의 하객 그룹 수를 반환한다.
     * 생성 한도(최대 20개) 검증에 사용된다.
     *
     * @param ownerOid 소유자 OID
     * @return 그룹 수
     */
    int countByOwnerOid(String ownerOid);
}
