package com.project.weddy.domain.guest.entity;

import com.project.weddy.common.util.OidGenerator;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * 하객 그룹 엔티티.
 * weddy_guest_groups 테이블과 1:1 매핑된다.
 *
 * <p>is_default=true 인 그룹은 삭제 불가 (애플리케이션 레이어에서 검증).
 * PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 */
@Entity
@Table(name = "weddy_guest_groups")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class GuestGroup {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "owner_oid", length = 14, nullable = false)
    private String ownerOid;

    @Column(name = "name", length = 50, nullable = false)
    private String name;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    private void prePersist() {
        if (this.oid == null) {
            this.oid = OidGenerator.generate();
        }
    }

    /** 그룹명을 변경한다. is_default 그룹은 서비스 레이어에서 별도로 검증한다. */
    public void updateName(String name) {
        this.name = name;
    }
}
