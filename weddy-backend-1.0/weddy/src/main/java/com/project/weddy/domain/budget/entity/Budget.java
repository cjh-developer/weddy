package com.project.weddy.domain.budget.entity;

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

import java.time.LocalDateTime;

/**
 * 예산 카테고리 엔티티.
 * weddy_budgets 테이블과 1:1 매핑된다.
 *
 * <p>PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 * 솔로 사용자는 owner_oid = 사용자 OID, 커플 연결 후에는 owner_oid = 커플 OID로 동작한다.
 * FK 제약 없이 INDEX만 부여한다.
 * spentAmount는 소속 항목의 amount 합산으로 서비스 레이어에서 계산한다.
 */
@Entity
@Table(name = "weddy_budgets")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Budget {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "owner_oid", length = 14, nullable = false)
    private String ownerOid;

    @Column(name = "category", length = 50, nullable = false)
    private String category;

    @Column(name = "planned_amount", nullable = false)
    private long plannedAmount;

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

    /**
     * 예산 계획 금액과 카테고리를 부분 업데이트한다.
     * null인 필드는 기존 값을 유지한다.
     *
     * @param category      변경할 카테고리명 (null이면 유지)
     * @param plannedAmount 변경할 계획 금액 (null이면 유지)
     */
    public void update(String category, Long plannedAmount) {
        if (category != null) this.category = category;
        if (plannedAmount != null) this.plannedAmount = plannedAmount;
    }
}
