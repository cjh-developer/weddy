package com.project.weddy.domain.roadmap.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.domain.budget.service.BudgetService;
import com.project.weddy.domain.couple.entity.Couple;
import com.project.weddy.domain.couple.repository.CoupleRepository;
import com.project.weddy.domain.roadmap.dto.request.AddTravelStopRequest;
import com.project.weddy.domain.roadmap.dto.request.CreateHallTourRequest;
import com.project.weddy.domain.roadmap.dto.request.CreateRoadmapStepRequest;
import com.project.weddy.domain.roadmap.dto.request.UpdateRoadmapStepRequest;
import com.project.weddy.domain.roadmap.dto.response.HallTourResponse;
import com.project.weddy.domain.roadmap.dto.response.RoadmapStepResponse;
import com.project.weddy.domain.roadmap.dto.response.TravelStopResponse;
import com.project.weddy.domain.roadmap.entity.HallTour;
import com.project.weddy.domain.roadmap.entity.RoadmapStep;
import com.project.weddy.domain.roadmap.entity.TravelStop;
import com.project.weddy.domain.roadmap.repository.HallTourRepository;
import com.project.weddy.domain.roadmap.repository.RoadmapStepRepository;
import com.project.weddy.domain.roadmap.repository.TravelStopRepository;
import com.project.weddy.domain.schedule.repository.ScheduleRepository;
import com.project.weddy.domain.schedule.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 웨딩 관리(로드맵) 서비스.
 *
 * <p>솔로/커플 공통으로 사용 가능하다.
 * BUDGET 단계 생성 시 details JSON에서 totalBudget을 파싱하여 예산 설정을 자동 동기화한다.
 * HALL 단계의 투어 등록 시 tourDate가 있으면 일정(Schedule)을 자동 생성한다.
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class RoadmapService {

    private final RoadmapStepRepository roadmapStepRepository;
    private final HallTourRepository hallTourRepository;
    private final TravelStopRepository travelStopRepository;
    private final CoupleRepository coupleRepository;
    private final ScheduleService scheduleService;
    private final ScheduleRepository scheduleRepository;
    private final BudgetService budgetService;
    private final ObjectMapper objectMapper;

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
     * 소유자의 웨딩 관리 단계 전체 목록을 sortOrder 오름차순으로 조회한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 단계 목록
     */
    @Transactional(readOnly = true)
    public List<RoadmapStepResponse> getSteps(String userOid) {
        String ownerOid = getOwnerOid(userOid);
        return roadmapStepRepository.findByOwnerOidOrderBySortOrderAsc(ownerOid)
                .stream().map(RoadmapStepResponse::from).toList();
    }

    /**
     * 웨딩 관리 단계를 생성한다.
     * 최대 20개 제한이 있으며, BUDGET 단계 생성 시 예산 설정을 자동 동기화한다.
     *
     * @param userOid 현재 사용자 OID
     * @param req     단계 생성 요청
     * @return 생성된 단계 응답
     * @throws CustomException ROADMAP_STEP_LIMIT_EXCEEDED (20개 초과)
     */
    public RoadmapStepResponse createStep(String userOid, CreateRoadmapStepRequest req) {
        String ownerOid = getOwnerOid(userOid);

        long currentCount = roadmapStepRepository.countByOwnerOid(ownerOid);
        if (currentCount >= 20) {
            throw new CustomException(ErrorCode.ROADMAP_STEP_LIMIT_EXCEEDED);
        }

        // 다음 sort_order: 현재 개수 + 1 (0-indexed 방지)
        int nextSortOrder = (int) currentCount + 1;

        RoadmapStep step = RoadmapStep.builder()
                .ownerOid(ownerOid)
                .stepType(req.getStepType())
                .title(req.getTitle())
                .isDone(false)
                .dueDate(req.getDueDate())
                .hasDueDate(req.isHasDueDate())
                .sortOrder(nextSortOrder)
                .details(req.getDetails())
                .build();

        RoadmapStep saved = roadmapStepRepository.save(step);
        log.info("로드맵 단계 생성 - oid: {}, stepType: {}, ownerOid: {}",
                saved.getOid(), saved.getStepType(), ownerOid);

        // BUDGET 단계 생성 시 details에서 totalBudget 파싱하여 예산 설정 동기화
        if ("BUDGET".equals(req.getStepType()) && req.getDetails() != null) {
            syncBudgetSettings(ownerOid, req.getDetails());
        }

        // dueDate가 있는 경우 일정 자동 등록
        if (req.isHasDueDate() && req.getDueDate() != null) {
            syncRoadmapSchedule(ownerOid, saved);
        }

        return RoadmapStepResponse.from(saved);
    }

    /**
     * 단건 웨딩 관리 단계를 조회한다.
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 단계 OID
     * @return 단계 응답
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    @Transactional(readOnly = true)
    public RoadmapStepResponse getStep(String userOid, String stepOid) {
        String ownerOid = getOwnerOid(userOid);
        RoadmapStep step = roadmapStepRepository.findByOidAndOwnerOid(stepOid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.ROADMAP_STEP_NOT_FOUND));
        return RoadmapStepResponse.from(step);
    }

    /**
     * 웨딩 관리 단계를 부분 수정한다.
     * null인 필드는 기존 값을 유지한다.
     * BUDGET 단계의 details가 변경되면 예산 설정을 자동 동기화한다.
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 수정할 단계 OID
     * @param req     수정 요청
     * @return 수정된 단계 응답
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    public RoadmapStepResponse updateStep(String userOid, String stepOid,
                                          UpdateRoadmapStepRequest req) {
        String ownerOid = getOwnerOid(userOid);
        RoadmapStep step = roadmapStepRepository.findByOidAndOwnerOid(stepOid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.ROADMAP_STEP_NOT_FOUND));

        step.update(req.getTitle(), req.getIsDone(), req.getDueDate(),
                req.getHasDueDate(), req.getDetails(), req.isClearDueDate());
        log.info("로드맵 단계 수정 - oid: {}, ownerOid: {}", stepOid, ownerOid);

        // BUDGET 단계의 details가 변경된 경우 예산 설정 동기화
        if ("BUDGET".equals(step.getStepType()) && req.getDetails() != null) {
            syncBudgetSettings(ownerOid, req.getDetails());
        }

        // 일정 관련 필드(dueDate/hasDueDate)가 변경된 경우에만 일정 동기화
        // title 단독 변경은 일정 OID를 유지하기 위해 동기화 제외
        boolean scheduleRelated = req.getDueDate() != null
                || req.getHasDueDate() != null
                || req.isClearDueDate();
        if (scheduleRelated) {
            syncRoadmapSchedule(ownerOid, step);
        }

        return RoadmapStepResponse.from(step);
    }

    /**
     * 단계 완료 여부를 토글한다.
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 토글할 단계 OID
     * @return 토글된 단계 응답
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    public RoadmapStepResponse toggleDone(String userOid, String stepOid) {
        String ownerOid = getOwnerOid(userOid);
        RoadmapStep step = roadmapStepRepository.findByOidAndOwnerOid(stepOid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.ROADMAP_STEP_NOT_FOUND));
        step.toggleDone();
        log.info("로드맵 단계 토글 - oid: {}, isDone: {}", stepOid, step.isDone());
        return RoadmapStepResponse.from(step);
    }

    /**
     * 웨딩 관리 단계와 연관 데이터를 모두 삭제한다.
     * 삭제 순서: 투어 → 경유지 → 연관 일정 → 단계
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 삭제할 단계 OID
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    public void deleteStep(String userOid, String stepOid) {
        String ownerOid = getOwnerOid(userOid);
        if (!roadmapStepRepository.existsByOidAndOwnerOid(stepOid, ownerOid)) {
            throw new CustomException(ErrorCode.ROADMAP_STEP_NOT_FOUND);
        }
        hallTourRepository.deleteByStepOid(stepOid);
        travelStopRepository.deleteByStepOid(stepOid);
        scheduleRepository.deleteBySourceOid(stepOid);
        roadmapStepRepository.deleteById(stepOid);
        log.info("로드맵 단계 삭제 - oid: {}, ownerOid: {}", stepOid, ownerOid);
    }

    // =========================================================
    // 웨딩홀 투어
    // =========================================================

    /**
     * 특정 단계의 웨딩홀 투어 목록을 조회한다.
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 단계 OID
     * @return 투어 목록
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    @Transactional(readOnly = true)
    public List<HallTourResponse> getHallTours(String userOid, String stepOid) {
        String ownerOid = getOwnerOid(userOid);
        validateStepOwnership(stepOid, ownerOid);
        return hallTourRepository.findByStepOidOrderByCreatedAtAsc(stepOid)
                .stream().map(HallTourResponse::from).toList();
    }

    /**
     * 웨딩홀 투어를 추가한다.
     * tourDate가 있고 scheduleTitle이 지정된 경우 일정을 자동 등록한다.
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 단계 OID
     * @param req     투어 추가 요청
     * @return 추가된 투어 응답
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    public HallTourResponse addHallTour(String userOid, String stepOid,
                                        CreateHallTourRequest req) {
        String ownerOid = getOwnerOid(userOid);
        validateStepOwnership(stepOid, ownerOid);

        HallTour tour = HallTour.builder()
                .stepOid(stepOid)
                .hallName(req.getHallName())
                .tourDate(req.getTourDate())
                .location(req.getLocation())
                .rentalFee(req.getRentalFee())
                .mealPrice(req.getMealPrice())
                .minGuests(req.getMinGuests())
                .memo(req.getMemo())
                .build();
        HallTour saved = hallTourRepository.save(tour);
        log.info("웨딩홀 투어 추가 - tourOid: {}, stepOid: {}", saved.getOid(), stepOid);

        // tourDate가 있고 scheduleTitle이 지정된 경우 일정 자동 등록
        if (req.getTourDate() != null && req.getScheduleTitle() != null
                && !req.getScheduleTitle().isBlank()) {
            LocalDateTime tourDateTime = req.getTourDate().atStartOfDay();
            scheduleService.createScheduleInternal(
                    ownerOid,
                    req.getScheduleTitle(),
                    "예식장",
                    tourDateTime,
                    "HALL_TOUR",
                    saved.getOid()
            );
        }

        return HallTourResponse.from(saved);
    }

    /**
     * 웨딩홀 투어를 삭제한다.
     * 투어 OID를 sourceOid로 갖는 일정도 함께 삭제한다.
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 단계 OID
     * @param tourOid 삭제할 투어 OID
     * @throws CustomException ROADMAP_STEP_NOT_FOUND, ROADMAP_HALL_TOUR_NOT_FOUND
     */
    public void deleteHallTour(String userOid, String stepOid, String tourOid) {
        String ownerOid = getOwnerOid(userOid);
        validateStepOwnership(stepOid, ownerOid);

        if (!hallTourRepository.existsByOidAndStepOid(tourOid, stepOid)) {
            throw new CustomException(ErrorCode.ROADMAP_HALL_TOUR_NOT_FOUND);
        }
        // 연관 일정 삭제 (tourOid를 sourceOid로 갖는 일정)
        scheduleRepository.deleteBySourceOid(tourOid);
        hallTourRepository.deleteById(tourOid);
        log.info("웨딩홀 투어 삭제 - tourOid: {}, stepOid: {}", tourOid, stepOid);
    }

    // =========================================================
    // 항공권 경유지
    // =========================================================

    /**
     * 항공권 경유지를 추가한다.
     * stopOrder는 기존 경유지 수 + 1로 자동 증가한다.
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 단계 OID
     * @param req     경유지 추가 요청
     * @return 추가된 경유지 응답
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    public TravelStopResponse addTravelStop(String userOid, String stepOid,
                                            AddTravelStopRequest req) {
        String ownerOid = getOwnerOid(userOid);
        validateStepOwnership(stepOid, ownerOid);

        int nextOrder = (int) travelStopRepository.countByStepOid(stepOid) + 1;
        TravelStop stop = TravelStop.builder()
                .stepOid(stepOid)
                .stopOrder(nextOrder)
                .city(req.getCity())
                .build();
        TravelStop saved = travelStopRepository.save(stop);
        log.info("경유지 추가 - stopOid: {}, stepOid: {}, order: {}", saved.getOid(), stepOid, nextOrder);
        return TravelStopResponse.from(saved);
    }

    /**
     * 항공권 경유지를 삭제한다.
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 단계 OID
     * @param stopOid 삭제할 경유지 OID
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    public void deleteTravelStop(String userOid, String stepOid, String stopOid) {
        String ownerOid = getOwnerOid(userOid);
        validateStepOwnership(stepOid, ownerOid);
        // stopOid 존재 여부 간단 검증 (소속 단계 일치 확인 포함)
        TravelStop stop = travelStopRepository.findById(stopOid)
                .orElseThrow(() -> new CustomException(ErrorCode.ROADMAP_TRAVEL_STOP_NOT_FOUND));
        if (!stop.getStepOid().equals(stepOid)) {
            throw new CustomException(ErrorCode.ROADMAP_TRAVEL_STOP_NOT_FOUND);
        }
        travelStopRepository.deleteById(stopOid);
        log.info("경유지 삭제 - stopOid: {}, stepOid: {}", stopOid, stepOid);
    }

    // =========================================================
    // 내부 유틸
    // =========================================================

    /**
     * 단계 소유권을 검증한다.
     *
     * @param stepOid  단계 OID
     * @param ownerOid 소유자 OID
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    private void validateStepOwnership(String stepOid, String ownerOid) {
        if (!roadmapStepRepository.existsByOidAndOwnerOid(stepOid, ownerOid)) {
            throw new CustomException(ErrorCode.ROADMAP_STEP_NOT_FOUND);
        }
    }

    /**
     * stepType에 해당하는 일정 카테고리를 반환한다.
     *
     * @param stepType 로드맵 단계 유형
     * @return 매핑된 일정 카테고리 문자열
     */
    private String getScheduleCategoryForStepType(String stepType) {
        return switch (stepType) {
            case "HALL" -> "예식장";
            case "PLANNER" -> "플래너";
            case "DRESS" -> "드레스";
            case "TRAVEL" -> "신혼여행";
            case "GIFT" -> "예물";
            case "SANGGYEONRYE" -> "상견례";
            default -> "기타";
        };
    }

    /**
     * 로드맵 단계의 dueDate 변경에 따라 일정을 동기화한다.
     *
     * <p>처리 규칙:
     * <ul>
     *   <li>hasDueDate=true && dueDate!=null: 기존 일정 삭제 후 새로 생성</li>
     *   <li>그 외: 기존 일정 삭제만 수행</li>
     * </ul>
     * sourceOid=step.getOid(), sourceType="ROADMAP" 으로 일정과 연결된다.
     *
     * @param ownerOid 소유자 OID
     * @param step     동기화 대상 로드맵 단계
     */
    private void syncRoadmapSchedule(String ownerOid, RoadmapStep step) {
        scheduleRepository.deleteBySourceOid(step.getOid());
        if (step.isHasDueDate() && step.getDueDate() != null) {
            String category = getScheduleCategoryForStepType(step.getStepType());
            String title = (step.getTitle() != null && !step.getTitle().isBlank())
                    ? step.getTitle() : category;
            scheduleService.createScheduleInternal(
                    ownerOid,
                    title,
                    category,
                    step.getDueDate().atStartOfDay(),
                    "ROADMAP",
                    step.getOid()
            );
            log.info("로드맵 일정 동기화 - stepOid: {}, dueDate: {}", step.getOid(), step.getDueDate());
        }
    }

    /**
     * BUDGET 단계의 details JSON에서 totalBudget을 파싱하여 예산 설정을 동기화한다.
     * 파싱 실패 시 경고 로그만 남기고 무시한다 (예산 설정 동기화 실패가 전체 트랜잭션을 롤백해서는 안 됨).
     *
     * @param ownerOid 소유자 OID
     * @param details  BUDGET 단계의 details JSON 문자열
     */
    private void syncBudgetSettings(String ownerOid, String details) {
        try {
            JsonNode node = objectMapper.readTree(details);
            if (node.has("totalBudget") && !node.get("totalBudget").isNull()) {
                long totalBudget = node.get("totalBudget").asLong();
                // 범위 체크: 1원 이상 99억 이하 (비정상값 예산 설정 방지)
                if (totalBudget < 1 || totalBudget > 9_999_999_999L) {
                    log.warn("BUDGET details totalBudget 범위 초과, 동기화 스킵: ownerOid={}, value={}",
                            ownerOid, totalBudget);
                    return;
                }
                budgetService.upsertSettingsInternal(ownerOid, totalBudget);
            }
        } catch (JsonProcessingException e) {
            log.warn("BUDGET 단계 details 파싱 실패, 예산 설정 동기화 스킵: ownerOid={}, error={}",
                    ownerOid, e.getMessage());
        }
    }
}
