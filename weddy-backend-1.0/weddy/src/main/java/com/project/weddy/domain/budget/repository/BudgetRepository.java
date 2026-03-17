package com.project.weddy.domain.budget.repository;

import com.project.weddy.domain.budget.entity.Budget;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 예산 카테고리 데이터 접근 레이어.
 */
@Repository
public interface BudgetRepository extends JpaRepository<Budget, String> {

    /**
     * 소유자 OID로 예산 목록을 생성일 오름차순으로 조회한다.
     *
     * @param ownerOid 소유자 OID (솔로: 사용자 OID, 커플: 커플 OID)
     * @return 예산 목록
     */
    List<Budget> findByOwnerOidOrderByCreatedAtAsc(String ownerOid);

    /**
     * 해당 OID의 예산이 지정된 소유자에 속하는지 확인한다.
     * 소유권 검증에 사용하여 IDOR 공격을 방지한다.
     *
     * @param oid      예산 OID
     * @param ownerOid 소유자 OID
     * @return 존재하면 true
     */
    boolean existsByOidAndOwnerOid(String oid, String ownerOid);

    /**
     * 소유자 OID에 속한 예산 카테고리 수를 반환한다.
     * 카테고리 생성 횟수 제한(최대 20개) 검증에 사용한다.
     *
     * @param ownerOid 소유자 OID
     * @return 예산 카테고리 수
     */
    long countByOwnerOid(String ownerOid);
}
