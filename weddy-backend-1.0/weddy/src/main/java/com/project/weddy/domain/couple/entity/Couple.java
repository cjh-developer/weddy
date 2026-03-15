package com.project.weddy.domain.couple.entity;

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
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 커플 엔티티.
 * weddy_couples 테이블과 1:1 매핑된다.
 *
 * <p>PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 * groom_oid, bride_oid는 weddy_users.oid를 참조하되 FK 제약 없이 INDEX만 부여한다.
 */
@Entity
@Table(name = "weddy_couples")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Couple {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "groom_oid", length = 14)
    private String groomOid;

    @Column(name = "bride_oid", length = 14)
    private String brideOid;

    @Column(name = "wedding_date")
    private LocalDate weddingDate;

    @Column(name = "total_budget")
    private Long totalBudget;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    private void prePersist() {
        if (this.oid == null) {
            this.oid = OidGenerator.generate();
        }
    }
}
