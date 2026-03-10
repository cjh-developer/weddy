package com.project.weddy.common.security;

import com.project.weddy.domain.user.entity.User;
import com.project.weddy.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Spring Security의 {@link UserDetailsService} 구현체.
 *
 * <p>Spring Security의 DaoAuthenticationProvider가 사용자 정보를 로드할 때 호출된다.
 * 로그인 아이디(userId)로 사용자를 조회하며, UserDetails의 username에는
 * userId가 아닌 userOid를 저장한다. 이렇게 하면 이후 {@code @AuthenticationPrincipal}로
 * userOid를 직접 꺼낼 수 있어 추가 DB 조회 없이 사용 가능하다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WeddyUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    /**
     * 로그인 아이디로 사용자를 조회하여 {@link UserDetails}를 반환한다.
     *
     * <p>반환되는 UserDetails:
     * <ul>
     *   <li>username: userOid (JWT sub 클레임과 동일한 값)</li>
     *   <li>password: BCrypt 해시된 비밀번호</li>
     *   <li>authorities: ROLE_USER</li>
     * </ul>
     *
     * @param userId 로그인 아이디 (Spring Security가 전달하는 username 파라미터)
     * @return UserDetails 구현체
     * @throws UsernameNotFoundException 사용자를 찾을 수 없는 경우
     */
    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
        User user = userRepository.findByUserId(userId)
                .orElseThrow(() -> {
                    log.debug("UserDetailsService - 사용자를 찾을 수 없음: {}", userId);
                    return new UsernameNotFoundException("사용자를 찾을 수 없습니다: " + userId);
                });

        // username에 userOid를 저장하여 SecurityContext에서 바로 사용 가능하게 한다
        return new org.springframework.security.core.userdetails.User(
                user.getOid(),
                user.getPassword(),
                List.of(new SimpleGrantedAuthority("ROLE_USER"))
        );
    }
}
