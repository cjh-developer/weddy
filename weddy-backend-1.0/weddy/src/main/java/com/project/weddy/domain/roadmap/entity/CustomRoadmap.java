package com.project.weddy.domain.roadmap.entity;

import com.project.weddy.common.util.OidGenerator;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * 직접 로드맵 컨테이너 엔티티.
 * weddy_custom_roadmaps 테이블과 1:1 매핑된다.
 *
 * <p>기본 로드맵(group_oid=NULL인 RoadmapStep)과 달리, 사용자가 자유롭게
 * 이름을 지정하여 생성하는 로드맵 그룹이다.
 * PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 */
@Entity
@Table(name = "weddy_custom_roadmaps")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomRoadmap {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    /**
     * 소유자 OID. 솔로 사용자이면 userOid, 커플이면 coupleOid.
     */
    @Column(name = "owner_oid", length = 14, nullable = false)
    private String ownerOid;

    /**
     * 사용자가 지정한 로드맵 이름.
     */
    @Column(name = "name", length = 100, nullable = false)
    private String name;

    /**
     * 화면 노출 순서. 생성 순서(count+1)로 자동 부여된다.
     */
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
     * 로드맵 이름을 변경한다.
     *
     * @param newName 새 로드맵 이름 (공백 불가, 100자 이하)
     */
    public void rename(String newName) {
        this.name = newName;
    }

    /**
     * 정렬 순서를 변경한다.
     *
     * @param sortOrder 새 정렬 순서
     */
    public void updateSortOrder(int sortOrder) {
        this.sortOrder = sortOrder;
    }
}
