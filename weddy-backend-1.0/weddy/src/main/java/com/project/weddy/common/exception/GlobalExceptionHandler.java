package com.project.weddy.common.exception;

import com.project.weddy.common.response.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.stream.Collectors;

/**
 * 전역 예외 처리 핸들러.
 * 모든 컨트롤러에서 발생하는 예외를 가로채어 일관된 {@link ApiResponse} 형태로 변환한다.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * 비즈니스 로직 예외 처리.
     * {@link CustomException}에 담긴 {@link ErrorCode}를 그대로 클라이언트에 반환한다.
     */
    @ExceptionHandler(CustomException.class)
    public ResponseEntity<ApiResponse<Void>> handleCustomException(CustomException ex) {
        log.warn("[CustomException] code={}, message={}", ex.getErrorCode().getCode(), ex.getMessage());
        ErrorCode errorCode = ex.getErrorCode();
        return ResponseEntity
                .status(errorCode.getHttpStatus())
                .body(ApiResponse.fail(errorCode.getCode(), ex.getMessage()));
    }

    /**
     * Bean Validation(@Valid) 실패 처리.
     * 검증에 실패한 모든 필드의 메시지를 콤마로 연결하여 반환한다.
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidationException(MethodArgumentNotValidException ex) {
        String details = ex.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining(", "));

        log.warn("[ValidationException] details={}", details);

        ErrorCode errorCode = ErrorCode.VALIDATION_FAILED;
        String message = errorCode.getMessage() + " (" + details + ")";

        return ResponseEntity
                .status(errorCode.getHttpStatus())
                .body(ApiResponse.fail(errorCode.getCode(), message));
    }

    /**
     * DB UNIQUE 제약 위반 처리.
     * 동시 요청으로 인한 중복 INSERT 등 데이터 무결성 위반 시 409 Conflict를 반환한다.
     * 도메인에 무관하게 범용 에러코드(COMMON_409)를 사용하여 커플·예산 설정 등 모든 케이스를 포괄한다.
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleDataIntegrityViolation(DataIntegrityViolationException ex) {
        log.warn("[DataIntegrityViolationException] {}", ex.getMessage());
        ErrorCode errorCode = ErrorCode.DUPLICATE_REQUEST;
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(ApiResponse.fail(errorCode.getCode(), errorCode.getMessage()));
    }

    /**
     * 처리되지 않은 모든 예외에 대한 최후 방어선.
     * 500 Internal Server Error를 반환하고 스택 트레이스를 ERROR 레벨로 기록한다.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleException(Exception ex) {
        log.error("[UnhandledException] {}", ex.getMessage(), ex);
        ErrorCode errorCode = ErrorCode.INTERNAL_SERVER_ERROR;
        return ResponseEntity
                .status(errorCode.getHttpStatus())
                .body(ApiResponse.fail(errorCode.getCode(), errorCode.getMessage()));
    }
}
