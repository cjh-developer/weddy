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
 * 전체 예산 설정 엔티티.
 * weddy_budget_settings 테이블과 1:1 매핑된다.
 *
 * <p>소유자(owner_oid)당 1개의 행만 존재한다 (UNIQUE KEY 보장).
 * 솔로 사용자는 owner_oid = 사용자 OID, 커플 연결 후에는 owner_oid = 커플 OID로 동작한다.
 */
@Entity
@Table(name = "weddy_budget_settings")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BudgetSettings {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "owner_oid", length = 14, nullable = false, unique = true)
    private String ownerOid;

    @Column(name = "total_amount", nullable = false)
    private long totalAmount;

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
     * 전체 예산 금액을 갱신한다.
     * Long 박싱 타입을 받아 null 전달 시 NPE 대신 IllegalArgumentException으로 명시적 실패 처리한다.
     *
     * @param totalAmount 새 전체 예산 금액 (1원 이상, null 불가)
     * @throws IllegalArgumentException totalAmount가 null이거나 1 미만인 경우
     */
    public void updateTotalAmount(Long totalAmount) {
        if (totalAmount == null || totalAmount < 1) {
            throw new IllegalArgumentException("전체 예산은 1원 이상이어야 합니다.");
        }
        this.totalAmount = totalAmount;
    }
}
