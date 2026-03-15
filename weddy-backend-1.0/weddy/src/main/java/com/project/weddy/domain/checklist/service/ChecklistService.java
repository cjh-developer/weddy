package com.project.weddy.domain.checklist.service;

import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.domain.checklist.dto.request.CreateChecklistItemRequest;
import com.project.weddy.domain.checklist.dto.request.CreateChecklistRequest;
import com.project.weddy.domain.checklist.dto.request.UpdateChecklistItemRequest;
import com.project.weddy.domain.checklist.dto.response.ChecklistItemResponse;
import com.project.weddy.domain.checklist.dto.response.ChecklistResponse;
import com.project.weddy.domain.checklist.entity.Checklist;
import com.project.weddy.domain.checklist.entity.ChecklistItem;
import com.project.weddy.domain.checklist.repository.ChecklistItemRepository;
import com.project.weddy.domain.checklist.repository.ChecklistRepository;
import com.project.weddy.domain.couple.entity.Couple;
import com.project.weddy.domain.couple.repository.CoupleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 체크리스트 CRUD 서비스.
 *
 * <p>모든 쓰기 연산은 커플 소유권을 검증하여 IDOR 공격을 방지한다.
 * 커플에 연결되지 않은 사용자는 모든 체크리스트 연산에서 COUPLE_NOT_FOUND 예외를 받는다.
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class ChecklistService {

    private final ChecklistRepository checklistRepository;
    private final ChecklistItemRepository checklistItemRepository;
    private final CoupleRepository coupleRepository;

    /**
     * 사용자 OID로 커플을 조회한다. 커플이 없으면 예외를 던진다.
     */
    private Couple getCoupleOrThrow(String userOid) {
        return coupleRepository.findByGroomOidOrBrideOid(userOid, userOid)
                .orElseThrow(() -> new CustomException(ErrorCode.COUPLE_NOT_FOUND));
    }

    /**
     * 체크리스트 소유권을 검증한다.
     * 지정된 커플에 속하지 않는 체크리스트 접근 시 예외를 던진다.
     */
    private void validateChecklistOwnership(String checklistOid, String coupleOid) {
        if (!checklistRepository.existsByOidAndCoupleOid(checklistOid, coupleOid)) {
            throw new CustomException(ErrorCode.CHECKLIST_NOT_FOUND);
        }
    }

    /**
     * 항목 소유권을 검증한다.
     * 지정된 체크리스트에 속하지 않는 항목 접근 시 예외를 던진다.
     */
    private void validateItemOwnership(String itemOid, String checklistOid) {
        if (!checklistItemRepository.existsByOidAndChecklistOid(itemOid, checklistOid)) {
            throw new CustomException(ErrorCode.CHECKLIST_ITEM_NOT_FOUND);
        }
    }

    /**
     * 커플의 전체 체크리스트 목록과 각 체크리스트의 항목을 조회한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 체크리스트 목록 (항목 포함)
     */
    @Transactional(readOnly = true)
    public List<ChecklistResponse> getChecklists(String userOid) {
        Couple couple = getCoupleOrThrow(userOid);
        List<Checklist> checklists =
                checklistRepository.findByCoupleOidOrderByCreatedAtAsc(couple.getOid());
        return checklists.stream().map(cl -> {
            List<ChecklistItem> items =
                    checklistItemRepository.findByChecklistOidOrderBySortOrderAscCreatedAtAsc(cl.getOid());
            return ChecklistResponse.from(cl, items);
        }).toList();
    }

    /**
     * 체크리스트를 생성한다.
     *
     * @param userOid 현재 사용자 OID
     * @param req     체크리스트 생성 요청
     * @return 생성된 체크리스트 응답
     */
    public ChecklistResponse createChecklist(String userOid, CreateChecklistRequest req) {
        Couple couple = getCoupleOrThrow(userOid);
        Checklist checklist = Checklist.builder()
                .coupleOid(couple.getOid())
                .title(req.getTitle())
                .category(req.getCategory())
                .build();
        checklist = checklistRepository.save(checklist);
        log.info("체크리스트 생성 - checklistOid: {}, coupleOid: {}", checklist.getOid(), couple.getOid());
        return ChecklistResponse.from(checklist, List.of());
    }

    /**
     * 체크리스트와 소속 항목을 모두 삭제한다.
     *
     * @param userOid      현재 사용자 OID
     * @param checklistOid 삭제할 체크리스트 OID
     */
    public void deleteChecklist(String userOid, String checklistOid) {
        Couple couple = getCoupleOrThrow(userOid);
        validateChecklistOwnership(checklistOid, couple.getOid());
        checklistItemRepository.deleteByChecklistOid(checklistOid);
        checklistRepository.deleteById(checklistOid);
        log.info("체크리스트 삭제 - checklistOid: {}, coupleOid: {}", checklistOid, couple.getOid());
    }

    /**
     * 체크리스트에 항목을 추가한다.
     *
     * @param userOid      현재 사용자 OID
     * @param checklistOid 대상 체크리스트 OID
     * @param req          항목 생성 요청
     * @return 생성된 항목 응답
     */
    public ChecklistItemResponse addItem(
            String userOid, String checklistOid, CreateChecklistItemRequest req) {
        Couple couple = getCoupleOrThrow(userOid);
        validateChecklistOwnership(checklistOid, couple.getOid());
        ChecklistItem item = ChecklistItem.builder()
                .checklistOid(checklistOid)
                .content(req.getContent())
                .isDone(false)
                .dueDate(req.getDueDate())
                .sortOrder(req.getSortOrder())
                .build();
        ChecklistItem saved = checklistItemRepository.save(item);
        log.info("체크리스트 항목 추가 - itemOid: {}, checklistOid: {}", saved.getOid(), checklistOid);
        return ChecklistItemResponse.from(saved);
    }

    /**
     * 체크리스트 항목을 부분 수정한다.
     * null인 필드는 기존 값을 유지한다.
     *
     * @param userOid      현재 사용자 OID
     * @param checklistOid 체크리스트 OID
     * @param itemOid      수정할 항목 OID
     * @param req          수정 요청
     * @return 수정된 항목 응답
     */
    public ChecklistItemResponse updateItem(
            String userOid, String checklistOid, String itemOid, UpdateChecklistItemRequest req) {
        Couple couple = getCoupleOrThrow(userOid);
        validateChecklistOwnership(checklistOid, couple.getOid());
        ChecklistItem item = checklistItemRepository.findById(itemOid)
                .orElseThrow(() -> new CustomException(ErrorCode.CHECKLIST_ITEM_NOT_FOUND));
        // 추가 DB 조회 없이 인메모리에서 소유권 확인
        if (!item.getChecklistOid().equals(checklistOid)) {
            throw new CustomException(ErrorCode.CHECKLIST_ITEM_NOT_FOUND);
        }
        item.update(req.getContent(), req.getIsDone(), req.getDueDate(), req.getSortOrder());
        return ChecklistItemResponse.from(item);
    }

    /**
     * 체크리스트 항목을 삭제한다.
     *
     * @param userOid      현재 사용자 OID
     * @param checklistOid 체크리스트 OID
     * @param itemOid      삭제할 항목 OID
     */
    public void deleteItem(String userOid, String checklistOid, String itemOid) {
        Couple couple = getCoupleOrThrow(userOid);
        validateChecklistOwnership(checklistOid, couple.getOid());
        validateItemOwnership(itemOid, checklistOid);
        checklistItemRepository.deleteById(itemOid);
        log.info("체크리스트 항목 삭제 - itemOid: {}, checklistOid: {}", itemOid, checklistOid);
    }

    /**
     * 홈 화면용 미완료 항목 프리뷰를 조회한다.
     * 목표일 오름차순으로 최대 limit개를 반환한다.
     *
     * @param userOid 현재 사용자 OID
     * @param limit   최대 반환 개수
     * @return 미완료 항목 목록
     */
    @Transactional(readOnly = true)
    public List<ChecklistItemResponse> getHomePreview(String userOid, int limit) {
        Couple couple = getCoupleOrThrow(userOid);
        return checklistItemRepository.findRecentUndoneItems(couple.getOid(), limit)
                .stream().map(ChecklistItemResponse::from).toList();
    }
}
