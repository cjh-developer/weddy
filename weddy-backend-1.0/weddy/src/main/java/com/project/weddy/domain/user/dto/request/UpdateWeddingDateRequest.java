package com.project.weddy.domain.user.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 결혼 예정일 설정/수정 요청 DTO.
 */
@Getter
@NoArgsConstructor
public class UpdateWeddingDateRequest {

    @NotNull(message = "결혼 예정일은 필수입니다.")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private LocalDate weddingDate;
}
