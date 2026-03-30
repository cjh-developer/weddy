package com.project.weddy.domain.attachment.repository;

import com.project.weddy.domain.attachment.entity.Attachment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * 첨부파일 데이터 접근 레이어.
 */
public interface AttachmentRepository extends JpaRepository<Attachment, String> {

    /**
     * ref 유형과 대상 OID로 첨부파일 목록을 생성일 오름차순으로 조회한다.
     *
     * @param refType 연결 유형 (ROADMAP_STEP | BUDGET)
     * @param refOid  연결 대상 OID
     * @return 첨부파일 목록
     */
    List<Attachment> findByRefTypeAndRefOidOrderByCreatedAtAsc(String refType, String refOid);

    /**
     * ref 유형과 대상 OID로 첨부파일 수를 반환한다.
     * 파일 개수 상한 검증에 사용한다.
     *
     * @param refType 연결 유형
     * @param refOid  연결 대상 OID
     * @return 첨부파일 수
     */
    long countByRefTypeAndRefOid(String refType, String refOid);

    /**
     * OID와 소유자 OID로 단건 조회한다.
     * 소유권 검증을 통해 IDOR를 방지한다.
     *
     * @param oid      첨부파일 OID
     * @param ownerOid 소유자 OID
     * @return 첨부파일 Optional
     */
    Optional<Attachment> findByOidAndOwnerOid(String oid, String ownerOid);

    /**
     * 연결 대상 OID로 첨부파일 목록을 조회한다.
     * 연쇄 삭제 시 물리 파일 삭제를 위해 storedName 목록이 필요하므로 List를 반환한다.
     *
     * @param refOid 연결 대상 OID
     * @return 첨부파일 목록
     */
    List<Attachment> findByRefOid(String refOid);

    /**
     * 연결 대상 OID에 속한 첨부파일 레코드를 전부 삭제한다.
     * 내부 연쇄 삭제 전용 메서드로, 물리 파일 삭제는 서비스 레이어에서 선행 처리해야 한다.
     *
     * @param refOid 연결 대상 OID
     */
    void deleteByRefOid(String refOid);
}
