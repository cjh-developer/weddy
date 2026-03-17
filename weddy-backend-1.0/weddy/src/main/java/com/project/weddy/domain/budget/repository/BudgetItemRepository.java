package com.project.weddy.domain.budget.repository;

import com.project.weddy.domain.budget.entity.BudgetItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 예산 항목 데이터 접근 레이어.
 */
@Repository
public interface BudgetItemRepository extends JpaRepository<BudgetItem, String> {

    /**
     * 예산 OID로 항목 목록을 생성일 오름차순으로 조회한다.
     *
     * @param budgetOid 예산 OID
     * @return 항목 목록
     */
    List<BudgetItem> findByBudgetOidOrderByCreatedAtAsc(String budgetOid);

    /**
     * 예산 OID 목록에 속한 모든 항목을 한 번의 쿼리로 조회한다.
     * getSummary()에서 N+1 쿼리를 방지하기 위해 사용한다.
     *
     * @param budgetOids 예산 OID 목록
     * @return 해당 예산들에 속한 항목 전체
     */
    @Query("SELECT i FROM BudgetItem i WHERE i.budgetOid IN :budgetOids")
    List<BudgetItem> findAllByBudgetOidIn(@Param("budgetOids") List<String> budgetOids);

    /**
     * 예산에 속한 모든 항목을 삭제한다.
     * 예산 카테고리 삭제 시 자식 항목을 먼저 삭제하는 용도로 사용한다.
     *
     * @param budgetOid 예산 OID
     */
    void deleteByBudgetOid(String budgetOid);

    /**
     * 해당 OID의 항목이 지정된 예산에 속하는지 확인한다.
     * 소유권 검증에 사용하여 IDOR 공격을 방지한다.
     *
     * @param oid       항목 OID
     * @param budgetOid 예산 OID
     * @return 존재하면 true
     */
    boolean existsByOidAndBudgetOid(String oid, String budgetOid);
}
