package com.project.weddy.domain.vendor.repository;

import com.project.weddy.domain.vendor.entity.Vendor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 웨딩 업체 데이터 접근 레이어.
 */
@Repository
public interface VendorRepository extends JpaRepository<Vendor, String> {

    /**
     * 카테고리와 키워드로 업체를 검색한다.
     *
     * <p>category가 null이면 전체 카테고리, keyword가 null이면 전체 업체명/주소를 대상으로 한다.
     * JPQL의 :category IS NULL 조건이 파라미터가 null인 경우 카테고리 필터를 건너뛰도록 동작한다.
     *
     * @param category 카테고리 필터 (HALL|STUDIO|DRESS|MAKEUP|HONEYMOON|ETC, null이면 전체)
     * @param keyword  업체명 또는 주소 검색어 (null이면 전체)
     * @return 조건에 맞는 업체 목록
     */
    @Query("SELECT v FROM Vendor v WHERE " +
           "(:category IS NULL OR v.category = :category) AND " +
           "(:keyword IS NULL OR v.name LIKE %:keyword% OR v.address LIKE %:keyword%) " +
           "ORDER BY v.category ASC, v.name ASC")
    List<Vendor> search(@Param("category") String category, @Param("keyword") String keyword);
}
