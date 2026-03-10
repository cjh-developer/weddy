package com.project.weddy.common.exception;

import lombok.Getter;

/**
 * 비즈니스 로직 오류를 표현하는 최상위 예외 클래스.
 * {@link ErrorCode}를 통해 오류 코드, 메시지, HTTP 상태를 함께 전달한다.
 *
 * <p>사용 예:
 * <pre>
 *     throw new CustomException(ErrorCode.USER_NOT_FOUND);
 * </pre>
 */
@Getter
public class CustomException extends RuntimeException {

    private final ErrorCode errorCode;

    public CustomException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }

    public CustomException(ErrorCode errorCode, String detailMessage) {
        super(detailMessage);
        this.errorCode = errorCode;
    }
}
