package com.project.weddy.common.response;

import lombok.Getter;
import org.springframework.data.domain.Page;

import java.util.List;

/**
 * Spring Data {@link Page}를 API 응답 형태로 변환하는 래퍼.
 * 클라이언트가 페이지네이션 메타데이터를 쉽게 소비할 수 있도록 평탄한 구조를 제공한다.
 *
 * @param <T> 페이지 내 개별 항목 타입
 */
@Getter
public class PageResponse<T> {

    private final List<T> content;
    private final long totalElements;
    private final int totalPages;
    private final int currentPage;
    private final int size;

    private PageResponse(Page<T> page) {
        this.content = page.getContent();
        this.totalElements = page.getTotalElements();
        this.totalPages = page.getTotalPages();
        this.currentPage = page.getNumber();
        this.size = page.getSize();
    }

    /**
     * Spring Data {@link Page} 객체로부터 {@link PageResponse}를 생성한다.
     *
     * @param page 변환할 페이지 객체
     * @param <T>  페이지 내 항목 타입
     * @return 변환된 {@link PageResponse}
     */
    public static <T> PageResponse<T> of(Page<T> page) {
        return new PageResponse<>(page);
    }
}
