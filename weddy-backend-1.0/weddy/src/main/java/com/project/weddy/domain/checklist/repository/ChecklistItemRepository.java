package com.project.weddy.domain.checklist.repository;

import com.project.weddy.domain.checklist.entity.ChecklistItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 체크리스트 항목 데이터 접근 레이어.
 */
@Repository
public interface ChecklistItemRepository extends JpaRepository<ChecklistItem, String> {

    /**
     * 체크리스트 OID로 항목 목록을 정렬 순서→생성일 오름차순으로 조회한다.
     *
     * @param checklistOid 체크리스트 OID
     * @return 항목 목록
     */
    List<ChecklistItem> findByChecklistOidOrderBySortOrderAscCreatedAtAsc(String checklistOid);

    /**
     * 체크리스트에 속한 모든 항목을 삭제한다.
     * 체크리스트 삭제 시 자식 항목을 먼저 삭제하는 용도로 사용한다.
     *
     * @param checklistOid 체크리스트 OID
     */
    void deleteByChecklistOid(String checklistOid);

    /**
     * 해당 OID의 항목이 지정된 체크리스트에 속하는지 확인한다.
     * 소유권 검증에 사용하여 IDOR 공격을 방지한다.
     *
     * @param oid          항목 OID
     * @param checklistOid 체크리스트 OID
     * @return 존재하면 true
     */
    boolean existsByOidAndChecklistOid(String oid, String checklistOid);

    /**
     * 커플의 미완료 항목을 목표일 오름차순(null은 마지막)으로 조회한다.
     * 홈 화면 프리뷰용으로 사용된다.
     *
     * <p>JPQL에서 MySQL 'LIMIT :limit' 은 직접 지원되지 않으므로
     * Pageable 대신 @Query + LIMIT 정수를 사용한다.
     * Spring Data JPA 3.x 에서 JPQL LIMIT 절이 지원된다.
     *
     * @param coupleOid 커플 OID
     * @param limit     최대 조회 개수
     * @return 미완료 항목 목록
     */
    @Query("""
            SELECT ci FROM ChecklistItem ci
            JOIN Checklist c ON ci.checklistOid = c.oid
            WHERE c.coupleOid = :coupleOid AND ci.isDone = false
            ORDER BY ci.dueDate ASC NULLS LAST, ci.createdAt ASC
            LIMIT :limit
            """)
    List<ChecklistItem> findRecentUndoneItems(
            @Param("coupleOid") String coupleOid,
            @Param("limit") int limit
    );
}
