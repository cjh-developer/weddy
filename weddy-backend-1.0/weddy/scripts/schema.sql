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

DROP TABLE IF EXISTS weddy_roadmap_travel_stops;
DROP TABLE IF EXISTS weddy_roadmap_hall_tours;
DROP TABLE IF EXISTS weddy_roadmap_steps;
DROP TABLE IF EXISTS weddy_schedules;
DROP TABLE IF EXISTS weddy_favorites;
DROP TABLE IF EXISTS weddy_couple_favorites;
DROP TABLE IF EXISTS weddy_budget_items;
DROP TABLE IF EXISTS weddy_budget_settings;
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
-- 전체 예산 설정
-- ============================================================
CREATE TABLE weddy_budget_settings (
    oid          VARCHAR(14)  NOT NULL               COMMENT 'SecureRandom 14자리 숫자 PK',
    owner_oid    VARCHAR(14)  NOT NULL               COMMENT '소유자 OID (솔로: 사용자 OID, 커플: 커플 OID)',
    total_amount BIGINT       NOT NULL DEFAULT 0     COMMENT '전체 예산 금액 (원)',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    UNIQUE KEY uq_budget_settings_owner_oid (owner_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='전체 예산 설정';

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
-- 일정 관리
-- ============================================================
CREATE TABLE weddy_schedules (
    oid          VARCHAR(14)  NOT NULL,
    owner_oid    VARCHAR(14)  NOT NULL COMMENT '솔로=userOid, 커플=coupleOid',
    title        VARCHAR(100) NOT NULL,
    description  TEXT,
    category     VARCHAR(30)  NOT NULL COMMENT '예식장|플래너|스튜디오|드레스|메이크업|신혼여행|예물|혼수|백화점|상견례|기타',
    is_all_day   TINYINT(1)   NOT NULL DEFAULT 0,
    start_at     DATETIME     NOT NULL,
    end_at       DATETIME     NULL,
    location     VARCHAR(200) NULL,
    alert_before VARCHAR(20)  NULL COMMENT '빈값(없음)|10MINUTES|30MINUTES|1HOUR|1DAY|3DAYS|1WEEK',
    source_type  VARCHAR(20)  NULL COMMENT 'MANUAL|HALL_TOUR|DRESS|SANGGYEONRYE',
    source_oid   VARCHAR(30)  NULL COMMENT '자동 생성 출처 OID (로드맵 _SANG suffix 포함 최대 19자)',
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    INDEX idx_schedules_owner (owner_oid),
    INDEX idx_schedules_start (start_at),
    INDEX idx_schedules_source (source_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='일정';

-- ============================================================
-- 웨딩 로드맵 단계
-- ============================================================
CREATE TABLE weddy_roadmap_steps (
    oid          VARCHAR(14)   NOT NULL,
    owner_oid    VARCHAR(14)   NOT NULL COMMENT '솔로=userOid, 커플=coupleOid',
    step_type    VARCHAR(30)   NOT NULL COMMENT 'BUDGET|HALL|PLANNER|DRESS|HOME|TRAVEL|GIFT|SANGGYEONRYE|ETC',
    title        VARCHAR(100)  NOT NULL COMMENT '기타 단계의 경우 직접 입력',
    is_done      TINYINT(1)    NOT NULL DEFAULT 0,
    due_date     DATE          NULL,
    has_due_date TINYINT(1)    NOT NULL DEFAULT 0,
    sort_order   INT           NOT NULL DEFAULT 0,
    details      TEXT          NULL COMMENT 'JSON 형태의 단계별 특화 데이터',
    created_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    INDEX idx_roadmap_owner (owner_oid),
    INDEX idx_roadmap_type  (step_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='웨딩 로드맵 단계';

-- ============================================================
-- 웨딩홀 투어 (1:N)
-- ============================================================
CREATE TABLE weddy_roadmap_hall_tours (
    oid        VARCHAR(14)   NOT NULL,
    step_oid   VARCHAR(14)   NOT NULL COMMENT 'weddy_roadmap_steps.oid',
    hall_name  VARCHAR(100)  NOT NULL,
    tour_date  DATE          NULL,
    location   VARCHAR(200)  NULL,
    rental_fee BIGINT        NULL,
    meal_price BIGINT        NULL COMMENT '식대(1인당)',
    min_guests INT           NULL COMMENT '보증 인원',
    memo       TEXT          NULL,
    created_at DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    INDEX idx_hall_tours_step (step_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='웨딩홀 투어';

-- ============================================================
-- 항공권 경유지 (1:N)
-- ============================================================
CREATE TABLE weddy_roadmap_travel_stops (
    oid        VARCHAR(14)  NOT NULL,
    step_oid   VARCHAR(14)  NOT NULL COMMENT 'weddy_roadmap_steps.oid',
    stop_order INT          NOT NULL,
    city       VARCHAR(100) NOT NULL,
    PRIMARY KEY (oid),
    INDEX idx_travel_stops_step (step_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='항공권 경유지';

-- ============================================================
-- 즐겨찾기 업체 (솔로/커플 공용, owner_oid 패턴)
-- ============================================================
CREATE TABLE weddy_favorites (
    oid        VARCHAR(14) NOT NULL               COMMENT 'SecureRandom 14자리 숫자 PK',
    owner_oid  VARCHAR(14) NOT NULL               COMMENT '소유자 OID (솔로=userOid, 커플=coupleOid)',
    vendor_oid VARCHAR(14) NOT NULL               COMMENT '업체 OID',
    created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (oid),
    UNIQUE KEY uq_owner_vendor (owner_oid, vendor_oid),
    INDEX idx_owner  (owner_oid),
    INDEX idx_vendor (vendor_oid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='업체 즐겨찾기';
