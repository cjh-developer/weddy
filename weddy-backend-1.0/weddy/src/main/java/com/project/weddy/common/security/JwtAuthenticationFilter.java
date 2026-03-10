package com.project.weddy.common.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.common.response.ApiResponse;
import io.jsonwebtoken.ExpiredJwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * 요청당 한 번 실행되는 JWT 인증 필터.
 *
 * <p>처리 흐름:
 * <ol>
 *   <li>Authorization 헤더에서 "Bearer " 접두사를 가진 토큰을 추출한다.</li>
 *   <li>{@link JwtTokenProvider}로 토큰 유효성을 검사한다.</li>
 *   <li>유효한 경우 SecurityContext에 인증 정보를 설정하고 다음 필터로 넘긴다.</li>
 *   <li>유효하지 않은 경우 401 응답을 JSON 형태로 즉시 반환한다.</li>
 * </ol>
 *
 * <p>토큰이 없는 요청은 그대로 통과시킨다. 인가 판단은 SecurityConfig에서 처리한다.
 */
@Slf4j
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtTokenProvider jwtTokenProvider;
    private final ObjectMapper objectMapper;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        String token = resolveToken(request);

        if (token == null) {
            // 토큰 없음 → 공개 경로 여부는 SecurityConfig에서 판단
            filterChain.doFilter(request, response);
            return;
        }

        // 만료된 토큰과 유효하지 않은 토큰을 구분하여 응답 — 클라이언트가 토큰 갱신 여부를 판단할 수 있도록 한다.
        if (jwtTokenProvider.isTokenExpired(token)) {
            sendUnauthorizedResponse(response, ErrorCode.EXPIRED_TOKEN);
            return;
        }

        if (!jwtTokenProvider.validateToken(token)) {
            sendUnauthorizedResponse(response, ErrorCode.INVALID_TOKEN);
            return;
        }

        // 유효한 토큰 → SecurityContext에 인증 정보 설정
        String userOid = jwtTokenProvider.getUserOidFromToken(token);
        UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                userOid,
                null,
                List.of(new SimpleGrantedAuthority("ROLE_USER"))
        );
        SecurityContextHolder.getContext().setAuthentication(authentication);
        log.debug("JWT 인증 성공 - userOid: {}", userOid);

        filterChain.doFilter(request, response);
    }

    /**
     * Authorization 헤더에서 Bearer 토큰을 추출한다.
     *
     * @return 토큰 문자열, 없으면 null
     */
    private String resolveToken(HttpServletRequest request) {
        String bearerToken = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith(BEARER_PREFIX)) {
            return bearerToken.substring(BEARER_PREFIX.length());
        }
        return null;
    }

    /**
     * 401 Unauthorized 응답을 JSON 형태의 {@link ApiResponse}로 반환한다.
     */
    private void sendUnauthorizedResponse(HttpServletResponse response, ErrorCode errorCode) throws IOException {
        log.warn("JWT 인증 실패: {}", errorCode.getMessage());
        response.setStatus(errorCode.getHttpStatus().value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");

        ApiResponse<Void> body = ApiResponse.fail(errorCode.getCode(), errorCode.getMessage());
        response.getWriter().write(objectMapper.writeValueAsString(body));
    }
}
