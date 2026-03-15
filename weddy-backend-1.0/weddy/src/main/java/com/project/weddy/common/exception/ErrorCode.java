package com.project.weddy.common.exception;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;

/**
 * 애플리케이션 전역 오류 코드 정의.
 * 각 항목은 클라이언트 전달용 code, 사람이 읽을 수 있는 message, HTTP 상태 코드를 포함한다.
 */
@Getter
@RequiredArgsConstructor
public enum ErrorCode {

    // 인증 / 인가
    UNAUTHORIZED("AUTH_001", "인증이 필요합니다.", HttpStatus.UNAUTHORIZED),
    INVALID_TOKEN("AUTH_002", "유효하지 않은 토큰입니다.", HttpStatus.UNAUTHORIZED),
    EXPIRED_TOKEN("AUTH_003", "만료된 토큰입니다.", HttpStatus.UNAUTHORIZED),

    // 사용자
    USER_NOT_FOUND("USER_001", "사용자를 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    DUPLICATE_USER_ID("USER_002", "이미 사용 중인 아이디입니다.", HttpStatus.CONFLICT),
    DUPLICATE_EMAIL("USER_003", "이미 사용 중인 이메일입니다.", HttpStatus.CONFLICT),

    // 커플
    COUPLE_NOT_FOUND("COUPLE_001", "커플 정보를 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    COUPLE_ALREADY_CONNECTED("COUPLE_002", "이미 연결된 커플입니다.", HttpStatus.CONFLICT),
    INVALID_INVITE_CODE("COUPLE_003", "유효하지 않은 초대 코드입니다.", HttpStatus.BAD_REQUEST),
    INVALID_COUPLE_ROLE("COUPLE_004", "같은 역할(신랑/신부)끼리는 연결할 수 없습니다.", HttpStatus.BAD_REQUEST),

    // 체크리스트
    CHECKLIST_NOT_FOUND("CHECKLIST_001", "체크리스트를 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    CHECKLIST_ITEM_NOT_FOUND("CHECKLIST_002", "체크리스트 항목을 찾을 수 없습니다.", HttpStatus.NOT_FOUND),

    // 공통
    VALIDATION_FAILED("COMMON_001", "입력값 검증에 실패했습니다.", HttpStatus.BAD_REQUEST),
    RATE_LIMIT_EXCEEDED("COMMON_429", "요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.", HttpStatus.TOO_MANY_REQUESTS),
    INTERNAL_SERVER_ERROR("COMMON_500", "서버 내부 오류가 발생했습니다.", HttpStatus.INTERNAL_SERVER_ERROR);

    private final String code;
    private final String message;
    private final HttpStatus httpStatus;
}
