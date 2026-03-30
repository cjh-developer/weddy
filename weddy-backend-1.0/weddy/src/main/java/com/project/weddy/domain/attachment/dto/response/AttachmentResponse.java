package com.project.weddy.domain.attachment.dto.response;

import com.project.weddy.domain.attachment.entity.Attachment;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

/**
 * 첨부파일 응답 DTO.
 *
 * <p>storedName, ownerOid, refOid 등 내부 식별자는 노출하지 않는다.
 */
@Getter
@Builder
public class AttachmentResponse {

    private String oid;
    private String originalName;
    private long fileSize;
    private String mimeType;
    private LocalDateTime createdAt;

    public static AttachmentResponse from(Attachment a) {
        return AttachmentResponse.builder()
                .oid(a.getOid())
                .originalName(a.getOriginalName())
                .fileSize(a.getFileSize())
                .mimeType(a.getMimeType())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
