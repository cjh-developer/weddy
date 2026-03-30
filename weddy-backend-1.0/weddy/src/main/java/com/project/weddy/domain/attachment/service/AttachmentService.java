package com.project.weddy.domain.attachment.service;

import com.project.weddy.common.exception.CustomException;
import com.project.weddy.common.exception.ErrorCode;
import com.project.weddy.domain.attachment.dto.response.AttachmentResponse;
import com.project.weddy.domain.attachment.entity.Attachment;
import com.project.weddy.domain.attachment.repository.AttachmentRepository;
import com.project.weddy.domain.budget.repository.BudgetRepository;
import com.project.weddy.domain.roadmap.repository.RoadmapStepRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;

/**
 * 첨부파일(Vault) 서비스.
 *
 * <p>파일 업로드 시 MIME 타입 헤더 검증 + 매직 넘버 이중 검증을 수행한다.
 * refOid 소유권 검증을 통해 IDOR를 방지한다.
 *
 * <p>순환 의존성 방지: BudgetService 를 주입받지 않고 BudgetRepository 를 직접 사용한다.
 * BudgetService 와 RoadmapService 는 본 서비스를 단방향으로 의존한다.
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class AttachmentService {

    private static final long MAX_FILE_SIZE = 20L * 1024 * 1024; // 20MB
    private static final int MAX_PER_REF = 20;
    private static final List<String> ALLOWED_MIME = List.of(
            "image/jpeg", "image/png", "image/webp", "application/pdf"
    );

    private final AttachmentRepository attachmentRepository;
    private final BudgetRepository budgetRepository;
    private final RoadmapStepRepository roadmapStepRepository;
    private final Path uploadPath;

    // -----------------------------------------------------------------------
    // 업로드
    // -----------------------------------------------------------------------

    /**
     * 파일을 업로드하고 첨부파일 레코드를 생성한다.
     *
     * <p>검증 순서:
     * <ol>
     *   <li>파일 크기 (20MB 이하)</li>
     *   <li>MIME 타입 헤더 (JPG/PNG/WEBP/PDF)</li>
     *   <li>매직 넘버 (파일 실제 바이너리 헤더)</li>
     *   <li>ref 당 파일 개수 (20개 이하)</li>
     *   <li>refOid 소유권 (IDOR 방지)</li>
     * </ol>
     *
     * @param userOid  현재 사용자 OID
     * @param ownerOid 소유자 OID (커플 OID 또는 사용자 OID)
     * @param refType  연결 유형 (ROADMAP_STEP | BUDGET)
     * @param refOid   연결 대상 OID
     * @param file     업로드 파일
     * @return 생성된 첨부파일 응답
     * @throws IOException            파일 I/O 오류
     * @throws CustomException        검증 실패 시
     */
    public AttachmentResponse upload(String userOid, String ownerOid,
                                     String refType, String refOid,
                                     MultipartFile file) throws IOException {
        // 1) 파일 크기
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new CustomException(ErrorCode.ATTACHMENT_SIZE_EXCEEDED);
        }

        // 2) MIME 타입 헤더
        String mime = file.getContentType();
        if (mime == null || !ALLOWED_MIME.contains(mime)) {
            throw new CustomException(ErrorCode.ATTACHMENT_INVALID_TYPE);
        }

        // 3) 매직 넘버 검증 — Content-Type 스푸핑 방지
        validateMagicBytes(file, mime);

        // 4) refOid 소유권 검증 (IDOR 방지) — 개수 제한보다 먼저 수행하여 오라클 노출 차단
        validateRefOwnership(refType, refOid, ownerOid);

        // 5) ref 당 파일 개수 제한
        if (attachmentRepository.countByRefTypeAndRefOid(refType, refOid) >= MAX_PER_REF) {
            throw new CustomException(ErrorCode.ATTACHMENT_LIMIT_EXCEEDED);
        }

        // 6) 디스크 저장
        String ext = getExtension(mime);
        String storedName = UUID.randomUUID().toString().replace("-", "") + ext;
        Path dest = uploadPath.resolve(storedName);
        Files.copy(file.getInputStream(), dest, StandardCopyOption.REPLACE_EXISTING);

        String originalName = (file.getOriginalFilename() != null && !file.getOriginalFilename().isBlank())
                ? file.getOriginalFilename() : "file";

        Attachment attachment = Attachment.builder()
                .ownerOid(ownerOid)
                .refType(refType)
                .refOid(refOid)
                .originalName(originalName)
                .storedName(storedName)
                .fileSize(file.getSize())
                .mimeType(mime)
                .build();
        attachmentRepository.save(attachment);
        log.info("첨부파일 업로드 - oid: {}, refType: {}, refOid: {}", attachment.getOid(), refType, refOid);
        return AttachmentResponse.from(attachment);
    }

    // -----------------------------------------------------------------------
    // 목록 조회
    // -----------------------------------------------------------------------

    /**
     * 특정 ref 의 첨부파일 목록을 생성일 오름차순으로 반환한다.
     * ownerOid 소유권 검증 후 목록을 반환하여 IDOR를 방지한다.
     *
     * @param refType  연결 유형
     * @param refOid   연결 대상 OID
     * @param ownerOid 소유자 OID (검증용)
     * @return 첨부파일 응답 목록
     */
    @Transactional(readOnly = true)
    public List<AttachmentResponse> list(String refType, String refOid, String ownerOid) {
        validateRefOwnership(refType, refOid, ownerOid);
        return attachmentRepository
                .findByRefTypeAndRefOidOrderByCreatedAtAsc(refType, refOid)
                .stream()
                .map(AttachmentResponse::from)
                .toList();
    }

    // -----------------------------------------------------------------------
    // 다운로드
    // -----------------------------------------------------------------------

    /**
     * 첨부파일을 다운로드한다.
     * ownerOid 검증으로 타인 파일 접근을 차단한다.
     *
     * @param userOid  현재 사용자 OID (미사용, 향후 감사 로그용)
     * @param ownerOid 소유자 OID
     * @param oid      첨부파일 OID
     * @return 다운로드 결과 (Resource + 파일명 + MIME)
     * @throws CustomException ATTACHMENT_NOT_FOUND / ATTACHMENT_IO_ERROR
     */
    @Transactional(readOnly = true)
    public DownloadResult download(String userOid, String ownerOid, String oid) {
        Attachment attachment = attachmentRepository.findByOidAndOwnerOid(oid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.ATTACHMENT_NOT_FOUND));
        try {
            Path filePath = uploadPath.resolve(attachment.getStoredName()).normalize();
            Resource resource = new UrlResource(filePath.toUri());
            if (!resource.exists()) {
                log.warn("물리 파일 없음 - oid: {}, storedName: {}", oid, attachment.getStoredName());
                throw new CustomException(ErrorCode.ATTACHMENT_NOT_FOUND);
            }
            return new DownloadResult(resource, attachment.getOriginalName(), attachment.getMimeType());
        } catch (MalformedURLException e) {
            log.error("다운로드 URL 생성 오류 - oid: {}", oid, e);
            throw new CustomException(ErrorCode.ATTACHMENT_IO_ERROR);
        }
    }

    // -----------------------------------------------------------------------
    // 삭제
    // -----------------------------------------------------------------------

    /**
     * 첨부파일을 삭제한다.
     * ownerOid 검증 후 물리 파일과 레코드를 함께 제거한다.
     *
     * @param userOid  현재 사용자 OID (미사용, 향후 감사 로그용)
     * @param ownerOid 소유자 OID
     * @param oid      삭제할 첨부파일 OID
     * @throws CustomException ATTACHMENT_NOT_FOUND
     */
    public void delete(String userOid, String ownerOid, String oid) {
        Attachment attachment = attachmentRepository.findByOidAndOwnerOid(oid, ownerOid)
                .orElseThrow(() -> new CustomException(ErrorCode.ATTACHMENT_NOT_FOUND));
        deletePhysicalFile(attachment.getStoredName());
        attachmentRepository.deleteById(oid);
        log.info("첨부파일 삭제 - oid: {}", oid);
    }

    /**
     * refOid 에 연결된 모든 첨부파일을 삭제한다.
     *
     * <p><b>내부 연쇄 삭제 전용 메서드</b> — ownerOid 조건 없이 동작하므로
     * 반드시 상위 소유권 검증이 완료된 이후에만 호출해야 한다.
     * (RoadmapService.deleteStep(), BudgetService.deleteBudget() 에서 호출)
     *
     * @param refOid 연결 대상 OID
     */
    public void deleteByRefOid(String refOid) {
        List<Attachment> attachments = attachmentRepository.findByRefOid(refOid);
        attachments.forEach(a -> deletePhysicalFile(a.getStoredName()));
        attachmentRepository.deleteByRefOid(refOid);
        if (!attachments.isEmpty()) {
            log.info("연쇄 첨부파일 삭제 - refOid: {}, count: {}", refOid, attachments.size());
        }
    }

    // -----------------------------------------------------------------------
    // private helpers
    // -----------------------------------------------------------------------

    /**
     * MIME 타입에 맞는 매직 넘버(파일 시그니처)를 검증한다.
     * Content-Type 헤더 위조를 통한 악성 파일 업로드를 방지한다.
     */
    private void validateMagicBytes(MultipartFile file, String mime) throws IOException {
        try (InputStream is = file.getInputStream()) {
            byte[] header = is.readNBytes(12);
            boolean valid = switch (mime) {
                case "image/jpeg" -> header.length >= 3
                        && (header[0] & 0xFF) == 0xFF
                        && (header[1] & 0xFF) == 0xD8
                        && (header[2] & 0xFF) == 0xFF;
                case "image/png" -> header.length >= 8
                        && (header[0] & 0xFF) == 0x89
                        && (header[1] & 0xFF) == 0x50  // P
                        && (header[2] & 0xFF) == 0x4E  // N
                        && (header[3] & 0xFF) == 0x47  // G
                        && (header[4] & 0xFF) == 0x0D
                        && (header[5] & 0xFF) == 0x0A
                        && (header[6] & 0xFF) == 0x1A
                        && (header[7] & 0xFF) == 0x0A;
                case "image/webp" -> header.length >= 12
                        && (header[0] & 0xFF) == 0x52  // R
                        && (header[1] & 0xFF) == 0x49  // I
                        && (header[2] & 0xFF) == 0x46  // F
                        && (header[3] & 0xFF) == 0x46  // F
                        && (header[8] & 0xFF) == 0x57  // W
                        && (header[9] & 0xFF) == 0x45  // E
                        && (header[10] & 0xFF) == 0x42 // B
                        && (header[11] & 0xFF) == 0x50; // P
                case "application/pdf" -> header.length >= 4
                        && (header[0] & 0xFF) == 0x25  // %
                        && (header[1] & 0xFF) == 0x50  // P
                        && (header[2] & 0xFF) == 0x44  // D
                        && (header[3] & 0xFF) == 0x46; // F
                default -> false;
            };
            if (!valid) {
                throw new CustomException(ErrorCode.ATTACHMENT_INVALID_TYPE);
            }
        }
    }

    /**
     * refType 과 refOid 기반으로 소유권을 검증한다.
     * 해당 리소스가 ownerOid 소유가 아니면 ATTACHMENT_NOT_FOUND 예외를 발생시킨다.
     * (403 대신 404를 반환하여 존재 자체를 노출하지 않음)
     */
    private void validateRefOwnership(String refType, String refOid, String ownerOid) {
        boolean owned = switch (refType) {
            case "BUDGET" -> budgetRepository.findById(refOid)
                    .map(b -> b.getOwnerOid().equals(ownerOid))
                    .orElse(false);
            case "ROADMAP_STEP" -> roadmapStepRepository.findById(refOid)
                    .map(s -> s.getOwnerOid().equals(ownerOid))
                    .orElse(false);
            default -> false;
        };
        if (!owned) {
            throw new CustomException(ErrorCode.ATTACHMENT_NOT_FOUND);
        }
    }

    /** 물리 파일을 삭제한다. 실패 시 경고 로그만 남기고 계속 진행한다. */
    private void deletePhysicalFile(String storedName) {
        try {
            Path filePath = uploadPath.resolve(storedName).normalize();
            Files.deleteIfExists(filePath);
        } catch (IOException e) {
            log.warn("물리 파일 삭제 실패 - storedName: {}, exceptionType: {}",
                    storedName, e.getClass().getSimpleName());
        }
    }

    /** MIME 타입에 대응하는 파일 확장자를 반환한다. */
    private String getExtension(String mime) {
        return switch (mime) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            case "application/pdf" -> ".pdf";
            default -> "";
        };
    }

    /**
     * 파일 다운로드 결과를 담는 레코드.
     *
     * @param resource     Spring Resource (스트림 제공)
     * @param originalName 클라이언트에 전달할 원본 파일명
     * @param mimeType     Content-Type 헤더값
     */
    public record DownloadResult(Resource resource, String originalName, String mimeType) {}
}
