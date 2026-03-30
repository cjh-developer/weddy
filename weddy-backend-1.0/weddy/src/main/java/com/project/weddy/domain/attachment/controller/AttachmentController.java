package com.project.weddy.domain.attachment.controller;

import com.project.weddy.common.response.ApiResponse;
import com.project.weddy.domain.attachment.dto.response.AttachmentResponse;
import com.project.weddy.domain.attachment.service.AttachmentService;
import com.project.weddy.domain.couple.entity.Couple;
import com.project.weddy.domain.couple.repository.CoupleRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * 첨부파일(Vault) API 컨트롤러.
 *
 * <p>엔드포인트:
 * <ul>
 *   <li>POST   /api/v1/attachments          — 파일 업로드</li>
 *   <li>GET    /api/v1/attachments          — 목록 조회 (refType + refOid 쿼리 파라미터)</li>
 *   <li>GET    /api/v1/attachments/{oid}/download — 파일 다운로드</li>
 *   <li>DELETE /api/v1/attachments/{oid}    — 파일 삭제</li>
 * </ul>
 *
 * <p>getOwnerOid() 는 BudgetController / RoadmapController 와 동일한 커플/솔로 분기 패턴을 사용한다.
 */
@Tag(name = "Attachment", description = "첨부파일(Vault) API")
@RestController
@RequestMapping("/api/v1/attachments")
@RequiredArgsConstructor
@Validated
public class AttachmentController {

    private final AttachmentService attachmentService;
    private final CoupleRepository coupleRepository;

    @Operation(summary = "파일 업로드",
               description = "refType(ROADMAP_STEP|BUDGET)과 refOid를 지정하여 파일을 업로드한다. " +
                             "JPG/PNG/WEBP/PDF만 허용, ref당 최대 20개, 최대 20MB.")
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<AttachmentResponse>> upload(
            @AuthenticationPrincipal String userOid,
            @RequestParam @Pattern(regexp = "ROADMAP_STEP|BUDGET") String refType,
            @RequestParam String refOid,
            @RequestParam("file") MultipartFile file) throws IOException {

        String ownerOid = getOwnerOid(userOid);
        AttachmentResponse response = attachmentService.upload(userOid, ownerOid, refType, refOid, file);
        return ResponseEntity.ok(ApiResponse.success("파일이 업로드되었습니다.", response));
    }

    @Operation(summary = "첨부파일 목록 조회",
               description = "refType과 refOid에 연결된 첨부파일 목록을 생성일 오름차순으로 반환한다.")
    @GetMapping
    public ResponseEntity<ApiResponse<List<AttachmentResponse>>> list(
            @AuthenticationPrincipal String userOid,
            @RequestParam @Pattern(regexp = "ROADMAP_STEP|BUDGET") String refType,
            @RequestParam String refOid) {

        String ownerOid = getOwnerOid(userOid);
        List<AttachmentResponse> list = attachmentService.list(refType, refOid, ownerOid);
        return ResponseEntity.ok(ApiResponse.success("첨부파일 목록입니다.", list));
    }

    @Operation(summary = "파일 다운로드",
               description = "첨부파일 OID로 파일을 다운로드한다. 소유자만 접근 가능하다.")
    @GetMapping("/{oid}/download")
    public ResponseEntity<org.springframework.core.io.Resource> download(
            @AuthenticationPrincipal String userOid,
            @PathVariable String oid) {

        String ownerOid = getOwnerOid(userOid);
        AttachmentService.DownloadResult result = attachmentService.download(userOid, ownerOid, oid);

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(result.mimeType()))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment()
                                .filename(result.originalName(), StandardCharsets.UTF_8)
                                .build()
                                .toString())
                .body(result.resource());
    }

    @Operation(summary = "첨부파일 삭제",
               description = "첨부파일 OID로 파일을 삭제한다. 소유자만 삭제 가능하다.")
    @DeleteMapping("/{oid}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @AuthenticationPrincipal String userOid,
            @PathVariable String oid) {

        String ownerOid = getOwnerOid(userOid);
        attachmentService.delete(userOid, ownerOid, oid);
        return ResponseEntity.ok(ApiResponse.success("첨부파일이 삭제되었습니다.", null));
    }

    /**
     * 커플에 연결된 사용자는 커플 OID를, 솔로 사용자는 사용자 OID를 반환한다.
     * Budget/RoadmapController 와 동일한 getOwnerOid() 패턴.
     */
    private String getOwnerOid(String userOid) {
        return coupleRepository.findByGroomOidOrBrideOid(userOid, userOid)
                .map(Couple::getOid)
                .orElse(userOid);
    }
}
