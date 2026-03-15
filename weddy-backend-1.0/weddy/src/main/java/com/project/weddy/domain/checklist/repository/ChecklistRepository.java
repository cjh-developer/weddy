package com.project.weddy.domain.checklist.repository;

import com.project.weddy.domain.checklist.entity.Checklist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 체크리스트 데이터 접근 레이어.
 */
@Repository
public interface ChecklistRepository extends JpaRepository<Checklist, String> {

    /**
     * 소유자 OID로 체크리스트 목록을 생성일 오름차순으로 조회한다.
     * 솔로 상태에서는 사용자 OID, 커플 연결 후에는 커플 OID로 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @return 체크리스트 목록
     */
    List<Checklist> findByOwnerOidOrderByCreatedAtAsc(String ownerOid);

    /**
     * 해당 OID의 체크리스트가 지정된 소유자에 속하는지 확인한다.
     * 소유권 검증에 사용하여 IDOR 공격을 방지한다.
     *
     * @param oid      체크리스트 OID
     * @param ownerOid 소유자 OID
     * @return 존재하면 true
     */
    boolean existsByOidAndOwnerOid(String oid, String ownerOid);

    /**
     * 솔로 체크리스트를 커플 소유로 일괄 마이그레이션한다.
     * 커플 연결 시 두 파트너 각각에 대해 호출된다.
     *
     * @param userOid   기존 소유자(사용자 OID)
     * @param coupleOid 새 소유자(커플 OID)
     */
    @Modifying
    @Query("UPDATE Checklist c SET c.ownerOid = :coupleOid WHERE c.ownerOid = :userOid")
    void migrateOwnerOid(@Param("userOid") String userOid, @Param("coupleOid") String coupleOid);
}
