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
    FORBIDDEN("AUTH_004", "접근 권한이 없습니다.", HttpStatus.FORBIDDEN),

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

    // 예산
    BUDGET_NOT_FOUND("BUDGET_001", "예산 카테고리를 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    BUDGET_ITEM_NOT_FOUND("BUDGET_002", "예산 항목을 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    // BUDGET_003: 솔로 허용 정책으로 미사용 — 하위 호환성을 위해 enum 항목은 유지
    BUDGET_COUPLE_REQUIRED("BUDGET_003", "예산 기능은 커플 연결 후 이용할 수 있습니다.", HttpStatus.FORBIDDEN),
    BUDGET_LIMIT_EXCEEDED("BUDGET_004", "예산 카테고리는 최대 20개까지 생성할 수 있습니다.", HttpStatus.BAD_REQUEST),

    // 업체 / 즐겨찾기
    VENDOR_NOT_FOUND("VENDOR_001", "업체를 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    FAVORITE_NOT_FOUND("FAVORITE_001", "즐겨찾기를 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    FAVORITE_ALREADY_EXISTS("FAVORITE_002", "이미 즐겨찾기한 업체입니다.", HttpStatus.CONFLICT),

    // 일정
    SCHEDULE_NOT_FOUND("SCHEDULE_001", "일정을 찾을 수 없습니다.", HttpStatus.NOT_FOUND),

    // 웨딩 관리 로드맵
    ROADMAP_STEP_NOT_FOUND("ROADMAP_001", "웨딩 관리 단계를 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    ROADMAP_HALL_TOUR_NOT_FOUND("ROADMAP_002", "투어 정보를 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    ROADMAP_STEP_LIMIT_EXCEEDED("ROADMAP_003", "웨딩 관리 단계는 최대 20개까지 생성할 수 있습니다.", HttpStatus.BAD_REQUEST),
    ROADMAP_TRAVEL_STOP_NOT_FOUND("ROADMAP_004", "경유지 정보를 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    ROADMAP_ALREADY_INITIALIZED("ROADMAP_005", "기본 로드맵이 이미 생성되어 있습니다.", HttpStatus.CONFLICT),
    ROADMAP_INVALID_STATUS("ROADMAP_006", "유효하지 않은 상태값입니다.", HttpStatus.BAD_REQUEST),
    ROADMAP_REORDER_INVALID("ROADMAP_007", "순서 변경 요청이 유효하지 않습니다.", HttpStatus.BAD_REQUEST),
    CUSTOM_ROADMAP_NOT_FOUND("ROADMAP_008", "직접 로드맵을 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    CUSTOM_ROADMAP_LIMIT_EXCEEDED("ROADMAP_009", "직접 로드맵은 최대 10개까지 생성할 수 있습니다.", HttpStatus.BAD_REQUEST),

    // 첨부파일
    ATTACHMENT_NOT_FOUND("ATTACHMENT_001", "첨부파일을 찾을 수 없습니다.", HttpStatus.NOT_FOUND),
    ATTACHMENT_LIMIT_EXCEEDED("ATTACHMENT_002", "첨부파일은 ref당 최대 20개까지 등록할 수 있습니다.", HttpStatus.BAD_REQUEST),
    ATTACHMENT_INVALID_TYPE("ATTACHMENT_003", "허용되지 않는 파일 형식입니다. (JPG/PNG/WEBP/PDF만 허용)", HttpStatus.BAD_REQUEST),
    ATTACHMENT_SIZE_EXCEEDED("ATTACHMENT_004", "파일 크기는 최대 20MB입니다.", HttpStatus.BAD_REQUEST),
    ATTACHMENT_IO_ERROR("ATTACHMENT_005", "파일 처리 중 오류가 발생했습니다.", HttpStatus.INTERNAL_SERVER_ERROR),

    // 공통
    VALIDATION_FAILED("COMMON_001", "입력값 검증에 실패했습니다.", HttpStatus.BAD_REQUEST),
    DUPLICATE_REQUEST("COMMON_409", "중복 요청입니다. 잠시 후 다시 시도해주세요.", HttpStatus.CONFLICT),
    RATE_LIMIT_EXCEEDED("COMMON_429", "요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.", HttpStatus.TOO_MANY_REQUESTS),
    INTERNAL_SERVER_ERROR("COMMON_500", "서버 내부 오류가 발생했습니다.", HttpStatus.INTERNAL_SERVER_ERROR);

    private final String code;
    private final String message;
    private final HttpStatus httpStatus;
}
