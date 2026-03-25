package com.project.weddy.domain.schedule.service;

import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.domain.couple.entity.Couple;
import com.project.weddy.domain.couple.repository.CoupleRepository;
import com.project.weddy.domain.schedule.dto.request.CreateScheduleRequest;
import com.project.weddy.domain.schedule.dto.request.UpdateScheduleRequest;
import com.project.weddy.domain.schedule.dto.response.ScheduleResponse;
import com.project.weddy.domain.schedule.entity.Schedule;
import com.project.weddy.domain.schedule.repository.ScheduleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;

/**
 * 일정 CRUD 서비스.
 *
 * <p>솔로 사용자도 일정을 사용할 수 있다.
 * 커플 연결 전에는 owner_oid = 사용자 OID, 커플 연결 후에는 owner_oid = 커플 OID로 동작한다.
 * 모든 쓰기 연산은 소유권을 검증하여 IDOR 공격을 방지한다.
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class ScheduleService {

    private final ScheduleRepository scheduleRepository;
    private final CoupleRepository coupleRepository;

    /**
     * 사용자의 소유자 OID를 반환한다.
     * 커플에 연결된 경우 커플 OID를, 솔로인 경우 사용자 OID를 반환한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 소유자 OID (커플 OID 또는 사용자 OID)
     */
    private String getOwnerOid(String userOid) {
        return coupleRepository.findByGroomOidOrBrideOid(userOid, userOid)
                .map(Couple::getOid)
                .orElse(userOid);
    }

    /**
     * 소유자의 일정 목록을 조회한다.
     * year와 month가 모두 지정된 경우 해당 월의 일정만 반환하고, 그렇지 않으면 전체를 반환한다.
     *
     * @param userOid 현재 사용자 OID
     * @param year    조회 연도 (null이면 전체 조회)
     * @param month   조회 월 (null이면 전체 조회)
     * @return 일정 목록
     */
    @Transactional(readOnly = true)
    public List<ScheduleResponse> getSchedules(String userOid, Integer year, Integer month) {
        String ownerOid = getOwnerOid(userOid);
        List<Schedule> schedules;

        if (year != null && month != null) {
            YearMonth yearMonth = YearMonth.of(year, month);
            LocalDateTime start = yearMonth.atDay(1).atStartOfDay();
            LocalDateTime end = yearMonth.atEndOfMonth().atTime(23, 59, 59);
            schedules = scheduleRepository
                    .findByOwnerOidAndStartAtBetweenOrderByStartAtAsc(ownerOid, start, end);
        } else {
            schedules = scheduleRepository.findByOwnerOidOrderByStartAtAsc(ownerOid);
        }

        return schedules.stream().map(ScheduleResponse::from).toList();
    }

    /**
     * 일정을 생성한다.
     *
     * @param userOid 현재 사용자 OID
     * @param req     일정 생성 요청
     * @return 생성된 일정 응답
     */
    public ScheduleResponse createSchedule(String userOid, CreateScheduleRequest req) {
        String ownerOid = getOwnerOid(userOid);
        Schedule schedule = Schedule.builder()
                .ownerOid(ownerOid)
                .title(req.getTitle())
                .description(req.getDescription())
                .category(req.getCategory())
                .isAllDay(req.isAllDay())
                .startAt(req.getStartAt())
                .endAt(req.getEndAt())
                .location(req.getLocation())
                .alertBefore(req.getAlertBefore())
                .sourceType("MANUAL")
                .build();
        Schedule saved = scheduleRepository.save(schedule);
        log.info("일정 생성 - scheduleOid: {}, ownerOid: {}", saved.getOid(), ownerOid);
        return ScheduleResponse.from(saved);
    }

    /**
     * 단건 일정을 조회한다.
     *
     * @param userOid     현재 사용자 OID
     * @param scheduleOid 일정 OID
     * @return 일정 응답
     * @throws CustomException SCHEDULE_NOT_FOUND
     */
    @Transactional(readOnly = true)
    public ScheduleResponse getSchedule(String userOid, String scheduleOid) {
        String ownerOid = getOwnerOid(userOid);
        Schedule schedule = scheduleRepository.findByOidAndOwnerOid(scheduleOid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.SCHEDULE_NOT_FOUND));
        return ScheduleResponse.from(schedule);
    }

    /**
     * 일정을 부분 수정한다.
     * null인 필드는 기존 값을 유지한다.
     *
     * @param userOid     현재 사용자 OID
     * @param scheduleOid 수정할 일정 OID
     * @param req         수정 요청
     * @return 수정된 일정 응답
     * @throws CustomException SCHEDULE_NOT_FOUND
     */
    public ScheduleResponse updateSchedule(String userOid, String scheduleOid,
                                           UpdateScheduleRequest req) {
        String ownerOid = getOwnerOid(userOid);
        Schedule schedule = scheduleRepository.findById(scheduleOid)
                .orElseThrow(() -> new CustomException(ErrorCode.SCHEDULE_NOT_FOUND));
        // 인메모리 소유권 검증 (DB 중복 조회 방지)
        if (!schedule.getOwnerOid().equals(ownerOid)) {
            throw new CustomException(ErrorCode.SCHEDULE_NOT_FOUND);
        }
        schedule.update(req.getTitle(), req.getDescription(), req.getCategory(),
                req.getIsAllDay(), req.getStartAt(), req.getEndAt(),
                req.getLocation(), req.getAlertBefore());
        log.info("일정 수정 - scheduleOid: {}, ownerOid: {}", scheduleOid, ownerOid);
        return ScheduleResponse.from(schedule);
    }

    /**
     * 일정을 삭제한다.
     *
     * @param userOid     현재 사용자 OID
     * @param scheduleOid 삭제할 일정 OID
     * @throws CustomException SCHEDULE_NOT_FOUND
     */
    public void deleteSchedule(String userOid, String scheduleOid) {
        String ownerOid = getOwnerOid(userOid);
        if (!scheduleRepository.existsByOidAndOwnerOid(scheduleOid, ownerOid)) {
            throw new CustomException(ErrorCode.SCHEDULE_NOT_FOUND);
        }
        scheduleRepository.deleteById(scheduleOid);
        log.info("일정 삭제 - scheduleOid: {}, ownerOid: {}", scheduleOid, ownerOid);
    }

    /**
     * 내부 자동 생성용 일정 생성 메서드.
     * 웨딩홀 투어 등록 시 RoadmapService에서 호출한다.
     * 이미 ownerOid가 결정된 상태이므로 getOwnerOid() 재호출을 하지 않는다.
     *
     * @param ownerOid   소유자 OID (커플 OID 또는 사용자 OID)
     * @param title      일정 제목
     * @param category   카테고리
     * @param startAt    시작 일시
     * @param sourceType 생성 출처 타입 (HALL_TOUR 등)
     * @param sourceOid  생성 출처 OID (투어 OID 등)
     * @return 생성된 일정 엔티티 OID
     */
    public String createScheduleInternal(String ownerOid, String title, String category,
                                         LocalDateTime startAt, String sourceType, String sourceOid) {
        Schedule schedule = Schedule.builder()
                .ownerOid(ownerOid)
                .title(title)
                .category(category)
                .isAllDay(true)
                .startAt(startAt)
                .sourceType(sourceType)
                .sourceOid(sourceOid)
                .build();
        Schedule saved = scheduleRepository.save(schedule);
        log.info("일정 자동 생성 - scheduleOid: {}, sourceType: {}, sourceOid: {}",
                saved.getOid(), sourceType, sourceOid);
        return saved.getOid();
    }
}
