package com.project.weddy.domain.guest.entity;

import com.project.weddy.common.util.OidGenerator;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * 하객 엔티티.
 * weddy_guests 테이블과 1:1 매핑된다.
 *
 * <p>owner_oid: 솔로=userOid, 커플=coupleOid (getOwnerOid() 패턴).
 * group_oid: NULL이면 그룹 미분류. 그룹 삭제 시 NULL로 초기화된다.
 * PK(oid)는 @PrePersist에서 OidGenerator로 자동 생성된다.
 */
@Entity
@Table(name = "weddy_guests")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Guest {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "owner_oid", length = 14, nullable = false)
    private String ownerOid;

    @Column(name = "group_oid", length = 14)
    private String groupOid;

    @Column(name = "name", length = 50, nullable = false)
    private String name;

    @Column(name = "companion_count", nullable = false)
    private int companionCount;

    @Column(name = "gift_amount", nullable = false)
    private long giftAmount;

    /** PAPER | MOBILE | NONE */
    @Column(name = "invitation_status", length = 10, nullable = false)
    private String invitationStatus;

    /** ATTEND | ABSENT | UNDECIDED */
    @Column(name = "attend_status", length = 15, nullable = false)
    private String attendStatus;

    @Column(name = "memo", length = 500)
    private String memo;

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
     * 하객 정보를 일괄 수정한다.
     * null 파라미터는 기존 값을 유지한다.
     *
     * @param groupOid         그룹 OID (null=유지, clearGroup=true이면 null로 설정)
     * @param clearGroup       true면 group_oid를 NULL로 초기화
     * @param name             이름 (null=유지)
     * @param companionCount   동반 인원 (null=유지)
     * @param giftAmount       축의금 (null=유지)
     * @param invitationStatus 청첩장 상태 (null=유지)
     * @param attendStatus     참석 여부 (null=유지)
     * @param memo             메모 (null=유지)
     */
    public void update(String groupOid, boolean clearGroup,
                       String name, Integer companionCount, Long giftAmount,
                       String invitationStatus, String attendStatus, String memo) {
        if (clearGroup) {
            this.groupOid = null;
        } else if (groupOid != null) {
            this.groupOid = groupOid;
        }
        if (name != null)             this.name = name;
        if (companionCount != null)   this.companionCount = companionCount;
        if (giftAmount != null)       this.giftAmount = giftAmount;
        if (invitationStatus != null) this.invitationStatus = invitationStatus;
        if (attendStatus != null)     this.attendStatus = attendStatus;
        if (memo != null)             this.memo = memo;
    }
}
