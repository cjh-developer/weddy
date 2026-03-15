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

import java.time.LocalDateTime;

/**
 * 체크리스트 엔티티.
 * weddy_checklists 테이블과 1:1 매핑된다.
 *
 * <p>PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 * couple_oid는 weddy_couples.oid를 참조하되 FK 제약 없이 INDEX만 부여한다.
 */
@Entity
@Table(name = "weddy_checklists")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Checklist {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "couple_oid", length = 14, nullable = false)
    private String coupleOid;

    @Column(name = "title", length = 100, nullable = false)
    private String title;

    @Column(name = "category", length = 50)
    private String category;

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
