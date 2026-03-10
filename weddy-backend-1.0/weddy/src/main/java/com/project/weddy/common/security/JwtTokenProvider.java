package com.project.weddy.common.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.security.SecurityException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT 액세스 토큰 및 리프레시 토큰 생성/검증 컴포넌트.
 * jjwt 0.12.x API 기준으로 작성되었다.
 *
 * <p>토큰 클레임 구조:
 * <ul>
 *   <li>sub  : userOid (엔티티 PK)</li>
 *   <li>uid  : userId  (로그인 ID, 액세스 토큰에만 포함)</li>
 *   <li>iat  : 발급 시각</li>
 *   <li>exp  : 만료 시각</li>
 * </ul>
 */
@Slf4j
@Component
public class JwtTokenProvider {

    private static final String CLAIM_USER_ID = "uid";

    private final SecretKey secretKey;
    private final long accessTokenExpiration;
    private final long refreshTokenExpiration;

    public JwtTokenProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.expiration}") long accessTokenExpiration,
            @Value("${jwt.refresh-expiration}") long refreshTokenExpiration
    ) {
        // jjwt 0.12.x: Keys.hmacShaKeyFor()로 SecretKey 생성
        this.secretKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessTokenExpiration = accessTokenExpiration;
        this.refreshTokenExpiration = refreshTokenExpiration;
    }

    /**
     * 액세스 토큰을 생성한다.
     *
     * @param userOid 사용자 엔티티 PK (14자리 숫자 문자열)
     * @param userId  로그인 아이디
     * @return 서명된 JWT 문자열
     */
    public String generateAccessToken(String userOid, String userId) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + accessTokenExpiration);

        return Jwts.builder()
                .subject(userOid)
                .claim(CLAIM_USER_ID, userId)
                .issuedAt(now)
                .expiration(expiry)
                .signWith(secretKey)
                .compact();
    }

    /**
     * 리프레시 토큰을 생성한다.
     * 리프레시 토큰에는 최소한의 정보(sub)만 포함한다.
     *
     * @param userOid 사용자 엔티티 PK
     * @return 서명된 JWT 문자열
     */
    public String generateRefreshToken(String userOid) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + refreshTokenExpiration);

        return Jwts.builder()
                .subject(userOid)
                .issuedAt(now)
                .expiration(expiry)
                .signWith(secretKey)
                .compact();
    }

    /**
     * 토큰에서 userOid(sub 클레임)를 추출한다.
     *
     * @param token JWT 문자열
     * @return userOid
     * @throws JwtException 토큰이 유효하지 않을 경우
     */
    public String getUserOidFromToken(String token) {
        return parseClaims(token).getSubject();
    }

    /**
     * 토큰의 유효성을 검사한다.
     * 서명 불일치, 만료, 기형 토큰 등 모든 jjwt 예외를 포괄한다.
     *
     * @param token JWT 문자열
     * @return 유효하면 true, 그 외 false
     */
    public boolean validateToken(String token) {
        try {
            parseClaims(token);
            return true;
        } catch (ExpiredJwtException e) {
            log.debug("만료된 JWT 토큰: {}", e.getMessage());
        } catch (UnsupportedJwtException e) {
            log.debug("지원하지 않는 JWT 토큰: {}", e.getMessage());
        } catch (MalformedJwtException e) {
            log.debug("기형 JWT 토큰: {}", e.getMessage());
        } catch (SecurityException e) {
            log.debug("JWT 서명 검증 실패: {}", e.getMessage());
        } catch (IllegalArgumentException e) {
            log.debug("JWT 클레임이 비어 있음: {}", e.getMessage());
        }
        return false;
    }

    /**
     * 토큰 만료 여부만 별도로 확인한다 (리프레시 토큰 처리 시 활용).
     *
     * @param token JWT 문자열
     * @return 만료되었으면 true
     */
    public boolean isTokenExpired(String token) {
        try {
            parseClaims(token);
            return false;
        } catch (ExpiredJwtException e) {
            return true;
        } catch (JwtException e) {
            return false;
        }
    }

    // ---- private helpers ----

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
