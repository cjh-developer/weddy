package com.project.weddy.domain.roadmap.repository;

import com.project.weddy.domain.roadmap.entity.TravelStop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 항공권 경유지 데이터 접근 레이어.
 */
@Repository
public interface TravelStopRepository extends JpaRepository<TravelStop, String> {

    /**
     * 특정 단계에 속하는 경유지 목록을 순서(stop_order) 오름차순으로 조회한다.
     *
     * @param stepOid 단계 OID
     * @return 경유지 목록
     */
    List<TravelStop> findByStepOidOrderByStopOrderAsc(String stepOid);

    /**
     * 특정 단계에 속하는 경유지를 모두 삭제한다.
     * 단계 삭제 시 연쇄 정리에 사용한다.
     *
     * @param stepOid 단계 OID
     */
    void deleteByStepOid(String stepOid);

    /**
     * 특정 단계에 속하는 경유지 수를 반환한다.
     * 다음 stop_order 계산에 사용한다.
     *
     * @param stepOid 단계 OID
     * @return 경유지 수
     */
    long countByStepOid(String stepOid);
}
