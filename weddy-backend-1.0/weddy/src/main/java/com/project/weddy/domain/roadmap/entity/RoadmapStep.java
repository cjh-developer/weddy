package com.project.weddy.domain.roadmap.entity;

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
 * 웨딩 로드맵 단계 엔티티.
 * weddy_roadmap_steps 테이블과 1:1 매핑된다.
 *
 * <p>PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 * details 필드는 단계별 특화 데이터를 JSON 문자열로 저장한다.
 * FK 제약 없이 INDEX만 부여한다.
 */
@Entity
@Table(name = "weddy_roadmap_steps")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoadmapStep {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "owner_oid", length = 14, nullable = false)
    private String ownerOid;

    /**
     * 단계 유형. BUDGET | HALL | PLANNER | DRESS | HOME | TRAVEL | GIFT | SANGGYEONRYE | ETC
     */
    @Column(name = "step_type", length = 30, nullable = false)
    private String stepType;

    @Column(name = "title", length = 100, nullable = false)
    private String title;

    @Column(name = "is_done", nullable = false)
    private boolean isDone;

    @Column(name = "due_date")
    private LocalDate dueDate;

    @Column(name = "has_due_date", nullable = false)
    private boolean hasDueDate;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

    /**
     * 단계별 특화 데이터 (JSON 문자열).
     * 예: BUDGET → {"totalBudget":50000000}, HALL → {"totalFee":0,"guestCount":0}
     */
    @Column(name = "details", columnDefinition = "TEXT")
    private String details;

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
     * 단계 정보를 부분 업데이트한다.
     * null인 필드는 기존 값을 유지한다. clearDueDate=true이면 dueDate를 명시적으로 null로 설정한다.
     *
     * @param title        변경할 제목 (null이면 유지)
     * @param isDone       변경할 완료 여부 (null이면 유지)
     * @param dueDate      변경할 목표일 (null이면 유지, clearDueDate=true이면 null로 삭제)
     * @param hasDueDate   변경할 목표일 활성화 여부 (null이면 유지)
     * @param details      변경할 상세 JSON (null이면 유지)
     * @param clearDueDate true이면 dueDate를 null로 삭제한다
     */
    public void update(String title, Boolean isDone, LocalDate dueDate,
                       Boolean hasDueDate, String details, boolean clearDueDate) {
        if (title != null) this.title = title;
        if (isDone != null) this.isDone = isDone;
        if (clearDueDate) {
            this.dueDate = null;
        } else if (dueDate != null) {
            this.dueDate = dueDate;
        }
        if (hasDueDate != null) this.hasDueDate = hasDueDate;
        if (details != null) this.details = details;
    }

    /**
     * 완료 여부를 토글한다.
     */
    public void toggleDone() {
        this.isDone = !this.isDone;
    }
}
