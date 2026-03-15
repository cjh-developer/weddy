package com.project.weddy.domain.checklist.repository;

import com.project.weddy.domain.checklist.entity.Checklist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 체크리스트 데이터 접근 레이어.
 */
@Repository
public interface ChecklistRepository extends JpaRepository<Checklist, String> {

    /**
     * 커플 OID로 체크리스트 목록을 생성일 오름차순으로 조회한다.
     *
     * @param coupleOid 커플 OID
     * @return 체크리스트 목록
     */
    List<Checklist> findByCoupleOidOrderByCreatedAtAsc(String coupleOid);

    /**
     * 해당 OID의 체크리스트가 지정된 커플에 속하는지 확인한다.
     * 소유권 검증에 사용하여 IDOR 공격을 방지한다.
     *
     * @param oid       체크리스트 OID
     * @param coupleOid 커플 OID
     * @return 존재하면 true
     */
    boolean existsByOidAndCoupleOid(String oid, String coupleOid);
}
