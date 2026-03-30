package com.project.weddy.domain.roadmap.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.domain.attachment.service.AttachmentService;
import com.project.weddy.domain.budget.service.BudgetService;
import com.project.weddy.domain.couple.entity.Couple;
import com.project.weddy.domain.couple.repository.CoupleRepository;
import com.project.weddy.domain.roadmap.dto.request.AddTravelStopRequest;
import com.project.weddy.domain.roadmap.dto.request.CreateCustomRoadmapRequest;
import com.project.weddy.domain.roadmap.dto.request.CreateHallTourRequest;
import com.project.weddy.domain.roadmap.dto.request.CreateRoadmapStepRequest;
import com.project.weddy.domain.roadmap.dto.request.ReorderRequest;
import com.project.weddy.domain.roadmap.dto.request.RenameCustomRoadmapRequest;
import com.project.weddy.domain.roadmap.dto.request.UpdateRoadmapStepRequest;
import com.project.weddy.domain.roadmap.dto.request.UpdateStatusRequest;
import com.project.weddy.domain.user.entity.User;
import com.project.weddy.domain.user.repository.UserRepository;
import com.project.weddy.domain.roadmap.dto.response.CustomRoadmapResponse;
import com.project.weddy.domain.roadmap.dto.response.HallTourResponse;
import com.project.weddy.domain.roadmap.dto.response.RoadmapStepResponse;
import com.project.weddy.domain.roadmap.dto.response.TravelStopResponse;
import com.project.weddy.domain.roadmap.entity.CustomRoadmap;
import com.project.weddy.domain.roadmap.entity.HallTour;
import com.project.weddy.domain.roadmap.entity.RoadmapStep;
import com.project.weddy.domain.roadmap.entity.TravelStop;
import com.project.weddy.domain.roadmap.repository.CustomRoadmapRepository;
import com.project.weddy.domain.roadmap.repository.HallTourRepository;
import com.project.weddy.domain.roadmap.repository.RoadmapStepRepository;
import com.project.weddy.domain.roadmap.repository.TravelStopRepository;
import com.project.weddy.domain.schedule.repository.ScheduleRepository;
import com.project.weddy.domain.schedule.service.ScheduleService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

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
    private final CustomRoadmapRepository customRoadmapRepository;
    private final HallTourRepository hallTourRepository;
    private final TravelStopRepository travelStopRepository;
    private final CoupleRepository coupleRepository;
    private final UserRepository userRepository;
    private final ScheduleService scheduleService;
    private final ScheduleRepository scheduleRepository;
    private final BudgetService budgetService;
    private final AttachmentService attachmentService;
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
     * 소유자의 기본 로드맵 단계 목록을 sortOrder 오름차순으로 조회한다.
     * group_oid가 NULL인 단계만 반환한다 (직접 로드맵 소속 단계는 제외).
     *
     * @param userOid 현재 사용자 OID
     * @return 기본 로드맵 단계 목록
     */
    @Transactional(readOnly = true)
    public List<RoadmapStepResponse> getSteps(String userOid) {
        String ownerOid = getOwnerOid(userOid);
        return roadmapStepRepository.findByOwnerOidAndGroupOidIsNullOrderBySortOrderAsc(ownerOid)
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

        // groupOid가 있으면 해당 직접 로드맵이 소유자 것인지 검증
        String groupOid = req.getGroupOid();
        if (groupOid != null && !groupOid.isBlank()) {
            customRoadmapRepository.findByOidAndOwnerOid(groupOid, ownerOid)
                    .orElseThrow(() -> new CustomException(ErrorCode.CUSTOM_ROADMAP_NOT_FOUND));
        } else {
            groupOid = null;
        }

        // 20개 제한: 기본 로드맵(group_oid=NULL) 단계에만 적용한다.
        // 직접 로드맵 단계는 별도 컨테이너에 속하므로 합산하지 않는다.
        long scopeCount = (groupOid == null)
                ? roadmapStepRepository.countByOwnerOidAndGroupOidIsNull(ownerOid)
                : roadmapStepRepository.countByOwnerOidAndGroupOid(ownerOid, groupOid);
        if (groupOid == null && scopeCount >= 20) {
            throw new CustomException(ErrorCode.ROADMAP_STEP_LIMIT_EXCEEDED);
        }

        // 다음 sort_order: 현재 스코프 내 개수 + 1 (0-indexed 방지)
        int nextSortOrder = (int) scopeCount + 1;

        RoadmapStep step = RoadmapStep.builder()
                .ownerOid(ownerOid)
                .stepType(req.getStepType())
                .groupOid(groupOid)
                .title(req.getTitle())
                .isDone(false)
                .status("NOT_STARTED")
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
            syncBudgetItemsFromDetails(ownerOid, req.getDetails());
        }

        // SANGGYEONRYE 단계 생성 시 details의 date로 일정 자동 등록
        if ("SANGGYEONRYE".equals(req.getStepType()) && req.getDetails() != null) {
            syncSanggyeonryeSchedule(ownerOid, saved, req.getDetails());
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
            syncBudgetItemsFromDetails(ownerOid, req.getDetails());
        }

        // SANGGYEONRYE 단계의 details가 변경된 경우 상견례 일정 동기화
        if ("SANGGYEONRYE".equals(step.getStepType()) && req.getDetails() != null) {
            syncSanggyeonryeSchedule(ownerOid, step, req.getDetails());
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
     * 단계 상태를 변경한다 (NOT_STARTED | IN_PROGRESS | DONE).
     *
     * @param userOid 현재 사용자 OID
     * @param stepOid 변경할 단계 OID
     * @param req     상태 변경 요청
     * @return 변경된 단계 응답
     * @throws CustomException ROADMAP_STEP_NOT_FOUND
     */
    public RoadmapStepResponse updateStatus(String userOid, String stepOid, UpdateStatusRequest req) {
        String ownerOid = getOwnerOid(userOid);
        RoadmapStep step = roadmapStepRepository.findByOidAndOwnerOid(stepOid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.ROADMAP_STEP_NOT_FOUND));
        step.updateStatus(req.getStatus());
        log.info("로드맵 단계 상태 변경 - oid: {}, status: {}", stepOid, req.getStatus());
        return RoadmapStepResponse.from(step);
    }

    /**
     * 기본 로드맵 8단계를 일괄 생성한다.
     * 이미 단계가 존재하면 ROADMAP_ALREADY_INITIALIZED 예외를 발생시킨다.
     * weddingDate가 있으면 각 구간의 dueDate를 역산한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 생성된 단계 목록
     * @throws CustomException ROADMAP_ALREADY_INITIALIZED (단계가 이미 존재할 때)
     */
    public List<RoadmapStepResponse> initDefaultRoadmap(String userOid) {
        String ownerOid = getOwnerOid(userOid);

        // 기본 로드맵(group_oid IS NULL) 단계만 확인한다.
        // 직접 로드맵 단계가 있어도 기본 로드맵 생성은 별도로 허용한다.
        long existing = roadmapStepRepository.countByOwnerOidAndGroupOidIsNull(ownerOid);
        if (existing > 0) {
            throw new CustomException(ErrorCode.ROADMAP_ALREADY_INITIALIZED);
        }

        // 결혼 날짜 조회: userOid로 개인 weddingDate 조회
        LocalDate weddingDate = userRepository.findById(userOid)
                .map(User::getWeddingDate)
                .orElse(null);

        // 8단계 기본 구성 (stepType, title, dueDate offset 개월)
        record StepTemplate(String stepType, String title, int monthsBefore) {}

        List<StepTemplate> templates = List.of(
            new StepTemplate("HALL",         "웨딩홀 투어 및 예약",              12),
            new StepTemplate("BUDGET",       "웨딩 예산 설정",                   12),
            new StepTemplate("PLANNER",      "스드메 / 플래너 예약",             9),
            new StepTemplate("GIFT",         "예물 준비",                        9),
            new StepTemplate("DRESS",        "스튜디오 촬영 / 메이크업 리허설",  7),
            new StepTemplate("HOME",         "신혼집 및 신혼여행 계획",          6),
            new StepTemplate("TRAVEL",       "청첩장 및 혼수 준비",              3),
            new StepTemplate("SANGGYEONRYE", "최종 점검 및 당일 준비",           1)
        );

        List<RoadmapStep> steps = new ArrayList<>();
        for (int i = 0; i < templates.size(); i++) {
            StepTemplate t = templates.get(i);
            LocalDate dueDate = (weddingDate != null)
                    ? weddingDate.minusMonths(t.monthsBefore())
                    : null;

            RoadmapStep step = RoadmapStep.builder()
                    .ownerOid(ownerOid)
                    .stepType(t.stepType())
                    .title(t.title())
                    .isDone(false)
                    .status("NOT_STARTED")
                    .dueDate(dueDate)
                    .hasDueDate(dueDate != null)
                    .sortOrder(i + 1)
                    .build();
            steps.add(step);
        }

        List<RoadmapStep> saved = roadmapStepRepository.saveAll(steps);
        log.info("기본 로드맵 {} 단계 일괄 생성 - ownerOid: {}", saved.size(), ownerOid);
        return saved.stream().map(RoadmapStepResponse::from).toList();
    }

    /**
     * 단계 순서를 일괄 변경한다.
     * 소유권 검증 후 sortOrder를 업데이트한다.
     * 요청의 oid 수와 실제 조회된 단계 수가 다르면 ROADMAP_REORDER_INVALID 예외를 발생시킨다.
     *
     * @param userOid 현재 사용자 OID
     * @param req     순서 변경 요청
     * @throws CustomException ROADMAP_REORDER_INVALID
     */
    public void reorderSteps(String userOid, ReorderRequest req) {
        String ownerOid = getOwnerOid(userOid);

        if (req.getOrders() == null || req.getOrders().isEmpty()) {
            throw new CustomException(ErrorCode.ROADMAP_REORDER_INVALID);
        }

        List<String> oids = req.getOrders().stream()
                .map(ReorderRequest.OrderItem::getOid)
                .toList();
        List<RoadmapStep> steps = roadmapStepRepository.findAllByOidInAndOwnerOid(oids, ownerOid);

        if (steps.size() != oids.size()) {
            throw new CustomException(ErrorCode.ROADMAP_REORDER_INVALID);
        }

        Map<String, RoadmapStep> stepMap = new java.util.HashMap<>();
        steps.forEach(s -> stepMap.put(s.getOid(), s));

        for (ReorderRequest.OrderItem item : req.getOrders()) {
            RoadmapStep step = stepMap.get(item.getOid());
            if (step != null) {
                step.updateSortOrder(item.getSortOrder());
            }
        }
        log.info("로드맵 단계 순서 변경 - ownerOid: {}, count: {}", ownerOid, steps.size());
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
        RoadmapStep step = roadmapStepRepository.findByOidAndOwnerOid(stepOid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.ROADMAP_STEP_NOT_FOUND));

        // BUDGET 단계 삭제 시 연동 예산 항목 초기화
        if ("BUDGET".equals(step.getStepType())) {
            budgetService.clearBudgetItemsFromRoadmap(ownerOid);
        }

        hallTourRepository.deleteByStepOid(stepOid);
        travelStopRepository.deleteByStepOid(stepOid);
        // sourceOid = stepOid 로 연결된 일정 삭제 (sourceType="ROADMAP", "HALL_TOUR" 등)
        scheduleRepository.deleteBySourceOid(stepOid);
        // sourceOid = stepOid + "_SANG" 로 연결된 일정 삭제 (SANGGYEONRYE 상견례 일정)
        // SANGGYEONRYE가 아닌 단계에서는 해당 sourceOid가 존재하지 않으므로 항상 실행해도 무관
        scheduleRepository.deleteBySourceOid(stepOid + "_SANG");
        // 단계에 연결된 첨부파일 연쇄 삭제 (물리 파일 + 레코드)
        attachmentService.deleteByRefOid(stepOid);
        roadmapStepRepository.deleteById(stepOid);
        log.info("로드맵 단계 삭제 - oid: {}, ownerOid: {}", stepOid, ownerOid);
    }

    // =========================================================
    // 직접 로드맵 CRUD
    // =========================================================

    /**
     * 소유자의 직접 로드맵 목록을 sortOrder 오름차순으로 조회한다.
     * 각 로드맵에 소속된 단계 목록(group_oid 일치)을 함께 반환한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 직접 로드맵 목록 (단계 포함)
     */
    @Transactional(readOnly = true)
    public List<CustomRoadmapResponse> getCustomRoadmaps(String userOid) {
        String ownerOid = getOwnerOid(userOid);
        List<CustomRoadmap> roadmaps = customRoadmapRepository.findByOwnerOidOrderBySortOrderAsc(ownerOid);
        return roadmaps.stream().map(cr -> {
            List<RoadmapStepResponse> steps = roadmapStepRepository
                    .findByOwnerOidAndGroupOidOrderBySortOrderAsc(ownerOid, cr.getOid())
                    .stream().map(RoadmapStepResponse::from).toList();
            return CustomRoadmapResponse.from(cr, steps);
        }).toList();
    }

    /**
     * 직접 로드맵을 생성한다.
     * 소유자당 최대 10개 제한이 있다.
     *
     * @param userOid 현재 사용자 OID
     * @param req     직접 로드맵 생성 요청
     * @return 생성된 직접 로드맵 응답
     * @throws CustomException CUSTOM_ROADMAP_LIMIT_EXCEEDED (10개 초과)
     */
    public CustomRoadmapResponse createCustomRoadmap(String userOid, CreateCustomRoadmapRequest req) {
        String ownerOid = getOwnerOid(userOid);
        long count = customRoadmapRepository.countByOwnerOid(ownerOid);
        if (count >= 10) {
            throw new CustomException(ErrorCode.CUSTOM_ROADMAP_LIMIT_EXCEEDED);
        }
        int nextSortOrder = (int) count + 1;
        CustomRoadmap cr = CustomRoadmap.builder()
                .ownerOid(ownerOid)
                .name(req.getName())
                .sortOrder(nextSortOrder)
                .build();
        CustomRoadmap saved = customRoadmapRepository.save(cr);
        log.info("직접 로드맵 생성 - oid: {}, name: {}, ownerOid: {}", saved.getOid(), saved.getName(), ownerOid);
        return CustomRoadmapResponse.from(saved);
    }

    /**
     * 직접 로드맵의 이름을 변경한다.
     *
     * @param userOid  현재 사용자 OID
     * @param groupOid 변경할 직접 로드맵 OID
     * @param req      이름 변경 요청
     * @return 변경된 직접 로드맵 응답
     * @throws CustomException CUSTOM_ROADMAP_NOT_FOUND
     */
    public CustomRoadmapResponse renameCustomRoadmap(String userOid, String groupOid,
                                                     RenameCustomRoadmapRequest req) {
        String ownerOid = getOwnerOid(userOid);
        CustomRoadmap cr = customRoadmapRepository.findByOidAndOwnerOid(groupOid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.CUSTOM_ROADMAP_NOT_FOUND));
        cr.rename(req.getName());
        log.info("직접 로드맵 이름 변경 - oid: {}, newName: {}, ownerOid: {}", groupOid, req.getName(), ownerOid);
        return CustomRoadmapResponse.from(cr);
    }

    /**
     * 직접 로드맵과 소속된 모든 단계를 삭제한다.
     * 삭제 순서: 각 단계별 투어 → 경유지 → 연관 일정 → 첨부파일 → 단계 일괄 삭제 → 로드맵 삭제
     *
     * @param userOid  현재 사용자 OID
     * @param groupOid 삭제할 직접 로드맵 OID
     * @throws CustomException CUSTOM_ROADMAP_NOT_FOUND
     */
    public void deleteCustomRoadmap(String userOid, String groupOid) {
        String ownerOid = getOwnerOid(userOid);
        customRoadmapRepository.findByOidAndOwnerOid(groupOid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.CUSTOM_ROADMAP_NOT_FOUND));

        List<RoadmapStep> steps = roadmapStepRepository
                .findByOwnerOidAndGroupOidOrderBySortOrderAsc(ownerOid, groupOid);

        for (RoadmapStep step : steps) {
            hallTourRepository.deleteByStepOid(step.getOid());
            travelStopRepository.deleteByStepOid(step.getOid());
            scheduleRepository.deleteBySourceOid(step.getOid());
            scheduleRepository.deleteBySourceOid(step.getOid() + "_SANG");
            attachmentService.deleteByRefOid(step.getOid());
        }
        roadmapStepRepository.deleteAll(steps);
        customRoadmapRepository.deleteById(groupOid);
        log.info("직접 로드맵 삭제 - oid: {}, stepCount: {}, ownerOid: {}", groupOid, steps.size(), ownerOid);
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

        // tourDate가 있으면 일정 자동 등록 (scheduleTitle이 없으면 hallName + " 투어" 사용)
        if (req.getTourDate() != null) {
            String schedTitle = (req.getScheduleTitle() != null && !req.getScheduleTitle().isBlank())
                    ? req.getScheduleTitle()
                    : req.getHallName() + " 투어";
            LocalDateTime tourDateTime = req.getTourDate().atStartOfDay();
            scheduleService.createScheduleInternal(
                    ownerOid,
                    schedTitle,
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
     * BUDGET 단계의 details JSON에서 budgetItems 배열을 파싱하여 예산 항목을 동기화한다.
     *
     * @param ownerOid 소유자 OID
     * @param details  BUDGET 단계의 details JSON 문자열
     */
    @SuppressWarnings("unchecked")
    private void syncBudgetItemsFromDetails(String ownerOid, String details) {
        try {
            JsonNode node = objectMapper.readTree(details);
            if (!node.has("budgetItems") || node.get("budgetItems").isNull()) return;

            JsonNode itemsNode = node.get("budgetItems");
            if (!itemsNode.isArray()) return;

            List<Map<String, Object>> items = new ArrayList<>();
            for (JsonNode item : itemsNode) {
                Map<String, Object> m = objectMapper.convertValue(item, Map.class);
                items.add(m);
            }
            budgetService.syncBudgetItemsFromRoadmap(ownerOid, items);
        } catch (Exception e) {
            // JsonProcessingException + convertValue의 IllegalArgumentException 모두 처리
            log.warn("BUDGET budgetItems 파싱 실패, 예산 항목 동기화 스킵: ownerOid={}, exceptionType={}",
                    ownerOid, e.getClass().getSimpleName());
        }
    }

    /**
     * SANGGYEONRYE 단계의 details JSON에서 date를 파싱하여 상견례 일정을 동기화한다.
     * sourceType="SANGGYEONRYE", sourceOid=stepOid+"_SANG" 으로 식별한다.
     *
     * @param ownerOid 소유자 OID
     * @param step     로드맵 단계
     * @param details  SANGGYEONRYE 단계의 details JSON 문자열
     */
    private void syncSanggyeonryeSchedule(String ownerOid, RoadmapStep step, String details) {
        final String sourceOid = step.getOid() + "_SANG";
        scheduleRepository.deleteBySourceOid(sourceOid);
        try {
            JsonNode node = objectMapper.readTree(details);
            if (!node.has("date") || node.get("date").isNull()) return;

            String dateStr = node.get("date").asText();
            LocalDate date = LocalDate.parse(dateStr);
            String restaurantName = node.has("restaurantName") && !node.get("restaurantName").isNull()
                    ? node.get("restaurantName").asText() : "상견례";
            String title = restaurantName + " 상견례";
            scheduleService.createScheduleInternal(
                    ownerOid,
                    title,
                    "상견례",
                    date.atStartOfDay(),
                    "SANGGYEONRYE",
                    sourceOid
            );
            log.info("상견례 일정 동기화 - stepOid: {}, date: {}", step.getOid(), date);
        } catch (Exception e) {
            log.warn("SANGGYEONRYE date 파싱 실패, 일정 동기화 스킵: ownerOid={}, exceptionType={}",
                    ownerOid, e.getClass().getSimpleName());
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
