package com.project.weddy.domain.checklist.entity;

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
 * 체크리스트 항목 엔티티.
 * weddy_checklist_items 테이블과 1:1 매핑된다.
 *
 * <p>PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 * checklist_oid는 weddy_checklists.oid를 참조하되 FK 제약 없이 INDEX만 부여한다.
 */
@Entity
@Table(name = "weddy_checklist_items")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChecklistItem {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "checklist_oid", length = 14, nullable = false)
    private String checklistOid;

    @Column(name = "content", length = 500, nullable = false)
    private String content;

    @Column(name = "is_done", nullable = false)
    private boolean isDone;

    @Column(name = "due_date")
    private LocalDate dueDate;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder;

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
     * 항목 내용, 완료 여부, 목표일, 정렬 순서를 부분 업데이트한다.
     * null인 필드는 기존 값을 유지한다.
     *
     * @param content   변경할 항목 내용 (null이면 유지)
     * @param isDone    완료 여부 (null이면 유지)
     * @param dueDate   목표 완료일 (null이면 유지)
     * @param sortOrder 정렬 순서 (null이면 유지)
     */
    public void update(String content, Boolean isDone, LocalDate dueDate, Integer sortOrder) {
        if (content != null) this.content = content;
        if (isDone != null) this.isDone = isDone;
        if (dueDate != null) this.dueDate = dueDate;
        if (sortOrder != null) this.sortOrder = sortOrder;
    }
}
