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

/**
 * 항공권 경유지 엔티티.
 * weddy_roadmap_travel_stops 테이블과 1:1 매핑된다.
 *
 * <p>step_oid는 weddy_roadmap_steps.oid를 참조하지만,
 * FK 제약 없이 INDEX만 부여한다.
 */
@Entity
@Table(name = "weddy_roadmap_travel_stops")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TravelStop {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "step_oid", length = 14, nullable = false)
    private String stepOid;

    @Column(name = "stop_order", nullable = false)
    private int stopOrder;

    @Column(name = "city", length = 100, nullable = false)
    private String city;

    @PrePersist
    private void prePersist() {
        if (this.oid == null) {
            this.oid = OidGenerator.generate();
        }
    }
}
