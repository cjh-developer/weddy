package com.project.weddy.domain.user.entity;

import com.project.weddy.common.util.OidGenerator;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.security.SecureRandom;
import java.time.LocalDateTime;

/**
 * 사용자 엔티티.
 * weddy_users 테이블과 1:1 매핑된다.
 *
 * <p>PK(oid)는 {@link OidGenerator}를 통해 @PrePersist에서 자동 생성되며,
 * DB auto-increment를 사용하지 않는다.
 * invite_code는 커플 연결에 사용하는 고유 초대 코드이다.
 */
@Entity
@Table(name = "weddy_users")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();
    private static final String INVITE_CODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    private static final int INVITE_CODE_RANDOM_LENGTH = 6;

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "user_id", length = 50, nullable = false, unique = true)
    private String userId;

    @Column(name = "password", length = 255, nullable = false)
    private String password;

    @Column(name = "name", length = 50, nullable = false)
    private String name;

    @Column(name = "hand_phone", length = 20)
    private String handPhone;

    @Column(name = "email", length = 100, unique = true)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false, length = 10)
    private UserRole role;

    @Column(name = "invite_code", length = 20, unique = true)
    private String inviteCode;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /**
     * 영속화 직전에 oid가 없으면 자동 생성한다.
     * Builder 패턴으로 생성 시 oid를 명시하지 않아도 된다.
     */
    @PrePersist
    private void prePersist() {
        if (this.oid == null) {
            this.oid = OidGenerator.generate();
        }
    }

    /**
     * "WED-" + 6자리 대문자 영숫자(A-Z, 0-9) 형태의 초대 코드를 생성한다.
     * 예: "WED-A3KZ9P"
     *
     * @return 생성된 초대 코드
     */
    public static String generateInviteCode() {
        StringBuilder sb = new StringBuilder("WED-");
        for (int i = 0; i < INVITE_CODE_RANDOM_LENGTH; i++) {
            sb.append(INVITE_CODE_CHARS.charAt(SECURE_RANDOM.nextInt(INVITE_CODE_CHARS.length())));
        }
        return sb.toString();
    }
}
