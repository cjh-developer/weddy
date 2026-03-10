package com.project.weddy.domain.user.entity;

import com.project.weddy.common.util.OidGenerator;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * 리프레시 토큰 엔티티.
 * weddy_refresh_tokens 테이블과 1:1 매핑된다.
 *
 * <p>사용자 1명당 리프레시 토큰 1개(user_oid UNIQUE)를 유지한다.
 * 로그인 시 기존 토큰이 있으면 {@link #updateToken}으로 갱신하고, 없으면 새로 저장한다.
 */
@Entity
@Table(name = "weddy_refresh_tokens")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RefreshToken {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "user_oid", length = 14, nullable = false, unique = true)
    private String userOid;

    @Column(name = "token", length = 512, nullable = false)
    private String token;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * 영속화 직전에 oid가 없으면 자동 생성한다.
     */
    @PrePersist
    private void prePersist() {
        if (this.oid == null) {
            this.oid = OidGenerator.generate();
        }
    }

    /**
     * 기존 레코드의 토큰 값과 만료 일시를 갱신한다.
     * 로그인 재시도 시 upsert 로직에서 사용한다.
     *
     * @param newToken      새로운 리프레시 토큰 문자열
     * @param newExpiresAt  새로운 만료 일시
     */
    public void updateToken(String newToken, LocalDateTime newExpiresAt) {
        this.token = newToken;
        this.expiresAt = newExpiresAt;
    }
}
