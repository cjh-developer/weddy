package com.project.weddy.domain.couple.service;

import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.domain.couple.dto.response.CoupleResponse;
import com.project.weddy.domain.couple.entity.Couple;
import com.project.weddy.domain.couple.repository.CoupleRepository;
import com.project.weddy.domain.user.entity.User;
import com.project.weddy.domain.user.entity.UserRole;
import com.project.weddy.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

/**
 * 커플 연결 및 조회 서비스.
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class CoupleService {

    private final CoupleRepository coupleRepository;
    private final UserRepository userRepository;

    /**
     * 파트너 초대코드를 입력하여 커플을 연결한다.
     *
     * <p>연결 순서:
     * <ol>
     *   <li>현재 사용자 조회</li>
     *   <li>이미 커플 연결 여부 확인 → COUPLE_ALREADY_CONNECTED</li>
     *   <li>파트너 초대코드로 파트너 조회 → 없으면 INVALID_INVITE_CODE</li>
     *   <li>자기 자신 코드 입력 방지 → INVALID_INVITE_CODE</li>
     *   <li>파트너 중복 커플 연결 여부 확인 → COUPLE_ALREADY_CONNECTED</li>
     *   <li>role에 따라 groom/bride 배정</li>
     *   <li>weddingDate: 현재 사용자 우선 → 파트너 날짜 → null</li>
     *   <li>Couple 저장</li>
     * </ol>
     *
     * @param userOid           현재 사용자 OID
     * @param partnerInviteCode 파트너의 초대 코드
     * @return 생성된 커플 정보
     */
    public CoupleResponse connectCouple(String userOid, String partnerInviteCode) {
        User me = userRepository.findById(userOid)
                .orElseThrow(() -> new CustomException(ErrorCode.USER_NOT_FOUND));

        if (coupleRepository.existsByGroomOidOrBrideOid(userOid, userOid)) {
            throw new CustomException(ErrorCode.COUPLE_ALREADY_CONNECTED);
        }

        User partner = userRepository.findByInviteCode(partnerInviteCode)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_INVITE_CODE));

        if (me.getOid().equals(partner.getOid())) {
            throw new CustomException(ErrorCode.INVALID_INVITE_CODE);
        }

        if (coupleRepository.existsByGroomOidOrBrideOid(partner.getOid(), partner.getOid())) {
            throw new CustomException(ErrorCode.COUPLE_ALREADY_CONNECTED);
        }

        String groomOid;
        String brideOid;
        String groomName;
        String brideName;

        if (me.getRole() == UserRole.GROOM) {
            groomOid = me.getOid();
            groomName = me.getName();
            brideOid = partner.getOid();
            brideName = partner.getName();
        } else {
            brideOid = me.getOid();
            brideName = me.getName();
            groomOid = partner.getOid();
            groomName = partner.getName();
        }

        LocalDate weddingDate = me.getWeddingDate() != null
                ? me.getWeddingDate()
                : partner.getWeddingDate();

        Couple couple = Couple.builder()
                .groomOid(groomOid)
                .brideOid(brideOid)
                .weddingDate(weddingDate)
                .totalBudget(0L)
                .build();

        couple = coupleRepository.save(couple);

        log.info("커플 연결 완료 - coupleOid: {}, groomOid: {}, brideOid: {}",
                couple.getOid(), groomOid, brideOid);

        return CoupleResponse.from(couple, groomName, brideName);
    }

    /**
     * 커플 연결을 해제한다.
     *
     * @param userOid 현재 사용자 OID
     */
    public void disconnectCouple(String userOid) {
        Couple couple = coupleRepository.findByGroomOidOrBrideOid(userOid, userOid)
                .orElseThrow(() -> new CustomException(ErrorCode.COUPLE_NOT_FOUND));
        coupleRepository.delete(couple);
        log.info("커플 연결 해제 완료 - coupleOid: {}, userOid: {}", couple.getOid(), userOid);
    }

    /**
     * 내 커플 정보 조회 (읽기 전용).
     *
     * @param userOid 현재 사용자 OID
     * @return 커플 정보
     */
    @Transactional(readOnly = true)
    public CoupleResponse getMyCouple(String userOid) {
        Couple couple = coupleRepository.findByGroomOidOrBrideOid(userOid, userOid)
                .orElseThrow(() -> new CustomException(ErrorCode.COUPLE_NOT_FOUND));

        String groomName = userRepository.findById(couple.getGroomOid())
                .map(User::getName)
                .orElse("알 수 없음");

        String brideName = couple.getBrideOid() != null
                ? userRepository.findById(couple.getBrideOid())
                        .map(User::getName)
                        .orElse("알 수 없음")
                : null;

        return CoupleResponse.from(couple, groomName, brideName);
    }
}
