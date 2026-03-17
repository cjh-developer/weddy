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

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 예산 항목 엔티티.
 * weddy_budget_items 테이블과 1:1 매핑된다.
 *
 * <p>PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 * budget_oid는 weddy_budgets.oid를 참조하되 FK 제약 없이 INDEX만 부여한다.
 * paid_at은 실제 결제(지출) 날짜를 의미한다.
 */
@Entity
@Table(name = "weddy_budget_items")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BudgetItem {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "budget_oid", length = 14, nullable = false)
    private String budgetOid;

    @Column(name = "title", length = 200, nullable = false)
    private String title;

    @Column(name = "amount", nullable = false)
    private long amount;

    @Column(name = "memo", length = 500)
    private String memo;

    @Column(name = "paid_at")
    private LocalDate paidAt;

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
     * 예산 항목을 부분 업데이트한다.
     * null인 필드는 기존 값을 유지한다.
     *
     * @param title  변경할 항목명 (null이면 유지)
     * @param amount 변경할 금액 (null이면 유지)
     * @param memo   변경할 메모 (null이면 유지)
     * @param paidAt 변경할 결제일 (null이면 유지)
     */
    public void update(String title, Long amount, String memo, LocalDate paidAt) {
        if (title != null) this.title = title;
        if (amount != null) this.amount = amount;
        if (memo != null) this.memo = memo;
        if (paidAt != null) this.paidAt = paidAt;
    }
}
