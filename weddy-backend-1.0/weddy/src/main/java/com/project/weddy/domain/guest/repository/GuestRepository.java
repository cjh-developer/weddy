package com.project.weddy.domain.guest.repository;

import com.project.weddy.domain.guest.entity.Guest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 하객 데이터 접근 레이어.
 */
@Repository
public interface GuestRepository extends JpaRepository<Guest, String> {

    /**
     * 소유자의 전체 하객 목록을 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @return 하객 목록
     */
    List<Guest> findByOwnerOid(String ownerOid);

    /**
     * 소유자 + 그룹 OID로 하객 목록을 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @param groupOid 그룹 OID
     * @return 해당 그룹의 하객 목록
     */
    List<Guest> findByOwnerOidAndGroupOid(String ownerOid, String groupOid);

    /**
     * 소유자의 하객 수를 반환한다.
     * 생성 한도(최대 500명) 검증에 사용된다.
     *
     * @param ownerOid 소유자 OID
     * @return 하객 수
     */
    int countByOwnerOid(String ownerOid);

    /**
     * 특정 그룹에 속한 하객 수를 반환한다.
     * GuestGroupResponse.guestCount 집계에 사용된다.
     *
     * @param groupOid 그룹 OID
     * @return 그룹에 속한 하객 수
     */
    int countByGroupOid(String groupOid);

    /**
     * 그룹 OID에 해당하는 모든 하객의 group_oid를 NULL로 초기화한다.
     * 그룹 삭제 시 소속 하객을 미분류 상태로 전환하는 데 사용된다.
     *
     * <p>내부 전용 메서드. 외부 API로 직접 노출되지 않는다.
     *
     * @param groupOid 삭제될 그룹 OID
     */
    @Modifying
    @Query("UPDATE Guest g SET g.groupOid = NULL WHERE g.groupOid = :groupOid")
    void clearGroupOid(@Param("groupOid") String groupOid);
}
