package com.project.weddy.domain.roadmap.repository;

import com.project.weddy.domain.roadmap.entity.HallTour;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 웨딩홀 투어 데이터 접근 레이어.
 */
@Repository
public interface HallTourRepository extends JpaRepository<HallTour, String> {

    /**
     * 특정 단계에 속하는 투어 목록을 생성일 오름차순으로 조회한다.
     *
     * @param stepOid 단계 OID
     * @return 투어 목록
     */
    List<HallTour> findByStepOidOrderByCreatedAtAsc(String stepOid);

    /**
     * 특정 단계에 속하는 투어를 모두 삭제한다.
     * 단계 삭제 시 연쇄 정리에 사용한다.
     *
     * @param stepOid 단계 OID
     */
    void deleteByStepOid(String stepOid);

    /**
     * 해당 투어가 지정된 단계에 속하는지 확인한다.
     *
     * @param oid     투어 OID
     * @param stepOid 단계 OID
     * @return 존재하면 true
     */
    boolean existsByOidAndStepOid(String oid, String stepOid);
}
