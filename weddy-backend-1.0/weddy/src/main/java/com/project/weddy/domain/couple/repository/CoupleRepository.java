package com.project.weddy.domain.couple.repository;

import com.project.weddy.domain.couple.entity.Couple;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * 커플 데이터 접근 레이어.
 */
@Repository
public interface CoupleRepository extends JpaRepository<Couple, String> {

    /**
     * 신랑 OID 또는 신부 OID로 커플을 조회한다.
     * 한 사용자는 하나의 커플에만 속할 수 있으므로 Optional을 반환한다.
     *
     * @param groomOid 신랑 사용자 OID
     * @param brideOid 신부 사용자 OID
     * @return 커플 Optional
     */
    Optional<Couple> findByGroomOidOrBrideOid(String groomOid, String brideOid);

    /**
     * 해당 사용자가 이미 커플에 연결되어 있는지 확인한다.
     *
     * @param groomOid 신랑 사용자 OID
     * @param brideOid 신부 사용자 OID
     * @return 연결된 커플이 존재하면 true
     */
    boolean existsByGroomOidOrBrideOid(String groomOid, String brideOid);
}
