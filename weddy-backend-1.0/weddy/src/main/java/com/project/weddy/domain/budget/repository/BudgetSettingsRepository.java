package com.project.weddy.domain.budget.repository;

import com.project.weddy.domain.budget.entity.BudgetSettings;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * 전체 예산 설정 레포지토리.
 * owner_oid당 최대 1개의 행만 존재한다 (UNIQUE KEY 보장).
 */
@Repository
public interface BudgetSettingsRepository extends JpaRepository<BudgetSettings, String> {

    /**
     * 소유자 OID로 예산 설정을 조회한다.
     *
     * @param ownerOid 소유자 OID
     * @return 예산 설정 (미설정이면 empty)
     */
    Optional<BudgetSettings> findByOwnerOid(String ownerOid);
}
