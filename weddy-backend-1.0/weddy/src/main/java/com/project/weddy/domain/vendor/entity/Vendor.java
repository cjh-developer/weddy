package com.project.weddy.domain.vendor.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * 웨딩 업체 엔티티.
 * weddy_vendors 테이블과 1:1 매핑된다.
 *
 * <p>업체 정보는 관리자가 관리하므로 애플리케이션 레이어에서 수정 메서드를 노출하지 않는다.
 * PK(oid)는 데이터 삽입 시 외부에서 지정된다 (data.sql 또는 DataInitializer).
 */
@Entity
@Table(name = "weddy_vendors")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Vendor {

    @Id
    @Column(name = "oid", length = 14, nullable = false, updatable = false)
    private String oid;

    @Column(name = "name", length = 100, nullable = false)
    private String name;

    @Column(name = "category", length = 20, nullable = false)
    private String category;

    @Column(name = "address", length = 300)
    private String address;

    @Column(name = "phone", length = 20)
    private String phone;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "homepage_url", length = 500)
    private String homepageUrl;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
