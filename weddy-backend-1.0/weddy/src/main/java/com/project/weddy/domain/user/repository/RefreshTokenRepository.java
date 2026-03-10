package com.project.weddy.domain.user.repository;

import com.project.weddy.domain.user.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * 리프레시 토큰 데이터 접근 레이어.
 * 사용자 OID 기준으로 토큰을 조회하거나 삭제하는 메서드를 제공한다.
 */
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, String> {

    /**
     * 사용자 OID로 리프레시 토큰을 조회한다.
     *
     * @param userOid 사용자 엔티티 PK
     * @return 리프레시 토큰 Optional
     */
    Optional<RefreshToken> findByUserOid(String userOid);

    /**
     * 사용자 OID에 해당하는 리프레시 토큰을 삭제한다 (로그아웃 시 사용).
     *
     * @param userOid 사용자 엔티티 PK
     */
    void deleteByUserOid(String userOid);
}
