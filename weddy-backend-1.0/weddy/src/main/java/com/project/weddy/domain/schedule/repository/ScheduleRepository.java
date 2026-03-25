package com.project.weddy.domain.schedule.repository;

import com.project.weddy.domain.schedule.entity.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 일정 데이터 접근 레이어.
 */
@Repository
public interface ScheduleRepository extends JpaRepository<Schedule, String> {

    /**
     * 소유자의 특정 기간 내 일정을 시작 일시 오름차순으로 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @param start    기간 시작 일시 (포함)
     * @param end      기간 종료 일시 (포함)
     * @return 기간 내 일정 목록
     */
    List<Schedule> findByOwnerOidAndStartAtBetweenOrderByStartAtAsc(
            String ownerOid, LocalDateTime start, LocalDateTime end);

    /**
     * 소유자의 전체 일정을 시작 일시 오름차순으로 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @return 전체 일정 목록
     */
    List<Schedule> findByOwnerOidOrderByStartAtAsc(String ownerOid);

    /**
     * 특정 출처 OID로 생성된 일정을 모두 삭제한다.
     * 웨딩홀 투어 삭제 시 연관 일정 정리에 사용한다.
     *
     * @param sourceOid 출처 OID
     */
    void deleteBySourceOid(String sourceOid);

    /**
     * 해당 일정이 지정된 소유자에 속하는지 확인한다.
     *
     * @param oid      일정 OID
     * @param ownerOid 소유자 OID
     * @return 존재하면 true
     */
    boolean existsByOidAndOwnerOid(String oid, String ownerOid);

    /**
     * OID와 소유자 OID로 일정을 단일 쿼리로 조회한다.
     * TOCTOU 방지를 위해 existsBy + findById 이중 호출 대신 사용한다.
     *
     * @param oid      일정 OID
     * @param ownerOid 소유자 OID
     * @return 일정 (없으면 empty)
     */
    Optional<Schedule> findByOidAndOwnerOid(String oid, String ownerOid);
}
