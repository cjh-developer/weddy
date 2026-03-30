package com.project.weddy.domain.attachment.entity;

import com.project.weddy.common.util.OidGenerator;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * 첨부파일(Vault) 엔티티.
 *
 * <p>refType + refOid 조합으로 로드맵 단계(ROADMAP_STEP) 또는 예산(BUDGET)에 연결된다.
 * storedName 은 UUID 기반으로 서버에서 생성하며, originalName 은 클라이언트가 전송한 원본 파일명이다.
 */
@Entity
@Table(name = "weddy_attachments")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Attachment {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "owner_oid", length = 14, nullable = false)
    private String ownerOid;

    /** 연결 대상 유형 — ROADMAP_STEP | BUDGET */
    @Column(name = "ref_type", length = 20, nullable = false)
    private String refType;

    /** 연결 대상 OID */
    @Column(name = "ref_oid", length = 14, nullable = false)
    private String refOid;

    /** 클라이언트가 전송한 원본 파일명 */
    @Column(name = "original_name", length = 255, nullable = false)
    private String originalName;

    /** 서버에 실제로 저장된 파일명 (UUID + 확장자) */
    @Column(name = "stored_name", length = 40, nullable = false)
    private String storedName;

    @Column(name = "file_size", nullable = false)
    private long fileSize;

    @Column(name = "mime_type", length = 100, nullable = false)
    private String mimeType;

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
