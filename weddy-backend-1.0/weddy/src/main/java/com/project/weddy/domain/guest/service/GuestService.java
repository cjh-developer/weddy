package com.project.weddy.domain.guest.service;

import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.domain.couple.entity.Couple;
import com.project.weddy.domain.couple.repository.CoupleRepository;
import com.project.weddy.domain.guest.dto.request.CreateGuestGroupRequest;
import com.project.weddy.domain.guest.dto.request.CreateGuestRequest;
import com.project.weddy.domain.guest.dto.request.UpdateGuestGroupRequest;
import com.project.weddy.domain.guest.dto.request.UpdateGuestRequest;
import com.project.weddy.domain.guest.dto.response.GuestGroupResponse;
import com.project.weddy.domain.guest.dto.response.GuestResponse;
import com.project.weddy.domain.guest.dto.response.GuestSummaryResponse;
import com.project.weddy.domain.guest.entity.Guest;
import com.project.weddy.domain.guest.entity.GuestGroup;
import com.project.weddy.domain.guest.repository.GuestGroupRepository;
import com.project.weddy.domain.guest.repository.GuestRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 하객 관리 서비스.
 *
 * <p>솔로 사용자도 하객 관리를 사용할 수 있다.
 * 커플 연결 전에는 owner_oid = 사용자 OID, 커플 연결 후에는 owner_oid = 커플 OID로 동작한다.
 * 모든 쓰기 연산은 소유권을 검증하여 IDOR 공격을 방지한다.
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class GuestService {

    private static final int MAX_GROUPS = 20;
    private static final int MAX_GUESTS = 500;

    private final GuestGroupRepository guestGroupRepository;
    private final GuestRepository guestRepository;
    private final CoupleRepository coupleRepository;

    // =========================================================================
    // 소유자 OID 결정
    // =========================================================================

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

    // =========================================================================
    // 하객 그룹 CRUD
    // =========================================================================

    /**
     * 소유자의 하객 그룹 목록을 sort_order 순으로 조회한다.
     * 각 그룹의 하객 수를 함께 반환한다.
     *
     * @param userOid 현재 사용자 OID
     * @return 그룹 목록 (guestCount 포함)
     */
    @Transactional(readOnly = true)
    public List<GuestGroupResponse> getGroups(String userOid) {
        String ownerOid = getOwnerOid(userOid);
        List<GuestGroup> groups = guestGroupRepository.findByOwnerOidOrderBySortOrderAsc(ownerOid);
        return groups.stream()
                .map(g -> GuestGroupResponse.from(g, guestRepository.countByGroupOid(g.getOid())))
                .toList();
    }

    /**
     * 하객 그룹을 생성한다.
     * 최대 20개 제한 검증 후 가장 마지막 순서로 추가한다.
     *
     * @param userOid 현재 사용자 OID
     * @param request 그룹명
     * @return 생성된 그룹 응답
     * @throws CustomException GUEST_GROUP_LIMIT_EXCEEDED
     */
    public GuestGroupResponse createGroup(String userOid, CreateGuestGroupRequest request) {
        String ownerOid = getOwnerOid(userOid);

        if (guestGroupRepository.countByOwnerOid(ownerOid) >= MAX_GROUPS) {
            throw new CustomException(ErrorCode.GUEST_GROUP_LIMIT_EXCEEDED);
        }

        // sort_order: 기존 그룹 최대 sortOrder + 1
        List<GuestGroup> existing = guestGroupRepository.findByOwnerOidOrderBySortOrderAsc(ownerOid);
        int nextOrder = existing.isEmpty()
                ? 0
                : existing.get(existing.size() - 1).getSortOrder() + 1;

        GuestGroup group = GuestGroup.builder()
                .ownerOid(ownerOid)
                .name(request.getName())
                .isDefault(false)
                .sortOrder(nextOrder)
                .build();
        GuestGroup saved = guestGroupRepository.save(group);
        log.debug("[GuestService] 그룹 생성 - oid: {}, ownerOid: {}", saved.getOid(), ownerOid);
        return GuestGroupResponse.from(saved, 0);
    }

    /**
     * 하객 그룹명을 수정한다.
     * is_default=true 그룹은 수정 불가 (GUEST_003).
     *
     * @param userOid  현재 사용자 OID
     * @param groupOid 수정할 그룹 OID
     * @param request  새로운 그룹명
     * @return 수정된 그룹 응답
     * @throws CustomException GUEST_GROUP_NOT_FOUND, FORBIDDEN, GUEST_GROUP_DEFAULT_DELETE
     */
    public GuestGroupResponse updateGroup(String userOid, String groupOid, UpdateGuestGroupRequest request) {
        String ownerOid = getOwnerOid(userOid);
        GuestGroup group = findGroupWithOwnerCheck(groupOid, ownerOid);

        // 기본 그룹 수정 금지
        if (group.isDefault()) {
            throw new CustomException(ErrorCode.GUEST_GROUP_DEFAULT_DELETE);
        }

        group.updateName(request.getName());
        int count = guestRepository.countByGroupOid(group.getOid());
        log.debug("[GuestService] 그룹 수정 - oid: {}, 새 이름: {}", groupOid, request.getName());
        return GuestGroupResponse.from(group, count);
    }

    /**
     * 하객 그룹을 삭제한다.
     * is_default=true 그룹은 삭제 불가 (GUEST_003).
     * 소속 하객의 group_oid는 NULL로 초기화된다.
     *
     * @param userOid  현재 사용자 OID
     * @param groupOid 삭제할 그룹 OID
     * @throws CustomException GUEST_GROUP_NOT_FOUND, FORBIDDEN, GUEST_GROUP_DEFAULT_DELETE
     */
    public void deleteGroup(String userOid, String groupOid) {
        String ownerOid = getOwnerOid(userOid);
        GuestGroup group = findGroupWithOwnerCheck(groupOid, ownerOid);

        // 기본 그룹 삭제 금지
        if (group.isDefault()) {
            throw new CustomException(ErrorCode.GUEST_GROUP_DEFAULT_DELETE);
        }

        // 소속 하객 group_oid → NULL (그룹 해제)
        guestRepository.clearGroupOid(groupOid);
        guestGroupRepository.delete(group);
        log.debug("[GuestService] 그룹 삭제 - oid: {}", groupOid);
    }

    // =========================================================================
    // 하객 CRUD + 집계
    // =========================================================================

    /**
     * 하객 집계 요약을 반환한다.
     * 모든 카운트는 companion_count + 1 기준 (본인 포함).
     *
     * @param userOid 현재 사용자 OID
     * @return 집계 요약 (총 하객 수, 참석/불참/미정, 총 축의금)
     */
    @Transactional(readOnly = true)
    public GuestSummaryResponse getSummary(String userOid) {
        String ownerOid = getOwnerOid(userOid);
        List<Guest> guests = guestRepository.findByOwnerOid(ownerOid);

        long totalCount = guests.stream().mapToLong(g -> g.getCompanionCount() + 1L).sum();
        long attendCount = guests.stream()
                .filter(g -> "ATTEND".equals(g.getAttendStatus()))
                .mapToLong(g -> g.getCompanionCount() + 1L).sum();
        long absentCount = guests.stream()
                .filter(g -> "ABSENT".equals(g.getAttendStatus()))
                .mapToLong(g -> g.getCompanionCount() + 1L).sum();
        long undecidedCount = guests.stream()
                .filter(g -> "UNDECIDED".equals(g.getAttendStatus()))
                .mapToLong(g -> g.getCompanionCount() + 1L).sum();
        long totalGiftAmount = guests.stream().mapToLong(Guest::getGiftAmount).sum();

        return GuestSummaryResponse.builder()
                .totalCount(totalCount)
                .attendCount(attendCount)
                .absentCount(absentCount)
                .undecidedCount(undecidedCount)
                .totalGiftAmount(totalGiftAmount)
                .build();
    }

    /**
     * 하객 목록을 조회한다.
     * groupOid 파라미터가 있으면 해당 그룹으로 필터링한다.
     * sort 파라미터에 따라 정렬한다.
     *
     * @param userOid  현재 사용자 OID
     * @param groupOid 그룹 필터 (null이면 전체)
     * @param sort     정렬 기준 (NAME_ASC|ATTEND_STATUS|INVITATION_STATUS|GIFT_HIGH|GIFT_LOW)
     * @return 하객 목록 (groupName 포함)
     */
    @Transactional(readOnly = true)
    public List<GuestResponse> getGuests(String userOid, String groupOid, String sort) {
        String ownerOid = getOwnerOid(userOid);

        List<Guest> guests;
        if (groupOid != null && !groupOid.isBlank()) {
            // 그룹 소유권 검증
            findGroupWithOwnerCheck(groupOid, ownerOid);
            guests = guestRepository.findByOwnerOidAndGroupOid(ownerOid, groupOid);
        } else {
            guests = guestRepository.findByOwnerOid(ownerOid);
        }

        // 그룹명 매핑 (N+1 방지: 그룹 목록을 한 번에 조회)
        List<GuestGroup> groups = guestGroupRepository.findByOwnerOidOrderBySortOrderAsc(ownerOid);
        Map<String, String> groupNameMap = groups.stream()
                .collect(Collectors.toMap(GuestGroup::getOid, GuestGroup::getName));

        List<GuestResponse> responses = guests.stream()
                .map(g -> GuestResponse.from(g, g.getGroupOid() != null ? groupNameMap.get(g.getGroupOid()) : null))
                .collect(Collectors.toList());

        // 정렬
        Comparator<GuestResponse> comparator = switch (sort != null ? sort : "NAME_ASC") {
            case "ATTEND_STATUS"     -> Comparator.comparing(GuestResponse::getAttendStatus);
            case "INVITATION_STATUS" -> Comparator.comparing(GuestResponse::getInvitationStatus);
            case "GIFT_HIGH"         -> Comparator.comparingLong(GuestResponse::getGiftAmount).reversed();
            case "GIFT_LOW"          -> Comparator.comparingLong(GuestResponse::getGiftAmount);
            default                  -> Comparator.comparing(GuestResponse::getName);
        };
        responses.sort(comparator);

        return responses;
    }

    /**
     * 하객을 추가한다.
     * 최대 500명 제한 검증 후 저장한다.
     * groupOid가 지정된 경우 소유권을 검증한다.
     *
     * @param userOid 현재 사용자 OID
     * @param request 하객 정보
     * @return 생성된 하객 응답
     * @throws CustomException GUEST_LIMIT_EXCEEDED, GUEST_GROUP_NOT_FOUND, FORBIDDEN
     */
    public GuestResponse createGuest(String userOid, CreateGuestRequest request) {
        String ownerOid = getOwnerOid(userOid);

        if (guestRepository.countByOwnerOid(ownerOid) >= MAX_GUESTS) {
            throw new CustomException(ErrorCode.GUEST_LIMIT_EXCEEDED);
        }

        // 그룹 OID가 있으면 소유권 검증
        String groupOid = request.getGroupOid();
        String groupName = null;
        if (groupOid != null) {
            GuestGroup group = findGroupWithOwnerCheck(groupOid, ownerOid);
            groupName = group.getName();
        }

        Guest guest = Guest.builder()
                .ownerOid(ownerOid)
                .groupOid(groupOid)
                .name(request.getName())
                .companionCount(request.getCompanionCount())
                .giftAmount(request.getGiftAmount())
                .invitationStatus(request.getInvitationStatus() != null ? request.getInvitationStatus() : "NONE")
                .attendStatus(request.getAttendStatus() != null ? request.getAttendStatus() : "UNDECIDED")
                .memo(request.getMemo())
                .build();
        Guest saved = guestRepository.save(guest);
        log.debug("[GuestService] 하객 추가 - oid: {}, ownerOid: {}", saved.getOid(), ownerOid);
        return GuestResponse.from(saved, groupName);
    }

    /**
     * 하객 정보를 수정한다.
     * null 필드는 기존 값을 유지한다.
     * clearGroup=true이면 그룹 OID를 NULL로 초기화한다.
     *
     * @param userOid  현재 사용자 OID
     * @param guestOid 수정할 하객 OID
     * @param request  수정 요청
     * @return 수정된 하객 응답
     * @throws CustomException GUEST_NOT_FOUND, FORBIDDEN, GUEST_GROUP_NOT_FOUND
     */
    public GuestResponse updateGuest(String userOid, String guestOid, UpdateGuestRequest request) {
        String ownerOid = getOwnerOid(userOid);
        Guest guest = findGuestWithOwnerCheck(guestOid, ownerOid);

        // 그룹 OID 변경 시 소유권 검증
        String newGroupOid = request.getGroupOid();
        String groupName = null;
        if (!request.isClearGroup() && newGroupOid != null) {
            GuestGroup group = findGroupWithOwnerCheck(newGroupOid, ownerOid);
            groupName = group.getName();
        } else if (!request.isClearGroup() && guest.getGroupOid() != null) {
            // 기존 그룹 OID 유지 시 그룹명 조회
            groupName = guestGroupRepository.findById(guest.getGroupOid())
                    .map(GuestGroup::getName)
                    .orElse(null);
        }

        guest.update(
                request.getGroupOid(), request.isClearGroup(),
                request.getName(), request.getCompanionCount(), request.getGiftAmount(),
                request.getInvitationStatus(), request.getAttendStatus(), request.getMemo()
        );

        // 수정 후 실제 groupOid 기준으로 그룹명 재조회
        String finalGroupName = null;
        if (guest.getGroupOid() != null) {
            finalGroupName = guestGroupRepository.findById(guest.getGroupOid())
                    .map(GuestGroup::getName)
                    .orElse(null);
        }

        log.debug("[GuestService] 하객 수정 - oid: {}", guestOid);
        return GuestResponse.from(guest, finalGroupName);
    }

    /**
     * 하객을 삭제한다.
     *
     * @param userOid  현재 사용자 OID
     * @param guestOid 삭제할 하객 OID
     * @throws CustomException GUEST_NOT_FOUND, FORBIDDEN
     */
    public void deleteGuest(String userOid, String guestOid) {
        String ownerOid = getOwnerOid(userOid);
        Guest guest = findGuestWithOwnerCheck(guestOid, ownerOid);
        guestRepository.delete(guest);
        log.debug("[GuestService] 하객 삭제 - oid: {}", guestOid);
    }

    // =========================================================================
    // 내부 헬퍼
    // =========================================================================

    /**
     * 그룹 OID로 그룹을 조회하고 소유권을 검증한다.
     *
     * @param groupOid 조회할 그룹 OID
     * @param ownerOid 현재 소유자 OID
     * @return 그룹 엔티티
     * @throws CustomException GUEST_GROUP_NOT_FOUND, FORBIDDEN
     */
    private GuestGroup findGroupWithOwnerCheck(String groupOid, String ownerOid) {
        GuestGroup group = guestGroupRepository.findById(groupOid)
                .orElseThrow(() -> new CustomException(ErrorCode.GUEST_GROUP_NOT_FOUND));
        if (!group.getOwnerOid().equals(ownerOid)) {
            throw new CustomException(ErrorCode.FORBIDDEN);
        }
        return group;
    }

    /**
     * 하객 OID로 하객을 조회하고 소유권을 검증한다.
     *
     * @param guestOid 조회할 하객 OID
     * @param ownerOid 현재 소유자 OID
     * @return 하객 엔티티
     * @throws CustomException GUEST_NOT_FOUND, FORBIDDEN
     */
    private Guest findGuestWithOwnerCheck(String guestOid, String ownerOid) {
        Guest guest = guestRepository.findById(guestOid)
                .orElseThrow(() -> new CustomException(ErrorCode.GUEST_NOT_FOUND));
        if (!guest.getOwnerOid().equals(ownerOid)) {
            throw new CustomException(ErrorCode.FORBIDDEN);
        }
        return guest;
    }
}
