package com.project.weddy.common.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.common.response.ApiResponse;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * 인증 관련 엔드포인트에 대한 IP 기반 Rate Limiting 필터.
 *
 * <p>적용 경로: 로그인, 회원가입, 토큰 갱신 (brute-force 공격 방어 목적)
 * <p>정책: IP + 경로 조합 기준, 분당 최대 10회 요청 허용 (greedy refill)
 * <p>버킷 만료: 마지막 접근 후 1분 경과 시 Caffeine 캐시에서 자동 제거
 *
 * <p>IP 추출: {@code server.forward-headers-strategy: NATIVE} 설정으로 Spring이
 * X-Forwarded-For를 검증하여 {@code request.getRemoteAddr()}에 실제 IP를 반영하므로
 * 필터에서는 RemoteAddr만 사용한다 (IP 스푸핑 방지).
 */
@Component
@Order(1)
@RequiredArgsConstructor
public class RateLimitFilter extends OncePerRequestFilter {

    private static final List<String> RATE_LIMITED_PATHS = List.of(
            "/api/v1/auth/login",
            "/api/v1/auth/signup",
            "/api/v1/auth/refresh",
            "/api/v1/couples/connect"
    );

    private static final int MAX_REQUESTS_PER_MINUTE = 10;

    private final ObjectMapper objectMapper;

    private final Cache<String, Bucket> buckets = Caffeine.newBuilder()
            .expireAfterAccess(1, TimeUnit.MINUTES)
            .build();

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String path = request.getRequestURI();

        if (!RATE_LIMITED_PATHS.contains(path)) {
            chain.doFilter(request, response);
            return;
        }

        String clientKey = getClientIp(request) + ":" + path;
        Bucket bucket = buckets.get(clientKey, key -> Bucket.builder()
                .addLimit(Bandwidth.classic(
                        MAX_REQUESTS_PER_MINUTE,
                        Refill.greedy(MAX_REQUESTS_PER_MINUTE, Duration.ofMinutes(1))
                ))
                .build()
        );

        if (bucket.tryConsume(1)) {
            chain.doFilter(request, response);
        } else {
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setCharacterEncoding("UTF-8");
            String body = objectMapper.writeValueAsString(
                    ApiResponse.fail(
                            ErrorCode.RATE_LIMIT_EXCEEDED.getCode(),
                            ErrorCode.RATE_LIMIT_EXCEEDED.getMessage()
                    )
            );
            response.getWriter().write(body);
        }
    }

    /**
     * 클라이언트 실제 IP를 추출한다.
     *
     * <p>{@code server.forward-headers-strategy: NATIVE} 설정으로 Spring(Tomcat)이
     * X-Forwarded-For를 신뢰 프록시 체인에 따라 검증한 뒤 {@code getRemoteAddr()}에
     * 실제 클라이언트 IP를 반영하므로 별도의 헤더 파싱이 불필요하다.
     * 이 방식으로 X-Forwarded-For 헤더 위조(IP 스푸핑)를 방어한다.
     */
    private String getClientIp(HttpServletRequest request) {
        return request.getRemoteAddr();
    }
}
