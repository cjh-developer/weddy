package com.project.weddy.domain.user.service;

import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.common.security.JwtTokenProvider;
import com.project.weddy.domain.user.dto.request.LoginRequest;
import com.project.weddy.domain.user.dto.request.SignUpRequest;
import com.project.weddy.domain.user.dto.response.AuthResponse;
import com.project.weddy.domain.user.dto.response.UserResponse;
import com.project.weddy.domain.user.entity.RefreshToken;
import com.project.weddy.domain.user.entity.User;
import com.project.weddy.domain.user.repository.RefreshTokenRepository;
import com.project.weddy.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 사용자 인증 및 회원 정보 서비스.
 *
 * <p>주요 책임:
 * <ul>
 *   <li>회원가입: 중복 확인 → 비밀번호 암호화 → 저장 → 토큰 발급</li>
 *   <li>로그인: 자격증명 검증 → 토큰 발급 → 리프레시 토큰 upsert</li>
 *   <li>토큰 갱신: 리프레시 토큰 검증 → 새 토큰 발급 → DB 업데이트</li>
 *   <li>내 정보 조회: userOid 기반 사용자 조회</li>
 * </ul>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;

    /** 리프레시 토큰 만료 시간 (밀리초). application.yml의 jwt.refresh-expiration 값과 동기화 */
    @Value("${jwt.refresh-expiration}")
    private long refreshTokenExpiration;

    /**
     * 회원가입 처리.
     *
     * @param request 회원가입 요청 DTO
     * @return 발급된 액세스/리프레시 토큰과 사용자 기본 정보
     */
    public AuthResponse signup(SignUpRequest request) {
        // 아이디 및 이메일 중복 검사
        if (userRepository.existsByUserId(request.getUserId())) {
            throw new CustomException(ErrorCode.DUPLICATE_USER_ID);
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new CustomException(ErrorCode.DUPLICATE_EMAIL);
        }

        // 초대 코드 생성 (충돌 시 재시도)
        String inviteCode = generateUniqueInviteCode();

        // 사용자 저장 — BCrypt(cost=12) 해시 적용
        User user = User.builder()
                .userId(request.getUserId())
                .password(passwordEncoder.encode(request.getPassword()))
                .name(request.getName())
                .handPhone(request.getHandPhone())
                .email(request.getEmail())
                .role(request.getRole())
                .inviteCode(inviteCode)
                .build();

        user = userRepository.save(user);
        log.info("회원가입 완료 - userId: {}, userOid: {}", user.getUserId(), user.getOid());

        // 토큰 발급 및 리프레시 토큰 저장
        return issueTokensAndSaveRefreshToken(user);
    }

    /**
     * 로그인 처리.
     *
     * @param request 로그인 요청 DTO
     * @return 발급된 액세스/리프레시 토큰과 사용자 기본 정보
     */
    public AuthResponse login(LoginRequest request) {
        // 사용자 조회 (null 허용 — 사용자 열거 공격 방지를 위해 예외를 바로 던지지 않는다)
        User user = userRepository.findByUserId(request.getUserId()).orElse(null);

        // 사용자 없거나 비밀번호 불일치 시 동일 응답으로 통일 (사용자 열거 방지)
        if (user == null || !passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            // 타이밍 공격 방지: 사용자가 없는 경우에도 해시 연산을 수행하여
            // 응답 시간을 일정하게 유지한다. 사용자가 없는 경우에만 실행.
            if (user == null) {
                passwordEncoder.encode(request.getPassword());
            }
            throw new CustomException(ErrorCode.UNAUTHORIZED);
        }

        log.info("로그인 성공 - userId: {}, userOid: {}", maskUserId(user.getUserId()), user.getOid());

        // 토큰 발급 및 리프레시 토큰 upsert
        return issueTokensAndSaveRefreshToken(user);
    }

    /**
     * 액세스 토큰 갱신.
     * 리프레시 토큰의 유효성과 DB 일치 여부를 모두 검사한다.
     *
     * @param refreshTokenValue 클라이언트가 전달한 리프레시 토큰 문자열
     * @return 새로 발급된 액세스/리프레시 토큰과 사용자 기본 정보
     */
    public AuthResponse refreshToken(String refreshTokenValue) {
        // 만료 여부를 먼저 검사한다.
        // validateToken()은 만료 토큰에도 false를 반환하므로,
        // 순서를 바꾸면 만료 토큰이 INVALID_TOKEN으로 잘못 응답된다.
        if (jwtTokenProvider.isTokenExpired(refreshTokenValue)) {
            throw new CustomException(ErrorCode.EXPIRED_TOKEN);
        }

        // 서명 불일치·기형 토큰 등 구조적 유효성 검사
        if (!jwtTokenProvider.validateToken(refreshTokenValue)) {
            throw new CustomException(ErrorCode.INVALID_TOKEN);
        }

        // 토큰에서 userOid 추출
        String userOid = jwtTokenProvider.getUserOidFromToken(refreshTokenValue);

        // DB 저장 토큰과 일치 여부 검사 (토큰 탈취 방어)
        RefreshToken storedRefreshToken = refreshTokenRepository.findByUserOid(userOid)
                .orElseThrow(() -> new CustomException(ErrorCode.INVALID_TOKEN));

        if (!storedRefreshToken.getToken().equals(refreshTokenValue)) {
            throw new CustomException(ErrorCode.INVALID_TOKEN);
        }

        // 사용자 조회
        User user = userRepository.findById(userOid)
                .orElseThrow(() -> new CustomException(ErrorCode.USER_NOT_FOUND));

        // 새 토큰 발급
        String newAccessToken = jwtTokenProvider.generateAccessToken(user.getOid(), user.getUserId());
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(user.getOid());
        LocalDateTime newExpiresAt = LocalDateTime.now().plusSeconds(refreshTokenExpiration / 1000);

        // DB 리프레시 토큰 업데이트
        storedRefreshToken.updateToken(newRefreshToken, newExpiresAt);

        log.info("토큰 갱신 완료 - userOid: {}", userOid);

        return buildAuthResponse(user, newAccessToken, newRefreshToken);
    }

    /**
     * 내 정보 조회 (읽기 전용 트랜잭션).
     *
     * @param userOid JWT에서 추출한 사용자 OID
     * @return 사용자 정보 DTO
     */
    @Transactional(readOnly = true)
    public UserResponse getMyInfo(String userOid) {
        User user = userRepository.findById(userOid)
                .orElseThrow(() -> new CustomException(ErrorCode.USER_NOT_FOUND));
        return UserResponse.from(user);
    }

    /**
     * 결혼 예정일 업데이트.
     *
     * @param userOid     JWT에서 추출한 사용자 OID
     * @param weddingDate 새 결혼 예정일
     * @return 업데이트된 사용자 정보
     */
    public UserResponse updateWeddingDate(String userOid, LocalDate weddingDate) {
        User user = userRepository.findById(userOid)
                .orElseThrow(() -> new CustomException(ErrorCode.USER_NOT_FOUND));
        user.updateWeddingDate(weddingDate);
        return UserResponse.from(user);
    }

    // ---- private helpers ----

    /**
     * 액세스/리프레시 토큰을 발급하고 리프레시 토큰을 DB에 upsert 처리한다.
     * 이미 존재하는 경우 업데이트, 없으면 신규 저장한다.
     */
    private AuthResponse issueTokensAndSaveRefreshToken(User user) {
        String accessToken = jwtTokenProvider.generateAccessToken(user.getOid(), user.getUserId());
        String newRefreshToken = jwtTokenProvider.generateRefreshToken(user.getOid());
        LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(refreshTokenExpiration / 1000);

        // upsert: 기존 토큰이 있으면 업데이트, 없으면 새로 생성
        refreshTokenRepository.findByUserOid(user.getOid())
                .ifPresentOrElse(
                        existing -> existing.updateToken(newRefreshToken, expiresAt),
                        () -> refreshTokenRepository.save(
                                RefreshToken.builder()
                                        .userOid(user.getOid())
                                        .token(newRefreshToken)
                                        .expiresAt(expiresAt)
                                        .build()
                        )
                );

        return buildAuthResponse(user, accessToken, newRefreshToken);
    }

    /**
     * AuthResponse를 빌드한다.
     */
    private AuthResponse buildAuthResponse(User user, String accessToken, String refreshToken) {
        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .userOid(user.getOid())
                .userId(user.getUserId())
                .name(user.getName())
                .role(user.getRole() != null ? user.getRole().name() : null)
                .build();
    }

    /**
     * 로그 출력용 userId 마스킹 헬퍼.
     * 앞 3자리를 유지하고 나머지를 '*'로 치환하여 로그 분석 시 가독성을 유지하면서
     * 개인정보 직접 노출을 방지한다.
     *
     * <p>예시: "testuser" → "tes*****"
     *
     * @param userId 원본 userId
     * @return 마스킹된 userId
     */
    private String maskUserId(String userId) {
        if (userId == null || userId.length() <= 3) {
            return "***";
        }
        return userId.substring(0, 3) + "*".repeat(userId.length() - 3);
    }

    /**
     * 초대 코드를 생성하되, DB 충돌 시 최대 5회 재시도한다.
     * "WED-" + 6자리 대문자 영숫자 형태로 생성된다.
     *
     * <p>invite_code는 weddy_users 테이블에 UNIQUE 제약이 있으므로, 생성 전
     * DB 중복 여부를 확인하여 충돌 시 재시도한다.
     *
     * @return 중복 없는 초대 코드
     * @throws IllegalStateException 5회 재시도 후에도 고유 코드를 생성하지 못한 경우
     */
    private String generateUniqueInviteCode() {
        for (int attempt = 0; attempt < 5; attempt++) {
            String code = User.generateInviteCode();
            if (!userRepository.existsByInviteCode(code)) {
                return code;
            }
            log.warn("초대 코드 충돌 발생, 재시도 중 (attempt={}): {}", attempt + 1, code);
        }
        throw new IllegalStateException("초대 코드 생성 실패: 5회 시도 후 고유 코드를 생성하지 못했습니다.");
    }
}
