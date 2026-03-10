package com.project.weddy.common.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Spring Security 설정.
 *
 * <p>주요 결정 사항:
 * <ul>
 *   <li>Stateless JWT 기반 인증 → 세션 생성 없음 (STATELESS)</li>
 *   <li>CSRF 비활성화 → REST API + JWT 환경에서는 불필요</li>
 *   <li>CORS 개방 → Flutter 개발 환경에서 모든 Origin 허용 (운영 시 제한 필요)</li>
 *   <li>공개 경로: 인증 API, Swagger UI</li>
 *   <li>나머지 모든 경로: 인증 필수</li>
 * </ul>
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtTokenProvider jwtTokenProvider;
    private final ObjectMapper objectMapper;

    /** 인증 없이 접근 가능한 경로 목록 */
    private static final String[] PUBLIC_PATHS = {
            "/api/v1/auth/**",
            "/swagger-ui/**",
            "/swagger-ui.html",
            "/v3/api-docs/**",
            "/actuator/health"
    };

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            DaoAuthenticationProvider authenticationProvider
    ) throws Exception {
        http
                // REST API → CSRF 불필요
                .csrf(AbstractHttpConfigurer::disable)

                // Flutter 개발용 CORS 설정
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // Stateless 세션 — JWT로 상태 관리
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // DaoAuthenticationProvider 등록 — DB 기반 인증(UserDetailsService) 활성화
                .authenticationProvider(authenticationProvider)

                // 경로별 접근 제어
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(PUBLIC_PATHS).permitAll()
                        .anyRequest().authenticated()
                )

                // 인증되지 않은 요청에 대한 401 처리 (JSON 응답)
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((request, response, authException) -> {
                            response.setStatus(ErrorCode.UNAUTHORIZED.getHttpStatus().value());
                            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                            response.setCharacterEncoding("UTF-8");
                            ApiResponse<Void> body = ApiResponse.fail(
                                    ErrorCode.UNAUTHORIZED.getCode(),
                                    ErrorCode.UNAUTHORIZED.getMessage()
                            );
                            response.getWriter().write(objectMapper.writeValueAsString(body));
                        })
                )

                // JWT 필터를 UsernamePasswordAuthenticationFilter 앞에 배치
                .addFilterBefore(
                        new JwtAuthenticationFilter(jwtTokenProvider, objectMapper),
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }

    /**
     * BCrypt 강도 12 — 연산 비용과 보안성의 균형점.
     * 기본값(10)보다 4배 더 느리지만 현대 하드웨어에서 로그인당 수백 ms 수준으로 허용 가능하다.
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    /**
     * AuthenticationManager 빈 노출.
     * 로그인 API(/api/v1/auth/login)에서 사용자 인증 처리 시 주입받아 사용한다.
     * UserDetailsService 구현체가 등록되면 Spring Security가 자동으로 연결한다.
     */
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    /**
     * DaoAuthenticationProvider 빈 등록.
     * WeddyUserDetailsService와 BCryptPasswordEncoder를 연결하여
     * Spring Security의 AuthenticationManager가 DB 기반 인증을 수행할 수 있게 한다.
     */
    @Bean
    public DaoAuthenticationProvider authenticationProvider(WeddyUserDetailsService userDetailsService) {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    /**
     * CORS 정책 설정.
     * 운영 환경에서는 allowedOrigins를 실제 Flutter 앱 도메인으로 제한해야 한다.
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();

        // 모든 Origin 허용 (개발용) — 운영 시 변경 필수
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
