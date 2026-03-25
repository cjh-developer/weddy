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

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 웨딩홀 투어 엔티티.
 * weddy_roadmap_hall_tours 테이블과 1:1 매핑된다.
 *
 * <p>step_oid는 weddy_roadmap_steps.oid를 참조하지만,
 * FK 제약 없이 INDEX만 부여한다.
 */
@Entity
@Table(name = "weddy_roadmap_hall_tours")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HallTour {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "step_oid", length = 14, nullable = false)
    private String stepOid;

    @Column(name = "hall_name", length = 100, nullable = false)
    private String hallName;

    @Column(name = "tour_date")
    private LocalDate tourDate;

    @Column(name = "location", length = 200)
    private String location;

    @Column(name = "rental_fee")
    private Long rentalFee;

    /** 식대 (1인당) */
    @Column(name = "meal_price")
    private Long mealPrice;

    /** 보증 인원 */
    @Column(name = "min_guests")
    private Integer minGuests;

    @Column(name = "memo", columnDefinition = "TEXT")
    private String memo;

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
