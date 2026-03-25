package com.project.weddy.domain.schedule.entity;

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
 * 일정 엔티티.
 * weddy_schedules 테이블과 1:1 매핑된다.
 *
 * <p>PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 * 솔로 사용자는 owner_oid = 사용자 OID, 커플 연결 후에는 owner_oid = 커플 OID로 동작한다.
 * sourceType이 MANUAL이 아닌 경우 웨딩 관리 단계(로드맵)에서 자동 생성된 일정이다.
 * FK 제약 없이 INDEX만 부여한다.
 */
@Entity
@Table(name = "weddy_schedules")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Schedule {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "owner_oid", length = 14, nullable = false)
    private String ownerOid;

    @Column(name = "title", length = 100, nullable = false)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "category", length = 30, nullable = false)
    private String category;

    @Column(name = "is_all_day", nullable = false)
    private boolean isAllDay;

    @Column(name = "start_at", nullable = false)
    private LocalDateTime startAt;

    @Column(name = "end_at")
    private LocalDateTime endAt;

    @Column(name = "location", length = 200)
    private String location;

    /**
     * 알림 설정. 빈 문자열(없음) | 10MINUTES | 30MINUTES | 1HOUR | 1DAY | 3DAYS | 1WEEK
     */
    @Column(name = "alert_before", length = 20)
    private String alertBefore;

    /**
     * 일정 생성 출처. MANUAL | HALL_TOUR | DRESS | SANGGYEONRYE
     */
    @Column(name = "source_type", length = 20)
    private String sourceType;

    /**
     * 자동 생성 출처 OID (웨딩홀 투어 OID 등).
     * sourceType이 MANUAL이면 null이다.
     */
    @Column(name = "source_oid", length = 14)
    private String sourceOid;

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
     * 일정 정보를 부분 업데이트한다.
     * null인 필드는 기존 값을 유지한다.
     *
     * @param title       변경할 제목 (null이면 유지)
     * @param description 변경할 설명 (null이면 유지)
     * @param category    변경할 카테고리 (null이면 유지)
     * @param isAllDay    변경할 종일 여부 (null이면 유지)
     * @param startAt     변경할 시작 일시 (null이면 유지)
     * @param endAt       변경할 종료 일시 (null이면 유지)
     * @param location    변경할 장소 (null이면 유지)
     * @param alertBefore 변경할 알림 설정 (null이면 유지)
     */
    public void update(String title, String description, String category,
                       Boolean isAllDay, LocalDateTime startAt, LocalDateTime endAt,
                       String location, String alertBefore) {
        if (title != null) this.title = title;
        if (description != null) this.description = description;
        if (category != null) this.category = category;
        if (isAllDay != null) this.isAllDay = isAllDay;
        if (startAt != null) this.startAt = startAt;
        if (endAt != null) this.endAt = endAt;
        if (location != null) this.location = location;
        if (alertBefore != null) this.alertBefore = alertBefore;
    }
}
