package com.project.weddy.domain.vendor.entity;

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
 * 업체 즐겨찾기 엔티티.
 * weddy_favorites 테이블과 1:1 매핑된다.
 *
 * <p>솔로 사용자는 owner_oid = 사용자 OID, 커플 연결 후에는 owner_oid = 커플 OID로 동작한다.
 * (owner_oid, vendor_oid) 조합에 UNIQUE 제약이 있으므로 중복 즐겨찾기를 DB 레벨에서도 방지한다.
 * PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 */
@Entity
@Table(name = "weddy_favorites")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Favorite {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "owner_oid", length = 14, nullable = false)
    private String ownerOid;

    @Column(name = "vendor_oid", length = 14, nullable = false)
    private String vendorOid;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    private void prePersist() {
        if (this.oid == null) {
            this.oid = OidGenerator.generate();
        }
    }
}
