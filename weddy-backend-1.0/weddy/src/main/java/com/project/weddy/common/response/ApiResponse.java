package com.project.weddy.common.response;

import lombok.Builder;
import lombok.Getter;

/**
 * 모든 API 응답의 표준 래퍼.
 * 성공/실패 여부와 관계없이 동일한 구조로 응답한다.
 *
 * @param <T> 응답 데이터 타입
 */
@Getter
@Builder
public class ApiResponse<T> {

    private final boolean success;
    private final String message;
    private final T data;
    private final String errorCode;

    /**
     * 데이터만 포함하는 성공 응답.
     */
    public static <T> ApiResponse<T> success(T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message("요청이 성공적으로 처리되었습니다.")
                .data(data)
                .build();
    }

    /**
     * 메시지와 데이터를 포함하는 성공 응답.
     */
    public static <T> ApiResponse<T> success(String message, T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .build();
    }

    /**
     * 데이터 없는 성공 응답 (예: 삭제 완료).
     */
    public static <T> ApiResponse<T> success(String message) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .build();
    }

    /**
     * 실패 응답.
     *
     * @param errorCode 오류 코드 문자열
     * @param message   사용자에게 노출할 오류 메시지
     */
    public static <T> ApiResponse<T> fail(String errorCode, String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .errorCode(errorCode)
                .message(message)
                .build();
    }
}
