-- ============================================================
-- Weddy Test Data
-- ============================================================
-- [중요] 이 스크립트는 수동으로 DB를 리셋할 때 사용합니다.
--
-- 실행 순서:
--   1. schema.sql  → 테이블 DROP & CREATE
--   2. data.sql    → 업체(weddy_vendors) 기초 데이터 삽입
--   3. 앱 기동     → DataInitializer가 사용자·커플·체크리스트·예산·즐겨찾기 자동 생성
--
-- [사용자 계정]
--   DataInitializer (com.project.weddy.common.init.DataInitializer) 에서
--   BCrypt 해시로 자동 생성됩니다. (@Profile("dev") 필수)
--   - groom_kim / 1234  (GROOM, oid: 10000000000001)
--   - bride_lee / 1234  (BRIDE, oid: 10000000000002)
--   - solo_park / 1234  (BRIDE, 커플 미연결, oid: 10000000000003)
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DELETE FROM weddy_couple_favorites;
DELETE FROM weddy_budget_items;
DELETE FROM weddy_budgets;
DELETE FROM weddy_checklist_items;
DELETE FROM weddy_checklists;
DELETE FROM weddy_refresh_tokens;
DELETE FROM weddy_couples;
DELETE FROM weddy_vendors;
DELETE FROM weddy_users;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 웨딩 업체 (weddy_vendors)
-- 카테고리: HALL | STUDIO | DRESS | MAKEUP | HONEYMOON | ETC
-- ============================================================

INSERT INTO weddy_vendors (oid, name, category, address, phone, description, homepage_url) VALUES

-- 웨딩홀
('70000000000001', '그랜드 웨딩홀',       'HALL',
 '서울특별시 강남구 테헤란로 123',
 '02-1234-5678',
 '강남 최대 규모의 웨딩홀. 최대 600명 수용. 전속 셰프의 고급 뷔페 제공. 야외 가든 포함.',
 'https://grandweddinghall.co.kr'),

('70000000000006', '더베뉴 웨딩홀',       'HALL',
 '서울특별시 서초구 반포대로 456',
 '02-2345-6789',
 '한강 뷰가 아름다운 루프탑 웨딩홀. 최대 300명 수용. 야경 웨딩 전문.',
 'https://thevenue.co.kr'),

('70000000000007', '파크 웨딩홀',         'HALL',
 '서울특별시 송파구 올림픽로 789',
 '02-3456-7890',
 '잠실 롯데타워 인근 초고층 뷰 웨딩홀. 최대 400명 수용. 스카이라운지 보유.',
 'https://parkwedding.co.kr'),

-- 스튜디오
('70000000000002', '스튜디오 아이엘',     'STUDIO',
 '서울특별시 마포구 홍대입구역 5번 출구',
 '02-9876-5432',
 '자연광 야외 촬영 전문 스튜디오. 한복·드레스 촬영 가능. 무제한 의상 변경 패키지 제공.',
 'https://studio-il.com'),

('70000000000008', '스튜디오 화이트',     'STUDIO',
 '서울특별시 강남구 청담동 12',
 '02-4567-8901',
 '미니멀 화이트톤 컨셉 스튜디오. 커플·본식 촬영 전문. SNS 감성 사진 특화.',
 'https://studiowhite.co.kr'),

-- 드레스
('70000000000003', '로맨티크 드레스샵',   'DRESS',
 '서울특별시 서초구 방배동 456',
 '02-3456-7890',
 '유럽 직수입 웨딩드레스 500벌 이상 보유. 맞춤 제작 서비스. 촬영용·본식용 분리 패키지.',
 'https://romantique-dress.co.kr'),

('70000000000009', '웨딩드레스 하우스',   'DRESS',
 '서울특별시 종로구 인사동 78',
 '02-5678-9012',
 '국내 디자이너 드레스 전문. 한복·드레스 원스톱 패키지. 신부 보정 속옷 무료 제공.',
 'https://weddingdresshouse.co.kr'),

-- 메이크업
('70000000000004', '뷰티 아뜰리에',       'MAKEUP',
 '서울특별시 강남구 청담동 789',
 '02-7890-1234',
 '전속 헤어·메이크업 팀 운영. 트라이얼 1회 포함. 당일 웨딩·스튜디오 촬영 모두 가능.',
 'https://beauty-atelier.kr'),

('70000000000010', '브라이덜 스튜디오',   'MAKEUP',
 '서울특별시 마포구 합정동 33',
 '02-6789-0123',
 '웨딩 특화 피부관리·메이크업 샵. 스킨케어 패키지와 메이크업을 함께 제공.',
 'https://bridal-studio.co.kr'),

-- 신혼여행
('70000000000005', '발리 허니문 투어',    'HONEYMOON',
 '서울특별시 중구 명동 101',
 '02-1111-2222',
 '발리·몰디브·유럽 신혼여행 패키지 전문. 맞춤 일정 설계. 풀빌라 단독 예약 서비스.',
 'https://bali-honeymoon.co.kr'),

('70000000000011', '유럽 웨딩 트래블',    'HONEYMOON',
 '서울특별시 강남구 역삼동 55',
 '02-2222-3333',
 '파리·로마·프라하 신혼여행 전문 여행사. 비즈니스 항공권 + 5성급 호텔 패키지.',
 'https://europe-wedding-travel.co.kr'),

-- 기타
('70000000000012', '웨딩 플래너 스튜디오','ETC',
 '서울특별시 용산구 이태원동 99',
 '02-3333-4444',
 '웨딩 전 과정 토탈 플래닝 서비스. 예식 당일 현장 관리 포함. 1:1 담당 플래너 배정.',
 'https://wedding-planner.co.kr'),

('70000000000013', '플라워 웨딩 데코',    'ETC',
 '서울특별시 강서구 마곡동 77',
 '02-4444-5555',
 '부케·테이블·홀 꽃장식 전문. 생화 100% 사용. 촬영용 소품 대여 서비스 포함.',
 'https://flower-wedding-deco.co.kr');
