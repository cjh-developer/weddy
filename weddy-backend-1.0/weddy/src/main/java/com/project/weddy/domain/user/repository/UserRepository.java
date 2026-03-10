package com.project.weddy.domain.user.repository;

import com.project.weddy.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * 사용자 데이터 접근 레이어.
 * 로그인 아이디와 이메일 기반의 조회 및 중복 확인 메서드를 제공한다.
 */
public interface UserRepository extends JpaRepository<User, String> {

    /**
     * 로그인 아이디로 사용자를 조회한다.
     *
     * @param userId 로그인 아이디
     * @return 사용자 Optional
     */
    Optional<User> findByUserId(String userId);

    /**
     * 이메일로 사용자를 조회한다.
     *
     * @param email 이메일 주소
     * @return 사용자 Optional
     */
    Optional<User> findByEmail(String email);

    /**
     * 로그인 아이디 중복 여부를 확인한다.
     *
     * @param userId 로그인 아이디
     * @return 존재하면 true
     */
    boolean existsByUserId(String userId);

    /**
     * 이메일 중복 여부를 확인한다.
     *
     * @param email 이메일 주소
     * @return 존재하면 true
     */
    boolean existsByEmail(String email);

    /**
     * 초대 코드 중복 여부를 확인한다.
     * 회원가입 시 고유 초대 코드 생성에 사용한다.
     *
     * @param inviteCode 초대 코드 (예: "WED-A3KZ9P")
     * @return 존재하면 true
     */
    boolean existsByInviteCode(String inviteCode);
}
