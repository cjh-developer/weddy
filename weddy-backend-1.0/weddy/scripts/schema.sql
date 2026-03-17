-- ============================================================
-- Weddy Database Schema
-- DB: weddy
-- 규칙:
--   - PK: oid VARCHAR(14), 서버에서 SecureRandom 14자리 숫자 문자열 생성
--   - FK 제약 없음 (참조 무결성은 애플리케이션 레이어에서 관리)
--   - 관계 컬럼에는 INDEX를 부여하여 JOIN 성능을 유지
--   - 모든 테이블 charset: utf8mb4 / collate: utf8mb4_unicode_ci
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS weddy_couple_favorites;
DROP TABLE IF EXISTS weddy_budget_items;
DROP TABLE IF EXISTS weddy_budgets;
DROP TABLE IF EXISTS weddy_checklist_items;
DROP TABLE IF EXISTS weddy_checklists;
DROP TABLE IF EXISTS weddy_refresh_tokens;
DROP TABLE IF EXISTS weddy_couples;
DROP TABLE IF EXISTS weddy_vendors;
DROP TABLE IF EXISTS weddy_users;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 사용자
-- ============================================================
CREATE TABLE weddy_users (
    oid         VARCHAR(14)  NOT NULL               COMMENT 'SecureRandom 14자리 숫자 PK',
    user_id     VARCHAR(50)  NOT NULL               COMMENT '로그인 아이디',
    password    VARCHAR(255) NOT NULL               COMMENT 'BCrypt 해시 비밀번호',
    name        VARCHAR(50)  NOT NULL               COMMENT '이름',
    hand_phone  VARCHAR(20)  NULL                   COMMENT '휴대폰 번호',
    email       VARCHAR(100) NULL                   COMMENT '이메일',
    role        VARCHAR(10)  NOT NULL               COMMENT 'GROOM | BRIDE',
    invite_code  VARCHAR(20)  NULL                   COMMENT '커플 연결 초대코드',
    wedding_date DATE         NULL                   COMMENT '개인 설정 결혼 예정일',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    UNIQUE KEY uq_user_id     (user_id),
    UNIQUE KEY uq_email       (email),
    UNIQUE KEY uq_invite_code (invite_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='사용자';

-- ============================================================
-- 커플
-- ============================================================
CREATE TABLE weddy_couples (
    oid          VARCHAR(14) NOT NULL               COMMENT 'SecureRandom 14자리 숫자 PK',
    groom_oid    VARCHAR(14) NULL                   COMMENT '신랑 사용자 OID',
    bride_oid    VARCHAR(14) NULL                   COMMENT '신부 사용자 OID',
    wedding_date DATE        NULL                   COMMENT '예식일',
    total_budget BIGINT      NOT NULL DEFAULT 0     COMMENT '총 예산 (원)',
    created_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    UNIQUE KEY uq_groom_oid (groom_oid),
    UNIQUE KEY uq_bride_oid (bride_oid),
    INDEX idx_groom (groom_oid),
    INDEX idx_bride (bride_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='커플';

-- ============================================================
-- 체크리스트 카테고리
-- ============================================================
CREATE TABLE weddy_checklists (
    oid        VARCHAR(14)  NOT NULL               COMMENT 'SecureRandom 14자리 숫자 PK',
    owner_oid  VARCHAR(14)  NOT NULL               COMMENT '소유자 OID (솔로: 사용자 OID, 커플: 커플 OID)',
    title      VARCHAR(100) NOT NULL               COMMENT '체크리스트 제목',
    category   VARCHAR(50)  NULL                   COMMENT '카테고리 (HALL, BEAUTY, HONEYMOON 등)',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    INDEX idx_owner (owner_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='체크리스트';

-- ============================================================
-- 체크리스트 항목
-- ============================================================
CREATE TABLE weddy_checklist_items (
    oid           VARCHAR(14)  NOT NULL             COMMENT 'SecureRandom 14자리 숫자 PK',
    checklist_oid VARCHAR(14)  NOT NULL             COMMENT '체크리스트 OID',
    content       VARCHAR(500) NOT NULL             COMMENT '항목 내용',
    is_done       TINYINT(1)   NOT NULL DEFAULT 0   COMMENT '완료 여부 (0: 미완료, 1: 완료)',
    due_date      DATE         NULL                 COMMENT '목표 완료일',
    sort_order    INT          NOT NULL DEFAULT 0   COMMENT '정렬 순서',
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    INDEX idx_checklist (checklist_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='체크리스트 항목';

-- ============================================================
-- 예산 카테고리
-- ============================================================
CREATE TABLE weddy_budgets (
    oid            VARCHAR(14) NOT NULL             COMMENT 'SecureRandom 14자리 숫자 PK',
    owner_oid      VARCHAR(14) NOT NULL             COMMENT '소유자 OID (솔로: 사용자 OID, 커플: 커플 OID)',
    category       VARCHAR(50) NOT NULL             COMMENT '예산 카테고리명',
    planned_amount BIGINT      NOT NULL DEFAULT 0   COMMENT '계획 금액 (원)',
    created_at     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    INDEX idx_owner (owner_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='예산';

-- ============================================================
-- 예산 지출 항목
-- ============================================================
CREATE TABLE weddy_budget_items (
    oid        VARCHAR(14)  NOT NULL               COMMENT 'SecureRandom 14자리 숫자 PK',
    budget_oid VARCHAR(14)  NOT NULL               COMMENT '예산 카테고리 OID',
    title      VARCHAR(200) NOT NULL               COMMENT '지출 항목명',
    amount     BIGINT       NOT NULL               COMMENT '금액 (원)',
    paid_at    DATE         NULL                   COMMENT '지출일',
    memo       VARCHAR(500) NULL                   COMMENT '메모',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    INDEX idx_budget (budget_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='예산 지출 항목';

-- ============================================================
-- 웨딩 업체
-- ============================================================
CREATE TABLE weddy_vendors (
    oid          VARCHAR(14)  NOT NULL             COMMENT 'SecureRandom 14자리 숫자 PK',
    name         VARCHAR(100) NOT NULL             COMMENT '업체명',
    category     VARCHAR(20)  NOT NULL             COMMENT 'HALL | STUDIO | DRESS | MAKEUP | HONEYMOON | ETC',
    address      VARCHAR(300) NULL                 COMMENT '주소',
    phone        VARCHAR(20)  NULL                 COMMENT '전화번호',
    description  TEXT         NULL                 COMMENT '업체 설명',
    homepage_url VARCHAR(500) NULL                 COMMENT '홈페이지 URL',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='웨딩 업체';

-- ============================================================
-- 리프레시 토큰
-- ============================================================
CREATE TABLE weddy_refresh_tokens (
    oid        VARCHAR(14)  NOT NULL               COMMENT 'SecureRandom 14자리 숫자 PK',
    user_oid   VARCHAR(14)  NOT NULL               COMMENT '사용자 OID',
    token      VARCHAR(512) NOT NULL               COMMENT 'Refresh Token 값',
    expires_at DATETIME     NOT NULL               COMMENT '만료 일시',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    UNIQUE KEY uq_user_oid (user_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='리프레시 토큰';

-- ============================================================
-- 커플 즐겨찾기 업체 (N:M)
-- ============================================================
CREATE TABLE weddy_couple_favorites (
    couple_oid VARCHAR(14) NOT NULL               COMMENT '커플 OID',
    vendor_oid VARCHAR(14) NOT NULL               COMMENT '업체 OID',
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (couple_oid, vendor_oid),
    INDEX idx_vendor (vendor_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='커플 즐겨찾기 업체';
