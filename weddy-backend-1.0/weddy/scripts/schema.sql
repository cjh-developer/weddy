-- ============================================================
-- Weddy Database Schema
-- DB: weddy_db
-- 규칙: PK는 oid VARCHAR(14) (서버 생성 14자리 숫자 문자열)
-- ============================================================

-- 사용자
CREATE TABLE IF NOT EXISTS weddy_users (
    oid          VARCHAR(14)  NOT NULL,
    user_id      VARCHAR(50)  NOT NULL,
    password     VARCHAR(255) NOT NULL,
    name         VARCHAR(50)  NOT NULL,
    hand_phone   VARCHAR(20)  NULL,
    email        VARCHAR(100) NULL,
    role         ENUM('GROOM', 'BRIDE') NOT NULL,
    invite_code  VARCHAR(20)  NULL,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    UNIQUE KEY uq_user_id    (user_id),
    UNIQUE KEY uq_email      (email),
    UNIQUE KEY uq_invite_code (invite_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 커플 (신랑 + 신부 연결)
CREATE TABLE IF NOT EXISTS weddy_couples (
    oid          VARCHAR(14) NOT NULL,
    groom_oid    VARCHAR(14) NULL,
    bride_oid    VARCHAR(14) NULL,
    wedding_date DATE        NULL,
    total_budget BIGINT      NOT NULL DEFAULT 0,
    created_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    CONSTRAINT fk_couple_groom FOREIGN KEY (groom_oid) REFERENCES weddy_users (oid) ON DELETE SET NULL,
    CONSTRAINT fk_couple_bride FOREIGN KEY (bride_oid) REFERENCES weddy_users (oid) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 체크리스트 (카테고리 단위 묶음)
CREATE TABLE IF NOT EXISTS weddy_checklists (
    oid         VARCHAR(14)  NOT NULL,
    couple_oid  VARCHAR(14)  NOT NULL,
    title       VARCHAR(100) NOT NULL,
    category    VARCHAR(50)  NULL,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    CONSTRAINT fk_checklist_couple FOREIGN KEY (couple_oid) REFERENCES weddy_couples (oid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 체크리스트 항목
CREATE TABLE IF NOT EXISTS weddy_checklist_items (
    oid            VARCHAR(14)  NOT NULL,
    checklist_oid  VARCHAR(14)  NOT NULL,
    content        VARCHAR(500) NOT NULL,
    is_done        TINYINT(1)   NOT NULL DEFAULT 0,
    due_date       DATE         NULL,
    sort_order     INT          NOT NULL DEFAULT 0,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    CONSTRAINT fk_checklist_item FOREIGN KEY (checklist_oid) REFERENCES weddy_checklists (oid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 예산 카테고리
CREATE TABLE IF NOT EXISTS weddy_budgets (
    oid            VARCHAR(14) NOT NULL,
    couple_oid     VARCHAR(14) NOT NULL,
    category       VARCHAR(50) NOT NULL,
    planned_amount BIGINT      NOT NULL DEFAULT 0,
    created_at     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    CONSTRAINT fk_budget_couple FOREIGN KEY (couple_oid) REFERENCES weddy_couples (oid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 예산 지출 항목
CREATE TABLE IF NOT EXISTS weddy_budget_items (
    oid        VARCHAR(14)  NOT NULL,
    budget_oid VARCHAR(14)  NOT NULL,
    title      VARCHAR(100) NOT NULL,
    amount     BIGINT       NOT NULL,
    paid_at    DATE         NULL,
    memo       VARCHAR(500) NULL,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    CONSTRAINT fk_budget_item FOREIGN KEY (budget_oid) REFERENCES weddy_budgets (oid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 웨딩 업체
CREATE TABLE IF NOT EXISTS weddy_vendors (
    oid          VARCHAR(14)  NOT NULL,
    name         VARCHAR(100) NOT NULL,
    category     ENUM('HALL','STUDIO','DRESS','MAKEUP','HONEYMOON','ETC') NOT NULL,
    address      VARCHAR(300) NULL,
    phone        VARCHAR(20)  NULL,
    description  TEXT         NULL,
    homepage_url VARCHAR(500) NULL,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 리프레시 토큰
CREATE TABLE IF NOT EXISTS weddy_refresh_tokens (
    oid          VARCHAR(14)   NOT NULL COMMENT 'SecureRandom 14자리 PK',
    user_oid     VARCHAR(14)   NOT NULL COMMENT '사용자 OID',
    token        VARCHAR(512)  NOT NULL COMMENT 'Refresh Token 값',
    expires_at   DATETIME      NOT NULL COMMENT '만료 일시',
    created_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    UNIQUE KEY uk_user_oid (user_oid),
    CONSTRAINT fk_refresh_user FOREIGN KEY (user_oid) REFERENCES weddy_users(oid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='리프레시 토큰';

-- 커플 즐겨찾기 업체 (N:M)
CREATE TABLE IF NOT EXISTS weddy_couple_favorites (
    couple_oid VARCHAR(14) NOT NULL,
    vendor_oid VARCHAR(14) NOT NULL,
    created_at DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (couple_oid, vendor_oid),
    CONSTRAINT fk_favorite_couple FOREIGN KEY (couple_oid) REFERENCES weddy_couples (oid) ON DELETE CASCADE,
    CONSTRAINT fk_favorite_vendor FOREIGN KEY (vendor_oid) REFERENCES weddy_vendors (oid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
