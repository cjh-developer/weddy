# Weddy 프로젝트 변경 이력

> 결혼 준비 앱 — Flutter (Frontend) + Spring Boot (Backend)

---

## [9단계] 즐겨찾기(벤더) + 업체 검색/상세 (2026-03-30)

### Added — Backend

**신규 파일**

| 파일 | 내용 |
|------|------|
| `domain/vendor/entity/Vendor.java` | weddy_vendors JPA 엔티티 |
| `domain/vendor/entity/Favorite.java` | weddy_favorites JPA 엔티티 (owner_oid + vendor_oid UNIQUE KEY) |
| `domain/vendor/repository/VendorRepository.java` | 카테고리/키워드 필터 조회 |
| `domain/vendor/repository/FavoriteRepository.java` | 즐겨찾기 CRUD |
| `domain/vendor/dto/request/AddFavoriteRequest.java` | @Pattern(regexp="^[0-9]{14}$") |
| `domain/vendor/dto/response/VendorResponse.java` | isFavorited(@JsonProperty("favorited")) 포함 |
| `domain/vendor/dto/response/VendorDetailResponse.java` | favoriteOid(@JsonProperty("favorited")) 포함 |
| `domain/vendor/dto/response/FavoriteItemResponse.java` | 즐겨찾기 목록 응답 DTO |
| `domain/vendor/dto/response/AddFavoriteResponse.java` | 즐겨찾기 추가 응답 DTO |
| `domain/vendor/service/VendorService.java` | VALID_CATEGORIES 화이트리스트, FORBIDDEN 응답, debug 로그 |
| `domain/vendor/controller/VendorController.java` | @Validated + @Pattern/@Size 입력 검증 |

**API 엔드포인트 추가**

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/api/v1/vendors?category=HALL&keyword=서울` | 벤더 목록 (isFavorited 포함) |
| GET | `/api/v1/vendors/favorites` | 즐겨찾기 목록 |
| GET | `/api/v1/vendors/{vendorOid}` | 벤더 상세 (favoriteOid 포함) |
| POST | `/api/v1/vendors/favorites` | 즐겨찾기 추가 |
| DELETE | `/api/v1/vendors/favorites/{favoriteOid}` | 즐겨찾기 삭제 |

**ErrorCode 추가**

| 코드 | 의미 |
|------|------|
| AUTH_004 / FORBIDDEN | 접근 권한 없음 (IDOR 방어용) |

### Added — Frontend

**신규 파일**

| 파일 | 내용 |
|------|------|
| `lib/features/vendor/data/model/vendor_model.dart` | VendorModel, VendorDetailModel, FavoriteItemModel |
| `lib/features/vendor/data/datasource/vendor_remote_datasource.dart` | Dio 기반 API 호출 |
| `lib/features/vendor/presentation/notifier/vendor_notifier.dart` | sealed state, reset(), updateFavoriteStatus() |
| `lib/features/vendor/presentation/notifier/vendor_detail_notifier.dart` | 상세 조회 notifier |
| `lib/features/vendor/presentation/screen/vendor_screen.dart` | 카테고리 탭 + 검색바 + 카드 리스트 |
| `lib/features/vendor/presentation/screen/vendor_detail_screen.dart` | SliverAppBar, URL 스킴 검증, url_launcher |

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `lib/core/router/app_router.dart` | /vendor, /vendor/:oid 경로 추가 |
| `lib/features/home/presentation/screen/home_screen.dart` | 업체 메뉴 context.push('/vendor') 연결 |
| `lib/features/auth/presentation/notifier/auth_notifier.dart` | 로그아웃 시 vendorNotifierProvider.reset() 추가 |
| `pubspec.yaml` | url_launcher ^6.3.0 추가 |

### Fixed — Backend (lead-code-validator)

| 버그 | 수정 내용 |
|------|---------|
| Jackson boolean 직렬화 키 불일치 | VendorResponse/VendorDetailResponse에 @JsonProperty("favorited") 명시 |

### Fixed — Frontend (lead-code-validator)

| 버그 | 수정 내용 |
|------|---------|
| vendor_detail_screen.dart 이중 API 호출 | 즐겨찾기 토글 후 updateFavoriteStatus() 로컬 동기화로 교체 |
| auth_notifier.dart 로그아웃 시 vendorNotifierProvider 미초기화 | reset() 호출 추가 |

### Security — Backend (security-advisor)

| 항목 | 내용 |
|------|------|
| category 파라미터 화이트리스트 | VALID_CATEGORIES Set으로 허용 값 명시 검증 |
| IDOR 응답 코드 수정 | UNAUTHORIZED(401) → FORBIDDEN(403, AUTH_004) |
| 입력 검증 강화 | @Validated + @Pattern/@Size (category, keyword, oid PathVariables) |
| 로그 레벨 낮춤 | 의심 접근 시 INFO → debug 레벨 (운영 로그 오염 방지) |

### Security — Frontend (security-advisor)

| 항목 | 내용 |
|------|------|
| URL 스킴 검증 | vendor_detail_screen.dart: http/https만 허용, 나머지 차단 |

---

## [8.2단계] 전체 화면 UI 개선 (2026-03-30)

### Changed — Frontend

| 화면 | 변경 내용 |
|------|---------|
| 전체 7개 화면 | 배경색 통일: `0xFF0D0D1A` → `0xFF080810` / `0xFF1B0929` → `0xFF0C0820` |
| `home_screen.dart` | _DDayChip 그라디언트+하트 아이콘, 메뉴 아이콘 글로우, 진행률 gradient bar |
| `budget_screen.dart` | 다이얼로그 입력필드 `Color(0x1AFFFFFF)` glass 스타일, 진행률 gradient bar |
| `schedule_screen.dart` | 뷰토글 그라디언트, 일정 카드 좌측 컬러바, 캘린더 오늘날짜 글로우 |
| `checklist_screen.dart` | 섹션 헤더 진행률 2px 바, 완료 아이템 초록 tint 배경 |
| `login_screen.dart` / `sign_up_screen.dart` / `wedding_date_setup_screen.dart` | 입력필드 `Color(0x1AFFFFFF)` glass 스타일 통일 |

### Notes
- DB/BE 변경 없음 (순수 FE UI 개선)

---

## [8.1단계] 웨딩 관리 UI 개선 (2026-03-29)

### Fixed — Frontend

| 버그 | 수정 내용 |
|------|---------|
| `initDefaultRoadmap()` 서버 동기화 누락 | API 성공 후 직접 state 설정 → `await loadSteps()` 호출로 서버 재동기화 |
| 단계 추가 모달 터치 버그 | `showDialog + Center + ConstrainedBox + Material` 래퍼 구조로 수정 |

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `lib/features/roadmap/screens/roadmap_screen.dart` | 유리 글래스모피즘 디자인 전면 적용 (`_kBg1=0xFF080810`, `_kBg2=0xFF0C0820`, BackdropFilter blur sigmaX/Y=10, 카드 배경 `0x1AFFFFFF`, 테두리 `0x28FFFFFF`) |
| `lib/features/roadmap/screens/roadmap_screen.dart` | `_PeriodGroup` 데이터 클래스 + `_PeriodGroupTile` 복원: 왼쪽 dot+gradient line / 오른쪽 glass card, dDayText 기반 기간 그룹화 |
| `lib/features/roadmap/screens/roadmap_screen.dart` | 기간 배지 상태 색상 분리: 완료→초록 / 진행중→노랑 / 미시작→`Color(0x88FFFFFF)` 중립 |
| `lib/features/roadmap/screens/roadmap_screen.dart` | ETC 커스텀 카테고리: 이름 직접 입력 + 12색 팔레트, `details['customColor']`(int)에 저장 |
| `lib/features/roadmap/screens/roadmap_screen.dart` | `_CustomRoadmapTabView`에 `onShowMenu` 콜백 + `Icons.more_vert` 버튼으로 직접 로드맵 삭제 접근성 개선 |
| `lib/features/roadmap/models/roadmap_step_model.dart` | `effectiveColor` getter 추가: `details['customColor']` int → `Color` 변환, 없으면 카테고리 기본색 사용 |

### Notes
- `flutter analyze`: No issues found
- DB/BE 변경 없음 (순수 FE UI 개선)

---

## [8단계] 로드맵 아키텍처 재설계 — 직접 로드맵 기능 (2026-03-29)

### Added — Backend

**신규 파일 5개**

| 파일 | 내용 |
|------|------|
| `domain/roadmap/entity/CustomRoadmap.java` | `weddy_custom_roadmaps` JPA 엔티티 (oid PK, owner_oid INDEX, name, sort_order) |
| `domain/roadmap/repository/CustomRoadmapRepository.java` | `findByOwnerOidOrderBySortOrderAsc`, `countByOwnerOid`, `findByOidAndOwnerOid` |
| `domain/roadmap/dto/request/CreateCustomRoadmapRequest.java` | 직접 로드맵 생성 요청 DTO |
| `domain/roadmap/dto/request/RenameCustomRoadmapRequest.java` | 직접 로드맵 이름 변경 요청 DTO |
| `domain/roadmap/dto/response/CustomRoadmapResponse.java` | oid/name/sortOrder/steps 포함 응답 DTO |
| `domain/roadmap/controller/CustomRoadmapController.java` | 4개 엔드포인트 (GET/POST 목록·생성, PATCH/DELETE 수정·삭제) |

**API 엔드포인트 추가**

| 메서드 | URL | 설명 |
|--------|-----|------|
| GET | `/api/v1/roadmap/custom` | 직접 로드맵 목록 (소속 단계 포함) |
| POST | `/api/v1/roadmap/custom` | 직접 로드맵 생성 (최대 10개) |
| PATCH | `/api/v1/roadmap/custom/{groupOid}` | 이름 변경 |
| DELETE | `/api/v1/roadmap/custom/{groupOid}` | 삭제 (소속 단계 연쇄 삭제) |

**ErrorCode 추가**

| 코드 | 의미 |
|------|------|
| ROADMAP_008 | CUSTOM_ROADMAP_NOT_FOUND — 직접 로드맵 없음 또는 소유권 없음 |
| ROADMAP_009 | CUSTOM_ROADMAP_LIMIT_EXCEEDED — 직접 로드맵 10개 한도 초과 |

**schema.sql 변경**

| 변경 | 내용 |
|------|------|
| `weddy_custom_roadmaps` 테이블 신규 추가 | oid PK, owner_oid INDEX, name VARCHAR(100), sort_order INT |
| `weddy_roadmap_steps.group_oid` 컬럼 추가 | VARCHAR(14) NULL + INDEX (NULL=기본 로드맵, 값=직접 로드맵 OID) |

### Changed — Backend

| 파일 | 변경 내용 |
|------|---------|
| `domain/roadmap/entity/RoadmapStep.java` | `groupOid` 필드 추가 |
| `domain/roadmap/dto/response/RoadmapStepResponse.java` | `groupOid` 필드 추가 |
| `domain/roadmap/dto/request/CreateRoadmapStepRequest.java` | optional `groupOid` 필드 추가 |
| `domain/roadmap/repository/RoadmapStepRepository.java` | `findByOwnerOidAndGroupOidIsNull`, `findByOwnerOidAndGroupOid`, `countByOwnerOidAndGroupOidIsNull`, `countByOwnerOidAndGroupOid` 추가 |
| `domain/roadmap/service/RoadmapService.java` | `getSteps()` 기본 로드맵만 조회, `createStep()` groupOid 소유권 검증 및 스코프별 sort_order 계산, `initDefaultRoadmap()` 중복 체크 수정, custom 로드맵 CRUD 메서드 4개 추가, `CustomRoadmapRepository` 의존성 주입 |

### Fixed — Backend

| 버그 | 수정 내용 |
|------|---------|
| `initDefaultRoadmap()` 중복 체크 오류 | `countByOwnerOid` → `countByOwnerOidAndGroupOidIsNull` 변경 — 직접 로드맵 단계가 있어도 기본 로드맵 생성 가능 |

### Added — Frontend

**신규 파일 2개**

| 파일 | 내용 |
|------|------|
| `lib/features/roadmap/models/custom_roadmap_model.dart` | oid/name/sortOrder/steps 포함 모델 |
| `lib/features/roadmap/providers/custom_roadmap_notifier.dart` | sealed state (Initial/Loading/Loaded/Error) + loadCustomRoadmaps / createCustomRoadmap / renameCustomRoadmap / deleteCustomRoadmap (낙관적 삭제) |

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `lib/features/roadmap/models/roadmap_step_model.dart` | `groupOid: String?` 필드 추가 (fromJson/toJson/copyWith) |
| `lib/features/roadmap/providers/roadmap_notifier.dart` | `createStep()`에 `groupOid` 파라미터 추가 |
| `lib/features/auth/providers/auth_notifier.dart` | 로그아웃 시 `customRoadmapNotifierProvider.notifier.reset()` 추가 |
| `lib/features/roadmap/screens/roadmap_screen.dart` | 동적 탭 구조 ([기본 로드맵] + [직접1..N] + [+]), `_initTabController` 동적 재초기화, 탭 롱프레스 메뉴, `_CustomRoadmapTabView`, `_AddRoadmapTab`, FAB 3분기 로직 |

---

## [7단계] 첨부파일(Vault) 기능 (2026-03-28)

### Added — Backend

**신규 파일 7개**

| 파일 | 내용 |
|------|------|
| `domain/attachment/config/FileStorageProperties.java` | `file.upload-dir` 프로퍼티 바인딩 |
| `domain/attachment/config/FileStorageConfig.java` | 업로드 디렉토리 초기화 |
| `domain/attachment/entity/Attachment.java` | weddy_attachments JPA 엔티티 (oid PK, owner_oid INDEX, ref_type, ref_oid, original_name, stored_name, file_size, mime_type) |
| `domain/attachment/repository/AttachmentRepository.java` | 5개 메서드 (findByOwnerOidAndRefTypeAndRefOid, deleteByRefOid 등) |
| `domain/attachment/dto/response/AttachmentResponse.java` | oid/originalName/fileSize/mimeType/createdAt |
| `domain/attachment/service/AttachmentService.java` | 업로드/목록/다운로드/삭제, 매직넘버 이중 검증 |
| `domain/attachment/controller/AttachmentController.java` | 4개 엔드포인트 |

**API 엔드포인트**

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/api/v1/attachments` | 파일 업로드 (multipart/form-data, refType+refOid 파라미터) |
| GET | `/api/v1/attachments?refType=&refOid=` | 특정 참조 대상 첨부파일 목록 |
| GET | `/api/v1/attachments/{oid}/download` | 파일 다운로드 (Content-Disposition: attachment) |
| DELETE | `/api/v1/attachments/{oid}` | 첨부파일 삭제 |

**ErrorCode 추가**

| 코드 | 의미 |
|------|------|
| ATTACHMENT_001 | NOT_FOUND — 첨부파일 없음 또는 소유권 없음 |
| ATTACHMENT_002 | UPLOAD_FAILED — 파일 저장 실패 |
| ATTACHMENT_003 | INVALID_FILE_TYPE — 허용되지 않는 MIME 타입 |
| ATTACHMENT_004 | FILE_TOO_LARGE — 파일 크기 초과 |
| ATTACHMENT_005 | LIMIT_EXCEEDED — 첨부파일 개수 한도 초과 |

### Changed — Backend

| 파일 | 변경 내용 |
|------|---------|
| `resources/application.yml` | multipart 설정 추가 + `file.upload-dir: ./uploads` |
| `resources/scripts/schema.sql` | weddy_attachments 테이블 추가 |
| `common/exception/ErrorCode.java` | ATTACHMENT_001~005 추가 |
| `domain/roadmap/service/RoadmapService.java` | `deleteStep()`에 `attachmentService.deleteByRefOid(stepOid)` 연쇄 삭제 추가 |
| `domain/budget/service/BudgetService.java` | `deleteBudget()`에 `attachmentService.deleteByRefOid(budgetOid)` 연쇄 삭제 추가 |

### Added — Frontend

**신규 파일 4개**

| 파일 | 내용 |
|------|------|
| `lib/features/attachment/data/model/attachment_model.dart` | AttachmentModel |
| `lib/features/attachment/presentation/notifier/attachment_notifier.dart` | StateNotifierProvider.autoDispose.family<..., (String, String)> — refType+refOid 튜플 키, _lastKnownList 필드 |
| `lib/features/attachment/presentation/widget/attachment_thumbnail_widget.dart` | 이미지/PDF/기타 파일 썸네일 + 다운로드, Image.memory() 표시 |
| `lib/features/attachment/presentation/widget/attachment_section_widget.dart` | 파일 추가 버튼 + 목록, AttachmentUploading 상태 시 버튼 비활성화 |

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `pubspec.yaml` | `image_picker: ^1.1.2`, `file_picker: ^8.1.2` 추가 |
| `lib/features/roadmap/presentation/screen/roadmap_screen.dart` | `_StepDetailBottomSheet` 하단에 `AttachmentSectionWidget(refType: 'ROADMAP_STEP')` 추가 |
| `lib/features/budget/presentation/screen/budget_screen.dart` | `_BudgetSection` 하단에 `AttachmentSectionWidget(refType: 'BUDGET')` 추가 |

### Security

| 항목 | 내용 |
|------|------|
| 매직넘버 이중 검증 | JPEG(FF D8 FF), PNG(8바이트 시그니처), WebP(RIFF+WEBP 12바이트), PDF(%PDF) — MIME 타입 위조 방지 |
| list() IDOR 방어 | `validateRefOwnership()` — refType/refOid 소유권 확인 후 목록 반환 |
| upload() 검증 순서 | 크기 → MIME → 매직넘버 → 소유권 → 개수제한 → 저장 |
| download 응답 | Content-Disposition: attachment + RFC 5987 파일명 인코딩 (한글 파일명 지원) |
| deleteByRefOid() | 내부 전용 메서드, ownerOid 없이 refOid로만 삭제 — 외부 API 미노출 |

**보안 백로그 신규 추가**

| 항목 | 우선순위 |
|------|----------|
| 고아 파일 정리 스케줄러 미구현 (디스크 저장 후 DB 실패 케이스) | LOW |
| storedName VARCHAR(40) → VARCHAR(50) 여유 확보 검토 | LOW |
| 운영 환경 로컬 스토리지 → S3/GCS 전환 필요 | LOW |

### Key Design Decisions

| 결정 | 이유 |
|------|------|
| StateNotifierProvider.family 튜플 키 | refType+refOid 조합으로 화면 간 상태 격리 (로드맵 단계별, 예산 카테고리별 독립 상태) |
| _lastKnownList 필드 | clearError() 시 빈 리스트 대신 마지막 정상 목록으로 복원 — 에러 후 목록 유지 |
| deleteByRefOid() ownerOid 조건 없음 | 내부 전용 메서드로 외부 API 경로 없음, RoadmapService/BudgetService에서만 호출 |
| 매직넘버 검증 | MIME 타입 스푸핑(파일 확장자 변조) 방어를 위해 파일 헤더 바이트 직접 검증 |

---

## [6.2단계] 웨딩 관리 로드맵 상세 폼 + 예산 연동 (2026-03-28)

### Added — Backend

| 파일 | 내용 |
|------|------|
| `domain/budget/repository/BudgetRepository.java` | `findByOwnerOidAndCategory(String ownerOid, String category)` 추가 |
| `domain/budget/service/BudgetService.java` | `syncBudgetItemsFromRoadmap(ownerOid, items)` — 배열 크기 제한(30), find-or-create 패턴 |
| `domain/budget/service/BudgetService.java` | `clearBudgetItemsFromRoadmap(ownerOid)` — BUDGET 단계 삭제 시 연동 항목 전량 삭제 |
| `domain/budget/service/BudgetService.java` | `toValidAmount(Object raw)` private 헬퍼 — 음수/0/범위초과 → 0L |

**BudgetService 클래스 상수 추가**

| 상수 | 값 | 설명 |
|------|----|------|
| `ROADMAP_BUDGET_CATEGORY` | `[로드맵] 결혼예산` | 로드맵 BUDGET 단계 연동 예산 고정 카테고리명 |
| `MAX_ITEM_AMOUNT` | `9_999_999_999L` | 예산 항목 최대 금액 |
| `MAX_BUDGET_ITEMS` | `30` | 로드맵 연동 예산 항목 최대 개수 |

### Changed — Backend

| 파일 | 변경 내용 |
|------|---------|
| `domain/roadmap/service/RoadmapService.java` | `deleteStep()` 단순화 — SANGGYEONRYE 타입 분기 제거, `deleteBySourceOid(stepOid)` + `deleteBySourceOid(stepOid + "_SANG")` 항상 2회 실행 |
| `domain/roadmap/service/RoadmapService.java` | `syncBudgetItemsFromDetails()` catch 범위 `JsonProcessingException` → `Exception` (convertValue IllegalArgumentException 포함) |
| `domain/roadmap/service/RoadmapService.java` | `syncSanggyeonryeSchedule()` 로그 `e.getMessage()` → `e.getClass().getSimpleName()` (개인정보 로그 방지) |
| `domain/roadmap/service/RoadmapService.java` | `syncBudgetItemsFromDetails()`, `syncSanggyeonryeSchedule()`, `syncRoadmapSchedule()` 헬퍼 메서드 명시 분리 |
| `domain/schedule/entity/Schedule.java` | `source_oid VARCHAR(14)` → `VARCHAR(30)` (stepOid+"_SANG" 19자 저장 허용) |
| `resources/scripts/schema.sql` | `weddy_schedules.source_oid` 컬럼 VARCHAR(14) → VARCHAR(30) |

### Added — Frontend

| 파일 | 내용 |
|------|------|
| `lib/features/roadmap/presentation/notifier/roadmap_notifier.dart` | `createStep()` 메서드 추가 (POST /roadmap) |
| `lib/features/roadmap/presentation/screen/roadmap_screen.dart` | `_StepDetailBottomSheetState` 9종 stepType별 폼 UI 전체 구현 |
| `lib/features/roadmap/presentation/screen/roadmap_screen.dart` | `_buildFab()` FAB 단계 추가 버튼 |
| `lib/features/roadmap/presentation/screen/roadmap_screen.dart` | `_AddStepBottomSheet` — 9종 stepType 선택, ETC 중복 허용, 기존 존재 시 비활성화 |

**9종 stepType 폼 상세**

| stepType | 주요 필드 |
|----------|---------|
| BUDGET | budgetItems[](name/deposit/balance), totalBudget, `_addBudgetItem()` 헬퍼 |
| HALL | 기존 필드 유지 |
| PLANNER | studio/dress/makeup 3개 고정 스드메 필드 |
| DRESS | 기존 필드 유지 |
| HOME | subway/walkDist 추가 필드 |
| TRAVEL | 기존 필드 유지 |
| GIFT | 기존 필드 유지 |
| SANGGYEONRYE | pricePerPerson×guests 자동계산, totalAmount 수동 입력, extraItems, 일정 자동 등록 |
| ETC | 기존 필드 유지 |

### Security

| 항목 | 내용 |
|------|------|
| source_oid VARCHAR 확장 | VARCHAR(14) → VARCHAR(30) — stepOid+"_SANG" 복합 키 저장 가능 |
| 배열 크기 제한 | syncBudgetItemsFromRoadmap() 항목 최대 30개 + name 길이 100자 제한 |
| 금액 검증 헬퍼 | toValidAmount(): 음수/0/9_999_999_999 초과 → 0L 처리 (정수 오버플로우 방지) |
| Exception 포괄 catch | syncBudgetItemsFromDetails() IllegalArgumentException까지 포함 — 처리 실패 시 예산 연동 조용히 스킵 |
| 개인정보 로그 방지 | syncSanggyeonryeSchedule() e.getMessage() 제거 → 클래스명만 로그 |

**보안 백로그 신규 추가**

| 항목 | 우선순위 |
|------|----------|
| deleteBySourceOid()에 ownerOid 조건 없음 — 내부 전용, JavaDoc 명시 권고 | LOW |

### Key Design Decisions

| 결정 | 이유 |
|------|------|
| deleteStep() SANGGYEONRYE 분기 제거 | 항상 stepOid + stepOid+"_SANG" 두 sourceOid로 deleteBySourceOid 2회 실행 → 분기 로직 없이 단순화, 향후 상견례 외 복합 일정 추가 시 확장 용이 |
| source_oid VARCHAR(30) 확장 | stepOid(14) + "_SANG"(5) = 19자 저장 필요, 여유분 포함하여 30자로 확장 |
| ROADMAP_BUDGET_CATEGORY 클래스 상수 | 서비스·레포지토리 양쪽에서 참조하는 문자열 상수를 BudgetService에 단일 관리 |
| toValidAmount() 0L 반환 | 유효하지 않은 금액은 저장하지 않고 조용히 스킵 (예외 발생 시 전체 단계 저장 실패 방지) |

---

## [6.1단계] 일정 관리 UI 개선 — 주간/일별 뷰 + 로드맵-일정 자동 연동 (2026-03-25)

### Added — Frontend

| 파일 | 내용 |
|------|------|
| `lib/features/schedule/presentation/screen/schedule_screen.dart` | `_ViewMode` enum (monthly/weekly/daily), 상단 뷰 모드 토글 버튼 3종 |
| `lib/features/schedule/presentation/screen/schedule_screen.dart` | `_buildWeeklyView()` — 7일 타일 + 카테고리 색상 점 마커 + 주 이동 네비게이션 |
| `lib/features/schedule/presentation/screen/schedule_screen.dart` | `_buildDailyView()` — 종일/시간 구분 리스트 + 날짜 네비게이션 |
| `lib/features/schedule/presentation/notifier/schedule_notifier.dart` | `loadSchedulesForRange(DateTime start, DateTime end)` — 주간 뷰 월 경계 처리, 루프 내 mounted 체크 |

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `lib/features/schedule/presentation/screen/schedule_screen.dart` | `_prevDay`/`_nextDay` 월 경계 감지 방식 변경 — ScheduleLoaded.year 대신 이전 `_selectedDay.month`와 직접 비교 후 `loadSchedules` 재조회 |

### Added — Backend

| 파일 | 내용 |
|------|------|
| `domain/roadmap/service/RoadmapService.java` | `getScheduleCategoryForStepType(stepType)` 헬퍼 (HALL→예식장, PLANNER→플래너, DRESS→드레스, TRAVEL→신혼여행, GIFT→예물, SANGGYEONRYE→상견례, default→기타) |
| `domain/roadmap/service/RoadmapService.java` | `syncRoadmapSchedule(ownerOid, step)` — deleteBySourceOid 후 조건부 createScheduleInternal (sourceType="ROADMAP") |

### Changed — Backend

| 파일 | 변경 내용 |
|------|---------|
| `domain/roadmap/service/RoadmapService.java` | `createStep()` — hasDueDate=true && dueDate!=null 시 일정 자동 등록 |
| `domain/roadmap/service/RoadmapService.java` | `updateStep()` — dueDate/hasDueDate/clearDueDate 변경 시에만 syncRoadmapSchedule 호출 (title 단독 변경은 동기화 제외, OID 안정성 보장) |

### Key Design Decisions

| 결정 | 이유 |
|------|------|
| 월 경계 감지 직접 비교 | notifier의 ScheduleLoaded.year보다 `_selectedDay.month` 직접 비교가 상태 의존성 없이 안전 |
| updateStep() 조건부 동기화 | title만 변경할 때 일정 OID가 교체되면 외부 참조가 끊기므로 날짜 변경 시에만 재동기화 |
| syncRoadmapSchedule 분리 | createStep/updateStep 양쪽에서 재사용하기 위해 독립 헬퍼로 분리 |

---

## [6단계] 일정 관리 & 웨딩 관리 (2026-03-20)

### Added — Backend

**새 테이블 (schema.sql)**

| 테이블 | 주요 컬럼 |
|--------|---------|
| `weddy_schedules` | owner_oid, title, category, is_all_day, start_at, end_at, location, alert_before, source_type, source_oid |
| `weddy_roadmap_steps` | owner_oid, step_type(BUDGET|HALL|PLANNER|DRESS|HOME|TRAVEL|GIFT|SANGGYEONRYE|ETC), title, is_done, due_date, has_due_date, sort_order, details(TEXT/JSON) |
| `weddy_roadmap_hall_tours` | step_oid, hall_name, tour_date, location, rental_fee, meal_price, min_guests, memo |
| `weddy_roadmap_travel_stops` | step_oid, stop_order, city |

**새 API 엔드포인트**

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/api/v1/schedules` | 월별 일정 목록 |
| POST | `/api/v1/schedules` | 일정 생성 |
| GET | `/api/v1/schedules/{oid}` | 일정 상세 |
| PUT | `/api/v1/schedules/{oid}` | 일정 수정 |
| DELETE | `/api/v1/schedules/{oid}` | 일정 삭제 |
| GET | `/api/v1/roadmap` | 로드맵 전체 단계 목록 |
| POST | `/api/v1/roadmap` | 단계 생성 |
| GET | `/api/v1/roadmap/{oid}` | 단계 상세 |
| PUT | `/api/v1/roadmap/{oid}` | 단계 수정 |
| DELETE | `/api/v1/roadmap/{oid}` | 단계 삭제 (연쇄) |
| PATCH | `/api/v1/roadmap/{oid}/toggle` | 완료/미완료 토글 |
| GET | `/api/v1/roadmap/{oid}/hall-tours` | 투어 목록 |
| POST | `/api/v1/roadmap/{oid}/hall-tours` | 투어 추가 (일정 자동 등록) |
| DELETE | `/api/v1/roadmap/{oid}/hall-tours/{tourOid}` | 투어 삭제 |
| POST | `/api/v1/roadmap/{oid}/travel-stops` | 여행 경유지 추가 |
| DELETE | `/api/v1/roadmap/{oid}/travel-stops/{stopOid}` | 경유지 삭제 |

**새 파일**

| 파일 | 내용 |
|------|------|
| `domain/schedule/entity/Schedule.java` | 일정 엔티티 (oid PK, owner_oid INDEX, source_type/source_oid 역추적용) |
| `domain/schedule/repository/ScheduleRepository.java` | findByOidAndOwnerOid() TOCTOU 방지 |
| `domain/schedule/service/ScheduleService.java` | 소유권 검증, createScheduleInternal() 내부 메서드 |
| `domain/schedule/controller/ScheduleController.java` | 5개 엔드포인트 |
| `domain/roadmap/entity/RoadmapStep.java` | 로드맵 단계 엔티티 (details TEXT/JSON) |
| `domain/roadmap/entity/HallTour.java` | 웨딩홀 투어 서브 엔티티 |
| `domain/roadmap/entity/TravelStop.java` | 여행 경유지 서브 엔티티 |
| `domain/roadmap/service/RoadmapService.java` | syncBudgetSettings(), createScheduleInternal() 연동, deleteStep() 연쇄 삭제 |
| `domain/roadmap/controller/RoadmapController.java` | 11개 엔드포인트 |

**ErrorCode 추가**

| 코드 | 의미 |
|------|------|
| SCHEDULE_001 | SCHEDULE_NOT_FOUND |
| ROADMAP_001 | ROADMAP_STEP_NOT_FOUND |
| ROADMAP_002 | ROADMAP_HALL_TOUR_NOT_FOUND |
| ROADMAP_003 | ROADMAP_STEP_LIMIT_EXCEEDED |
| ROADMAP_004 | ROADMAP_TRAVEL_STOP_NOT_FOUND |

**BudgetService 추가**

| 메서드 | 설명 |
|--------|------|
| `upsertSettingsInternal(String ownerOid, Long totalAmount)` | RoadmapService BUDGET 단계에서 내부 호출용, 범위 1~9_999_999_999 |

**DataInitializer 추가**
- 9단계 자동 생성: OID 80000000000001~80000000000009, 커플 소유 (BUDGET/HALL/PLANNER/DRESS/HOME/TRAVEL/GIFT/SANGGYEONRYE/ETC)

### Added — Frontend

| 파일 | 내용 |
|------|------|
| `lib/features/schedule/data/model/schedule_model.dart` | ScheduleModel, categoryColor() static (11개 카테고리 색상 매핑) |
| `lib/features/schedule/presentation/notifier/schedule_notifier.dart` | sealed state, loadSchedules/createSchedule/deleteSchedule/changeMonth |
| `lib/features/schedule/presentation/screen/schedule_screen.dart` | TableCalendar 다크 테마, 카테고리 색상 마커, _ScheduleFormBottomSheet(FAB) |
| `lib/features/roadmap/data/model/roadmap_step_model.dart` | RoadmapStepModel, stepIcon/stepColor/defaultTitle/dDayText static |
| `lib/features/roadmap/data/model/hall_tour_model.dart` | HallTourModel |
| `lib/features/roadmap/presentation/notifier/roadmap_notifier.dart` | 낙관적 toggleDone/deleteStep |
| `lib/features/roadmap/presentation/screen/roadmap_screen.dart` | 9단계 카드 리스트, _StepDetailBottomSheet(stepType 분기 9종) |

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `pubspec.yaml` | `table_calendar: ^3.1.2` 추가 |
| `lib/core/router/app_router.dart` | AppRoutes.schedule = '/schedule', AppRoutes.roadmap = '/roadmap' 추가 |
| `lib/features/home/presentation/screen/home_screen.dart` | 메뉴 그리드 5개 → 6개 (3열 2행), "웨딩 관리" 버튼(Icons.auto_awesome, 0xFFF472B6) 추가, index 0 → /schedule, index 5 → /roadmap |

### Security — Backend

| 항목 | 내용 |
|------|------|
| category @Pattern | 한글/영문/숫자 1~30자 화이트리스트 |
| description/location @Size | max=1000/200 |
| alertBefore @Pattern | 화이트리스트 (NONE|5M|15M|30M|1H|1D 등) |
| stepType @Pattern | BUDGET|HALL|PLANNER|DRESS|HOME|TRAVEL|GIFT|SANGGYEONRYE|ETC |
| details @Size | max=2000 |
| rentalFee/mealPrice @Max | 9_999_999_999L |
| minGuests @Min/@Max | 1~10000 |
| memo @Size | max=500 |
| findByOidAndOwnerOid() | existsBy+findById 이중 조회 → 단일 조건 쿼리로 TOCTOU 방지 |

### Key Design Decisions

| 결정 | 이유 |
|------|------|
| RoadmapStep.details: TEXT/JSON | 단계 유형별 서브 테이블 9개 생성 대신 TEXT 컬럼에 JSON 저장 → 스키마 단순화, stepType별 분기는 서비스 레이어에서 처리 |
| createScheduleInternal() | 웨딩홀 투어 저장 시 일정 자동 등록을 위해 ownerOid 직접 파라미터로 받는 내부 메서드 분리 |
| deleteStep() 연쇄 삭제 순서 | hall_tours(+ 연결 일정) → travel_stops → schedules(source_oid) → step — FK 없는 환경에서 고아 레코드 방지 |
| 9단계 자동 생성 | DataInitializer에서 커플 생성 직후 9단계 기본 로드맵 자동 생성 → 신규 커플 온보딩 UX 개선 |

---

## [5.1단계] 예산 화면 UX 개선 — 전체 예산 다이얼로그 전환 (2026-03-19)

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `lib/features/budget/presentation/screen/budget_screen.dart` | `_buildTotalBudgetSetupScreen()` 메서드 및 `_setupAmountCtrl` State 필드 제거 — 설정 전용 전체 화면 폐지 |
| `lib/features/budget/presentation/screen/budget_screen.dart` | `showModalBottomSheet` → `showDialog + Center + Dialog` 패턴으로 전체 예산 다이얼로그 화면 중앙 배치, `SingleChildScrollView + viewInsets.bottom` 키보드 대응 |
| `lib/features/budget/presentation/screen/budget_screen.dart` | 요약 카드 전체 예산 행 항상 표시 — 미설정 시 "설정하기" 초록 칩, 설정 시 금액 + 수정 아이콘 |
| `lib/features/budget/presentation/screen/budget_screen.dart` | TextField 입력 텍스트 색상 `_kText(흰색)` → `Colors.black87`, hint `Colors.black45`, suffix `Colors.black54` |

### Fixed — Frontend

| 버그 | 증상 | 원인 | 해결 |
|------|------|------|------|
| 빈 상태 전체 예산 UI 사라짐 | 모든 카테고리 삭제 후 전체 예산 설정/수정 버튼이 노출되지 않음 | `!isConfigured` 조건부 렌더링으로 빈 상태에서만 설정 버튼 표시하던 로직 오류 | 항상 전체 예산 설정 버튼 노출, 설정 여부에 따라 표시 텍스트/아이콘만 분기 |

### Key Design Decisions

| 결정 | 이유 |
|------|------|
| 설정 전용 화면 폐지, 다이얼로그 통합 | 자동 화면 전환은 UX 맥락 단절 유발 — 항상 동일 화면에서 다이얼로그로 설정/수정 처리 |
| Dialog 위젯 TextField 텍스트 흑색 | Dialog 기본 배경이 흰색이므로 다크 글래스모피즘 화면과 별도로 텍스트 색상 지정 필요 |

---

## [5단계 추가] 예산 솔로 허용 + TextField dispose 버그 수정 (2026-03-18)

### Changed — Backend

| 파일 | 변경 내용 |
|------|---------|
| `domain/budget/entity/Budget.java` | `couple_oid` → `owner_oid` (솔로=userOid, 커플=coupleOid 공용) |
| `domain/budget/repository/BudgetRepository.java` | `findByCoupleOid` → `findByOwnerOid`, `countByCoupleOid` → `countByOwnerOid` |
| `domain/budget/service/BudgetService.java` | `requireCoupleOid()` → `getOwnerOid()` (커플 미연결 시 userOid 반환, 솔로 허용) |
| `common/exception/ErrorCode.java` | BUDGET_003(COUPLE_REQUIRED) 미사용 처리 — 코드는 유지, 서비스에서 미호출 |
| `resources/scripts/schema.sql` | `weddy_budgets.couple_oid` → `owner_oid` 컬럼명 변경 |

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `lib/features/budget/presentation/notifier/budget_notifier.dart` | `BudgetLoaded.isCoupleRequired` 필드 제거 |
| `lib/features/budget/presentation/screen/budget_screen.dart` | 커플 미연결 안내 UI 제거, 빈 목록 시 "첫 예산 카테고리 추가" 안내로 단순화 |
| `lib/features/home/presentation/screen/home_screen.dart` | 예산 섹션 안내 문구 "파트너 연결" → "첫 예산 카테고리 추가" |

### Fixed — Frontend

| 버그 | 증상 | 원인 | 해결 |
|------|------|------|------|
| TextField dispose 크래시 | 다이얼로그 닫힐 때 "used after disposed" 에러, `_dependents.isEmpty` assertion 실패 | `.then()` + `addPostFrameCallback`에서 로컬 TextEditingController 수동 dispose 시 exit 애니메이션 중 크래시 | `_showAddBudgetDialog`, `_showAddItemDialog` 두 곳의 `.then()` dispose 블록 제거 (로컬 변수는 GC 자동 정리) |

### Key Design Decisions

| 결정 | 이유 |
|------|------|
| `owner_oid` 통합 컬럼 | 체크리스트 `getOwnerOid()` 패턴과 일치시켜 솔로/커플 공용 화면 단일화 |
| TextField 로컬 컨트롤러 GC 위임 | Flutter는 로컬 변수 컨트롤러를 GC가 정리하므로 다이얼로그 `.then()`에서 수동 dispose 불필요 |

---

## [5단계] 예산 CRUD API + Flutter 예산 화면 (2026-03-17)

### Added — Backend

| 파일 | 내용 |
|------|------|
| `domain/budget/entity/Budget.java` | 예산 엔티티 (oid PK, couple_oid INDEX, category, planned_amount) |
| `domain/budget/entity/BudgetItem.java` | 예산 항목 엔티티 (oid PK, budget_oid INDEX, title, amount, memo, paid_at) |
| `domain/budget/repository/BudgetRepository.java` | JPA Repository (countByCoupleOid 포함) |
| `domain/budget/repository/BudgetItemRepository.java` | JPA Repository (findAllByBudgetOidIn IN 쿼리) |
| `domain/budget/dto/request/` | CreateBudgetRequest, CreateBudgetItemRequest, UpdateBudgetItemRequest |
| `domain/budget/dto/response/` | BudgetResponse(coupleOid 미노출), BudgetItemResponse(budgetOid 미노출), BudgetSummaryResponse |
| `domain/budget/service/BudgetService.java` | requireCoupleOid(커플 미연결→403), 소유권 3단계 검증, N+1 방지(IN 쿼리), 생성 20개 한도 |
| `domain/budget/controller/BudgetController.java` | 7개 엔드포인트 |

**API 엔드포인트**

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/api/v1/budgets` | 전체 목록 + 항목 조회 |
| POST | `/api/v1/budgets` | 예산 카테고리 생성 (20개 한도) |
| DELETE | `/api/v1/budgets/{oid}` | 삭제 (항목 포함) |
| POST | `/api/v1/budgets/{oid}/items` | 항목 추가 |
| PATCH | `/api/v1/budgets/{oid}/items/{itemOid}` | 항목 수정 (null=기존값 유지) |
| DELETE | `/api/v1/budgets/{oid}/items/{itemOid}` | 항목 삭제 |
| GET | `/api/v1/budgets/summary` | 전체 예산 요약 (총계획/총지출/카테고리별) |

**ErrorCode 추가**

| 코드 | 의미 |
|------|------|
| BUDGET_001 | NOT_FOUND — 예산 없음 또는 소유권 없음 |
| BUDGET_002 | ITEM_NOT_FOUND — 항목 없음 또는 소유권 없음 |
| BUDGET_003 | COUPLE_REQUIRED — 커플 미연결 (솔로 사용자 접근 불가) |
| BUDGET_004 | LIMIT_EXCEEDED — 예산 카테고리 20개 초과 |

### Changed — Backend

| 파일 | 변경 내용 |
|------|---------|
| `common/exception/ErrorCode.java` | BUDGET_001~004 추가 |
| `resources/scripts/schema.sql` | weddy_budgets/weddy_budget_items updated_at 컬럼 추가, title VARCHAR(200) 수정 |

### Security — Backend

| 항목 | 내용 |
|------|------|
| 금액 오버플로우 방지 | `@Max(9_999_999_999L)` 추가 |
| IDOR 방어 | BudgetResponse coupleOid 제거, BudgetItemResponse budgetOid 제거 |
| XSS/인젝션 방지 | category, title `@Pattern` 추가 |
| 미래 날짜 차단 | paidAt `@PastOrPresent` 추가 |
| DoS 방지 | 예산 카테고리 20개 생성 한도 |
| 로그 마스킹 | 로그에서 coupleOid 제거 |

### Added — Frontend

| 파일 | 내용 |
|------|------|
| `lib/features/budget/data/model/budget_item_model.dart` | BudgetItemModel |
| `lib/features/budget/data/model/budget_model.dart` | BudgetModel (usageRatio getter) |
| `lib/features/budget/data/model/budget_summary_model.dart` | BudgetSummaryModel |
| `lib/features/budget/presentation/notifier/budget_notifier.dart` | sealed state (BudgetLoaded isCoupleRequired 필드), budgetSummaryProvider |
| `lib/features/budget/presentation/screen/budget_screen.dart` | 요약 카드 + Accordion + Dismissible, 커플 미연결 안내 UI |

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `lib/core/router/app_router.dart` | AppRoutes.budget = '/budget' 추가 |
| `lib/features/home/presentation/screen/home_screen.dart` | 예산 섹션 실제 API 연동, 메뉴 탭(인덱스 1) /budget 라우팅 |

### Key Design Decisions

| 결정 | 이유 |
|------|------|
| spentAmount 인메모리 스트림 합산 | DB SUM 쿼리 없이 서비스 레이어에서 BudgetItem.amount 합산 → 쿼리 수 최소화 |
| getSummary() N+1 방지 | `findAllByBudgetOidIn()` 단일 IN 쿼리로 전체 항목 한 번에 조회 |
| BudgetLoaded(isCoupleRequired:) | 403 커플 미연결 vs 정상 빈 목록 UI 분기를 sealed state 내 필드로 처리 |
| requireCoupleOid() | 솔로 사용자 접근 불가 커플 전용 기능 — 체크리스트 getOwnerOid()와 달리 솔로 불허 |

### Backlog Added

| 항목 | 우선순위 |
|------|----------|
| 예산 카테고리 수정 API 미구현 (PATCH /api/v1/budgets/{oid}) | LOW |

---

## [4.1단계] 홈 체크리스트 섹션 개선 — 제목 표시 + 섹션 직접 이동 (2026-03-16)

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `lib/features/checklist/presentation/notifier/checklist_notifier.dart` | `checklistPreviewProvider` 반환 타입 `List<ChecklistItemModel>` → `List<ChecklistModel>`, 호출 엔드포인트 `/home-preview` → `/checklists` (3개 slicing) |
| `lib/core/router/app_router.dart` | `/checklist` 라우트에 쿼리 파라미터(`?target=<oid>`) 지원 추가, `ChecklistScreen(targetOid:)` 전달 |
| `lib/features/checklist/presentation/screen/checklist_screen.dart` | `targetOid` 파라미터 추가, `Map<String, GlobalKey> _sectionKeys` 로 섹션별 키 관리, `_scrollToTarget()` 구현, `SliverChildBuilderDelegate` → `SliverChildListDelegate` 교체 |
| `lib/features/home/presentation/screen/home_screen.dart` | import 교체(`checklist_item_model` → `checklist_model`), `_PreviewChecklistTile` → `_PreviewChecklistCard` (제목·카테고리 배지·X/Y 진행률·화살표), 카드 탭 시 `?target=` 쿼리로 해당 섹션 직접 이동, 미사용 유틸 함수 제거 |

### Added Patterns

| 패턴 | 설명 |
|------|------|
| `Scrollable.ensureVisible` + `GlobalKey` | `SliverChildListDelegate`(eager build) 로 GlobalKey 즉시 등록 → `ref.listen` 에서 `ChecklistLoaded` 감지 시 `addPostFrameCallback` 으로 스크롤 예약, `_hasScrolledToTarget` 플래그로 최초 1회만 실행 |
| GoRouter 쿼리 파라미터 | 화면 이동 시 `context.push('/path?key=value')`, 수신 측 `state.uri.queryParameters['key']` |

---

## [4단계] 체크리스트 CRUD API + Flutter 화면 (2026-03-15, 커밋 b0168fa)

### Added — Backend

| 파일 | 내용 |
|------|------|
| `domain/checklist/entity/Checklist.java` | 체크리스트 엔티티 (oid PK, couple_oid 인덱스, weddy_ 접두사) |
| `domain/checklist/entity/ChecklistItem.java` | 체크리스트 항목 엔티티 (oid PK, checklist_oid 인덱스) |
| `domain/checklist/repository/ChecklistRepository.java` | JPA Repository |
| `domain/checklist/repository/ChecklistItemRepository.java` | JPA Repository |
| `domain/checklist/service/ChecklistService.java` | 소유권 3단계 검증 (커플→체크리스트→항목) |
| `domain/checklist/controller/ChecklistController.java` | 7개 엔드포인트 |

**API 엔드포인트**

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/api/v1/checklists` | 전체 목록 + 항목 조회 |
| POST | `/api/v1/checklists` | 체크리스트 생성 |
| DELETE | `/api/v1/checklists/{oid}` | 삭제 (항목 포함) |
| POST | `/api/v1/checklists/{oid}/items` | 항목 추가 |
| PATCH | `/api/v1/checklists/{oid}/items/{itemOid}` | 항목 수정 (null=기존값 유지) |
| DELETE | `/api/v1/checklists/{oid}/items/{itemOid}` | 항목 삭제 |
| GET | `/api/v1/checklists/home-preview` | 미완료 항목 최신 3개 (홈 화면용) |

**ErrorCode 추가**

| 코드 | 의미 |
|------|------|
| CHECKLIST_001 | NOT_FOUND — 체크리스트 없음 또는 소유권 없음 |
| CHECKLIST_002 | ITEM_NOT_FOUND — 항목 없음 또는 소유권 없음 |

### Added — Frontend

| 파일 | 내용 |
|------|------|
| `lib/features/checklist/data/model/checklist_item_model.dart` | ChecklistItemModel (dueDate .toLocal() KST 보정) |
| `lib/features/checklist/data/model/checklist_model.dart` | ChecklistModel |
| `lib/features/checklist/presentation/notifier/checklist_notifier.dart` | sealed state, 낙관적 토글, checklistPreviewProvider |
| `lib/features/checklist/presentation/screen/checklist_screen.dart` | Dark Glass 테마, Accordion, Dismissible, 카테고리 생성 다이얼로그 |

### Changed — Frontend

| 파일 | 변경 내용 |
|------|---------|
| `lib/core/router/app_router.dart` | /checklist 라우트 추가 |
| `lib/features/home/presentation/screen/home_screen.dart` | _buildChecklistSection 목업 → 실제 API 연동, 더보기 → context.push('/checklist') |

### Fixed (lead-code-validator 검수 반영)

| 버그 | 원인 | 해결 |
|------|------|------|
| updateItem() DB 중복 조회 | 소유권 검증 시 checklist를 DB에서 재조회 | 인메모리 checklistOid 비교로 대체 |
| toggleItem() 에러 상태 경쟁 조건 | loadChecklists() 후 state 덮어씀 | 에러 메시지 먼저 저장 → loadChecklists() → state = ChecklistError 순서 보장 |
| dueDate D-DAY 1일 오차 | DateTime.parse가 UTC로 파싱 | .toLocal() 추가로 KST 변환 |

---

## [3.4단계] 보안 백로그 처리 (2026-03-15)

### Security — 6개 항목 처리 완료

| 항목 | 우선순위 | 내용 |
|------|----------|------|
| CoupleResponse IDOR 선제 차단 | MEDIUM | groomOid / brideOid 응답 필드 제거 (BE + FE couple_model.dart 동시 수정) |
| handPhone @Pattern 검증 | MEDIUM | `^01[016789]-?\d{3,4}-?\d{4}$` 패턴 추가 (유효하지 않은 번호 400 반환) |
| disconnectCouple 연관 삭제 순서 | MEDIUM | checklist_items → checklists → budget_items → budgets → couple_favorites → couples 순서 보장 |
| Swagger 운영 비활성화 | MEDIUM | `application.yml` 기본 `springdoc.api-docs.enabled: false`, `application-dev.yml`에서만 `true` |
| 로그인 성공 로그 마스킹 | LOW | `maskUserId()` 헬퍼: 앞 3자리 + `***` (예: `gro***`) |
| JWT_SECRET 폴백 제거 | 추가 | `${JWT_SECRET}` 환경변수 필수화, CORS allowed-origins 동일 처리 |

### Changed

| 파일 | 변경 내용 |
|------|---------|
| `domain/user/dto/request/SignUpRequest.java` | handPhone `@Pattern(regexp = "^01[016789]-?\\d{3,4}-?\\d{4}$")` 추가 |
| `domain/couple/dto/response/CoupleResponse.java` | groomOid, brideOid 필드 제거 |
| `domain/couple/service/CoupleService.java` | disconnectCouple() 연관 삭제 순서 명시 + maskUserId() 헬퍼 추가 |
| `domain/user/service/UserService.java` | 로그인 성공 로그 maskUserId() 적용 |
| `resources/application.yml` | springdoc 비활성화 기본값, JWT_SECRET 폴백 제거, CORS_ALLOWED_ORIGINS 필수화 |
| `resources/application-dev.yml` | springdoc.api-docs.enabled: true 추가 |
| `lib/features/couple/data/model/couple_model.dart` | groomOid, brideOid 필드 제거 |

### 잔여 보안 백로그

| 항목 | 우선순위 | 비고 |
|------|----------|------|
| CoupleService 역할 검증 (GROOM+GROOM 방지) | MEDIUM | 4단계 전 처리 필요 |
| jwt.expiration 30분 단축 | LOW | 클라이언트 토큰 갱신 로직 영향도 검토 필요 |

---

## [3.3단계] 다크 글래스모피즘 UI 전면 개편 (2026-03-15)

### Frontend — 디자인 시스템 전환: Light Glass → Dark Glassmorphism

| 파일 | 변경 내용 |
|------|---------|
| `features/auth/presentation/screen/login_screen.dart` | 딥 다크 배경(`#0D0D1A→#1B0929`), BackdropFilter glass 카드, dark glass 입력/소셜 버튼 |
| `features/auth/presentation/screen/sign_up_screen.dart` | 동일 다크 글래스 구조, 역할 칩 핑크 glass 선택 효과 |
| `features/home/presentation/screen/home_screen.dart` | 구조 개편 + 전체 다크 배경 (상세 아래 참조) |
| `features/wedding_setup/presentation/screen/wedding_date_setup_screen.dart` | dark glass 카드, 다크 휠 피커(white 텍스트) |

**새 디자인 시스템**
- 배경: `#0D0D1A → #1B0929` 딥 다크 그라디언트
- 카드: `ClipRRect(16) → BackdropFilter(blur:20) → Container(0x0F~0x14FFFFFF)` 3-레이어 glass
- 테두리: `Color(0x38FFFFFF)` white 22%, 핑크 glow 그림자 유지
- 텍스트 주: `Colors.white`, 보조: `Color(0xAAFFFFFF)` white 67%
- 입력 필드: `Color(0xFF1E1B33)` 일반 / `Color(0xFF2A2550)` 포커스 (명시적 다크 색상)
- 아이콘 박스: `Color(0x33EC4899)` 핑크 20%

**home_screen.dart 구조 개편**

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| 파트너 연결 UI | `_PartnerConnectCard` (인라인) | `_PartnerInviteButton` + `_PartnerConnectModal` (showGeneralDialog 중앙 애니메이션) |
| 메뉴 레이아웃 | 가로 스크롤 5메뉴 | `GridView.builder(crossAxisCount:3)` 3열 그리드 6메뉴 |
| 진행률 표시 | 별도 카드 섹션 | 헤더 인라인 0% 표시로 축소 |
| 신규 섹션 | — | 웨딩 체크리스트 섹션 (`_ChecklistTile`, 더보기 링크) |
| 신규 섹션 | — | 웨딩 타임라인 섹션 (`_TimelineTile`, IntrinsicHeight dot+line 구조) |
| 커플 연결 후 헤더 | 기본 그리팅 | `'{groom} ♥ {bride} 예비부부님 오늘도 알차게 준비해봐요!'` |

**아이콘 색상 체계**
| 메뉴 | 색상 |
|------|------|
| 일정 관리 | 파랑 (Blue) |
| 예산 관리 | 에메랄드 (Emerald) |
| 업체 관리 | 앰버 (Amber) |
| 하객 관리 | 퍼플 (Purple) |
| 가전·혼수 | 사이안 (Cyan) |
| 파트너 연결 | 핑크 (Pink) |

### Fixed

| 버그 | 원인 | 해결 |
|------|------|------|
| 모달 내 SnackBar 미표시 | showGeneralDialog 내 BuildContext가 Scaffold 외부 | scaffoldContext 파라미터 패턴으로 부모 context 전달 |
| RenderFlex overflow (invite code) | Text 위젯 고정 폭 초과 | Flexible 래핑 + fontSize 26→22 축소 |
| dead_null_aware_expression 경고 | null 체크 불필요한 위치 | 경고 발생 표현식 제거 |

---

## [3.3-hotfix] initState 인증 체크 + Dio 404 정상 처리 (2026-03-15)

### Fixed

| 버그 | 증상 | 원인 | 해결 |
|------|------|------|------|
| 미인증 상태 HomeScreen 401 cascade | 앱 시작 시 토큰 없는 상태에서 GET /couples/me → 401 → 강제 로그아웃 루프 | GoRouter 리다이렉트 전 initState가 잠깐 실행되어 loadMyCouple() 호출됨 | initState 첫 줄에 `if (ref.read(authNotifierProvider) is! AuthAuthenticated) return;` 추가 |
| 커플 미연결 사용자 SEVERE 에러 로그 | 로그인 후 GET /couples/me → 404 → _ErrorInterceptor SEVERE 로그 | 404가 DioException으로 처리되어 에러 인터셉터를 거침 | `Options(validateStatus: (s) => s != null && s < 500)` 으로 에러 인터셉터 우회, 404 수신 시 CoupleNotConnected 상태로 조용히 전환 |

### Changed
| 파일 | 변경 내용 |
|------|---------|
| `features/home/presentation/screen/home_screen.dart` | initState: AuthAuthenticated 상태 확인 후에만 loadMyCouple() 호출 |
| `features/couple/presentation/notifier/couple_notifier.dart` | loadMyCouple(): validateStatus 옵션 추가 (404 에러 인터셉터 우회) |

---

## [2단계] 인증 시스템 구현

### Backend
| 파일 | 내용 |
|------|------|
| `domain/user/entity/User.java` | 사용자 엔티티 (oid PK, BCrypt 비밀번호, 초대코드) |
| `domain/user/entity/UserRole.java` | GROOM / BRIDE Enum |
| `domain/user/entity/RefreshToken.java` | 리프레시 토큰 엔티티 (user_oid UNIQUE) |
| `domain/user/repository/UserRepository.java` | JPA Repository (existsByUserId, findByUserId 등) |
| `domain/user/repository/RefreshTokenRepository.java` | JPA Repository (findByUserOid, deleteByUserOid 등) |
| `domain/user/dto/request/SignUpRequest.java` | 회원가입 요청 DTO |
| `domain/user/dto/request/LoginRequest.java` | 로그인 요청 DTO |
| `domain/user/dto/request/TokenRefreshRequest.java` | 토큰 갱신 요청 DTO |
| `domain/user/dto/response/AuthResponse.java` | 인증 응답 DTO (accessToken, refreshToken, userOid) |
| `domain/user/dto/response/UserResponse.java` | 사용자 정보 응답 DTO |
| `domain/user/service/UserService.java` | 회원가입·로그인·토큰갱신·내정보조회 비즈니스 로직 |
| `domain/user/controller/AuthController.java` | POST /api/v1/auth/{signup, login, refresh, logout} |
| `domain/user/controller/UserController.java` | GET /api/v1/users/me |
| `common/security/WeddyUserDetailsService.java` | username = userOid 기반 UserDetails 구현 |
| `common/security/SecurityConfig.java` | Spring Security 설정 (JWT + DaoAuthenticationProvider) |
| `common/security/JwtTokenProvider.java` | JWT 발급·검증 (accessToken 24h, refreshToken 7d) |
| `common/security/JwtAuthenticationFilter.java` | 요청마다 토큰 검증 및 SecurityContext 주입 |

### Frontend
| 파일 | 내용 |
|------|------|
| `lib/features/auth/data/model/auth_response.dart` | AuthResponse 모델 |
| `lib/features/auth/data/model/user_model.dart` | UserModel |
| `lib/features/auth/data/model/sign_up_request.dart` | SignUpRequest 모델 |
| `lib/features/auth/data/datasource/auth_remote_datasource.dart` | 인증 API 호출 |
| `lib/features/auth/data/repository/auth_repository_impl.dart` | Repository 구현체 |
| `lib/features/auth/domain/repository/auth_repository.dart` | Repository 추상 인터페이스 |
| `lib/features/auth/presentation/notifier/auth_notifier.dart` | AuthState(sealed) + AuthNotifier(Riverpod) |
| `lib/features/auth/presentation/screen/login_screen.dart` | 로그인 화면 |
| `lib/features/auth/presentation/screen/sign_up_screen.dart` | 회원가입 화면 |
| `lib/core/router/app_router.dart` | go_router + _AuthStateListenable 어댑터 |
| `lib/main.dart` | ProviderScope + unauthorizedCallbackProvider override |

---

## [2.5단계] 보안·환경·UI 개선 (2026-03-12)

### 1. Flutter 환경 설정 — flutter_dotenv 적용

**목적**: 서버 주소 등 설정값을 코드에서 분리, Dev/Prod 환경 구분

| 파일 | 변경 내용 |
|------|-----------|
| `pubspec.yaml` | `flutter_dotenv: ^5.2.1` 추가, assets 섹션 등록 |
| `.env` | Dev 환경 설정 (`API_BASE_URL=http://10.0.2.2:8080/api/v1`) |
| `.env.production` | Prod 환경 설정 |
| `.env.example` | 팀 공유용 템플릿 (커밋 허용) |
| `.gitignore` | `.env` 파일 제외 규칙 추가 |
| `lib/main.dart` | `dotenv.load(fileName: envFile)` 초기화 추가 |
| `lib/core/network/dio_client.dart` | `_baseUrl`을 dotenv 참조로 교체 |

**빌드 커맨드**
```bash
flutter run                                         # Dev (.env 사용)
flutter build apk --dart-define=FLAVOR=production   # Prod (.env.production 사용)
```

---

### 2. 비밀번호 암호화 — BCrypt(strength=12)

**목적**: OWASP 권고 방식인 BCrypt 적용 (SHA-512는 GPU 크래킹에 취약)

| 파일 | 변경 내용 |
|------|-----------|
| `common/security/SecurityConfig.java` | `BCryptPasswordEncoder(12)` 빈 등록 |
| `domain/user/service/UserService.java` | `passwordEncoder.encode()` / `matches()` 사용 |
| `common/init/DataInitializer.java` | `PasswordEncoder` 주입 → 런타임에 BCrypt 해시 생성 |

---

### 3. UI 테마 — Light Green + 로고

**목적**: 옅은 초록색 계열 테마 적용, 로고 이미지 연동

| 파일 | 변경 내용 |
|------|-----------|
| `lib/main.dart` | `seedColor: 0xFF22C55E` (Green-500) 전면 교체, AppBar/Button/Input/Card 테마 통일 |
| `lib/features/auth/presentation/screen/login_screen.dart` | `_WeddyLogo` 위젯 재설계 — `assets/images/logo.jpg` 사용, 로드 실패 시 텍스트 fallback |
| `assets/images/logo.jpg` | `D:/workspace/weddy/images/default.jpg` 복사 배치 |

**테마 컬러 팔레트**
| 역할 | 색상 |
|------|------|
| Primary Seed | `#22C55E` (Green-500, 로고 동일) |
| Scaffold 배경 | `#F0FDF4` (Green-50) |
| AppBar 전경 | `#15803D` (Green-700) |
| Input 포커스 테두리 | `#22C55E` (width 2) |
| Card 테두리 | `#BBF7D0` (Green-200) |

---

### 4. DB 초기화 스크립트 정비

| 파일 | 변경 내용 |
|------|-----------|
| `scripts/schema.sql` | `SET FOREIGN_KEY_CHECKS=0`, `DROP TABLE IF EXISTS` (자식→부모 역순) |
| `scripts/data.sql` | `DELETE FROM` (자식→부모 역순), 업체 데이터 삽입 |

---

### 5. 보안 패치 — 6개 항목

#### 5-1. 로그인 사용자 열거 방지
- `UserService.login()`: 사용자 미존재 시 `USER_NOT_FOUND` → `UNAUTHORIZED` 통일
- 타이밍 공격 방지: 사용자 없어도 더미 `encode()` 연산 수행

#### 5-2. JWT Secret 관리 강화
- `application.yml`: 하드코딩 폴백 제거 → 환경변수 전용
- `JwtTokenProvider` 생성자: 32자(UTF-8 바이트) 미만 시 기동 즉시 실패
- `application-dev.yml` 생성 (개발용 자격증명 분리, `.gitignore` 등록)

#### 5-3. Rate Limiting
| 항목 | 내용 |
|------|------|
| 라이브러리 | `bucket4j-core:8.10.1` + `caffeine:3.1.8` |
| 적용 경로 | `/api/v1/auth/login`, `/api/v1/auth/signup`, `/api/v1/auth/refresh` |
| 정책 | IP + 경로 조합 키, 분당 최대 10회 (greedy refill) |
| 필터 위치 | `@Order(1)` — SecurityFilterChain 앞에서 실행 |
| 초과 응답 | HTTP 429 + `ApiResponse.fail("COMMON_429", ...)` |
| IP 스푸핑 방지 | `server.forward-headers-strategy: NATIVE` + `getRemoteAddr()` 사용 |

#### 5-4. CORS 환경별 설정
- `SecurityConfig.java`: 와일드카드(`allowedOriginPatterns("*")`) → `setAllowedOrigins()` 명시적 오리진
- `application.yml`: `cors.allowed-origins: ${CORS_ALLOWED_ORIGINS:...}` 환경변수 주입

#### 5-5. DataInitializer 프로파일 제한
- `@Profile("!test")` → `@Profile("dev")`: 운영·스테이징 환경에서 테스트 계정 생성 차단

#### 5-6. 운영 설정 기본값 안전화
- `jpa.show-sql: false` (dev에서는 `application-dev.yml`로 오버라이드)
- `logging.level: INFO` (dev에서는 DEBUG)

---

### 6. 테스트 데이터 초기화 — DataInitializer 확장

**목적**: 앱 기동 시 전체 테스트 데이터 자동 생성 (멱등 보장)

#### 생성 데이터 전체 목록

**사용자 (비밀번호 모두 `1234`)**
| userId | 이름 | 역할 | oid |
|--------|------|------|-----|
| groom_kim | 김지훈 | GROOM | 10000000000001 |
| bride_lee | 이수연 | BRIDE | 10000000000002 |
| solo_park | 박민지 | BRIDE (미연결) | 10000000000003 |

**커플**
- 김지훈 + 이수연 / 예식일 `2026-10-15` / 총 예산 5,000만원 / oid: 20000000000001

**체크리스트 (3카테고리, 13항목)**
| 카테고리 | oid | 완료 | 미완료 |
|----------|-----|------|--------|
| 예식장 준비 | 30000000000001 | 2개 | 3개 |
| 스드메 준비 | 30000000000002 | 2개 | 2개 |
| 신혼여행 준비 | 30000000000003 | 1개 | 2개 |

**예산 (4카테고리, 10항목)**
| 카테고리 | 계획 금액 | 지출 항목 | oid |
|----------|-----------|-----------|-----|
| 예식비 | 1,500만원 | 웨딩홀 대관료, 답례품, 사회자 | 40000000000001 |
| 스드메 | 1,000만원 | 촬영비, 드레스, 메이크업 | 40000000000002 |
| 신혼여행 | 800만원 | 항공권, 숙소 | 40000000000003 |
| 기타 | 500만원 | 예복, 혼수 가전 | 40000000000004 |

**즐겨찾기**: 그랜드 웨딩홀, 스튜디오 아이엘, 뷰티 아뜰리에

**웨딩 업체 (data.sql — 13개)**
| 카테고리 | 업체명 |
|----------|--------|
| HALL | 그랜드 웨딩홀, 더베뉴 웨딩홀, 파크 웨딩홀 |
| STUDIO | 스튜디오 아이엘, 스튜디오 화이트 |
| DRESS | 로맨티크 드레스샵, 웨딩드레스 하우스 |
| MAKEUP | 뷰티 아뜰리에, 브라이덜 스튜디오 |
| HONEYMOON | 발리 허니문 투어, 유럽 웨딩 트래블 |
| ETC | 웨딩 플래너 스튜디오, 플라워 웨딩 데코 |

---

### 7. DB 스키마 재설계 — FK 전면 제거

**원인**: `weddy_refresh_tokens` collation 미지정(`utf8mb4_0900_ai_ci`)으로
나머지 테이블(`utf8mb4_unicode_ci`)과 충돌 → `[HY000][3780]` FK 에러

**변경 내용**
| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| FK 제약 | 9개 CONSTRAINT FOREIGN KEY | **전부 제거** |
| 참조 무결성 | DB 레벨 | 애플리케이션 레이어 관리 |
| 관계 컬럼 인덱스 | FK 자동 생성 | `INDEX idx_*` 명시 추가 |
| `role` 컬럼 | `ENUM('GROOM','BRIDE')` | `VARCHAR(10)` |
| vendor `category` | `ENUM(...)` | `VARCHAR(20)` |
| collation | 테이블마다 상이 | **전 테이블 `utf8mb4_unicode_ci` 통일** |

---

## DB 리셋 및 기동 방법

```bash
# 1. DB 초기화 (MySQL 클라이언트)
source scripts/schema.sql
source scripts/data.sql

# 2. 앱 기동 (dev 프로파일 필수)
./gradlew bootRun --args='--spring.profiles.active=dev'
# → DataInitializer: 사용자·커플·체크리스트·예산·즐겨찾기 자동 생성
```

---

## 현재 아키텍처 주요 결정사항

| 항목 | 결정 | 이유 |
|------|------|------|
| 비밀번호 해시 | BCrypt(strength=12) | OWASP 권고, GPU 브루트포스 방어 |
| JWT | accessToken 24h + refreshToken 7d | DB Rotation 방식 |
| SecurityContext principal | userOid (String) | userId 변경 가능성 고려 |
| PK 방식 | SecureRandom 14자리 숫자 문자열 | IDOR 공격 예측 불가, auto-increment 비사용 |
| DB FK | 미사용 | 참조 무결성은 Service 트랜잭션에서 관리 |
| Flutter 환경 설정 | flutter_dotenv | Dev/Prod .env 파일 분리 |

---

## 다음 구현 단계

- **3단계**: 커플 연결 (Couple 엔티티 + 초대코드 API + Flutter 커플 연결 화면)
- **4단계**: 체크리스트 → 예산 → 즐겨찾기 (CRUD API + Flutter 화면)

---

## 보안 백로그 (추후 적용 권고)

| 우선순위 | 항목 |
|----------|------|
| MEDIUM | `SignUpRequest` handPhone `@Pattern` 검증 추가 |
| MEDIUM | Swagger 운영 환경 비활성화 (`springdoc.enabled: false`) |
| LOW | `jwt.expiration` 30분으로 단축 (현재 24시간) |
| LOW | 로그인 성공 로그 userId 마스킹 |
| LOW | iOS Keychain 접근성 `first_unlock_this_device` 강화 |

---

## [3단계] 홈 화면 구현 (2026-03-14)

### Added

| 파일 | 내용 |
|------|------|
| `lib/features/home/presentation/screen/home_screen.dart` | 홈 화면 전체 구성 — CustomScrollView + SliverAppBar(pinned) |

### HomeScreen 섹션 구성

| 섹션 | 위젯 | 설명 |
|------|------|------|
| AppBar | SliverAppBar | backgroundColor: _kPink, Playfair Display "WEDDY", 로그아웃 아이콘 |
| 섹션1 | `_InviteSection` | 초대코드 표시(user.inviteCode nullable), 복사 버튼, 핑크 그라디언트 버튼 |
| 섹션2 | `_ProgressSection` | 진행률 45%, LinearProgressIndicator, 통계(완료12/진행6/전체20) — 목업 static |
| 섹션3 | `_MenuGrid` | GridView 3열, 5개 메뉴(일정/예산/업체/하객/커뮤니티), 탭 시 "준비 중" SnackBar |
| 섹션4 | `_VendorSection` | StatefulWidget, 3탭(스튜디오/메이크업/드레스), 목업 업체 3개씩 |
| 섹션5 | `_LoveRankingSection` | 순위 5개, 1~3위 핑크/4~5위 회색 차등 표시 |

> 전체 데이터는 목업(정적) — 실제 API 연동은 추후 단계에서 처리

### Changed

| 파일 | 변경 내용 |
|------|-----------|
| `lib/main.dart` | seedColor `0xFF22C55E`(초록) → `0xFFEC4899`(핑크), scaffoldBackground `0xFFF0FDF4` → `0xFFFDF2F8` |
| `lib/core/router/app_router.dart` | `_HomeScreen`(임시 플레이스홀더) → 실제 `HomeScreen` 교체, errorBuilder도 동일 적용 |

### Fixed (lead-code-validator 검수 반영)

| 버그 | 원인 | 해결 |
|------|------|------|
| SliverAppBar 배경색 미적용 | `expandedHeight: 0` + `flexibleSpace` 조합 버그 | `backgroundColor: _kPink` 직접 지정 |
| `_showComingSoon` 3중 중복 정의 | 각 StatelessWidget 내부에 각각 선언 | top-level 함수로 통합 |

---

## [2.6단계] 버그 수정 (2026-03-14)

### Fixed — 로그인/회원가입 후 화면 전환 불가

| 파일 | 변경 내용 |
|------|-----------|
| `lib/features/auth/presentation/screen/login_screen.dart` | `ref.listen<AuthState>` 콜백에서 `AuthAuthenticated` 수신 시 `context.go(AppRoutes.home)` 직접 호출 |
| `lib/features/auth/presentation/screen/sign_up_screen.dart` | `ref.listen<AuthState>` 콜백에서 `AuthUnauthenticated` 전환 시 `context.go(AppRoutes.login)` 직접 호출 |
| `lib/features/auth/presentation/notifier/auth_notifier.dart` | `signup()` 완료 후 `AuthUnauthenticated` 설정 + `clearTokens` (자동 로그인 방지) |

- 원인: Riverpod 2.5.x에서 GoRouter `refreshListenable` + Provider 내부 `ref.listen` 조합이 불안정
- 해결: Screen 레이어에서 `ref.listen` + `context.go()` 직접 호출 패턴으로 전환

### Fixed — Flutter Web RenderFlex overflow

| 파일 | 변경 내용 |
|------|-----------|
| `lib/features/auth/presentation/screen/login_screen.dart` | `Text('계정이 없으신가요?')` → `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))` |

- 증상: `RenderFlex overflowed by 90 pixels on the right` at `login_screen.dart:164`

### Fixed — Flutter Web SubtleCrypto.OperationError (flutter_secure_storage)

| 파일 | 변경 내용 |
|------|-----------|
| `lib/core/storage/_local_storage.dart` (신규) | 웹 전용 `dart:html` localStorage 래퍼 |
| `lib/core/storage/_local_storage_stub.dart` (신규) | 비웹 플랫폼용 no-op 스텁 |
| `lib/core/storage/token_storage.dart` | Dart 조건부 임포트 + `kIsWeb` 분기: 웹은 localStorage, 네이티브는 flutter_secure_storage |

- 증상: 로그인 성공 후 `WebCrypto SubtleCrypto.OperationError` 발생
- 원인: `flutter_secure_storage`가 일부 Chrome 환경에서 Web Crypto API 호출 실패
- 해결: 플랫폼 조건부 임포트 (`dart.library.html`) + `kIsWeb` 런타임 분기

---

## [2.7단계] UI 전면 재설계 — 핑크 테마 (2026-03-14)

### Added — google_fonts 패키지

| 파일 | 변경 내용 |
|------|-----------|
| `pubspec.yaml` | `google_fonts: ^6.2.1` 추가 |

### Changed — 핑크 테마 전면 적용

**색상 팔레트**

| 상수 | 값 | 용도 |
|------|-----|------|
| `_kPink` | `#EC4899` | 주 색상 (Tailwind pink-500) |
| `_kDarkPink` | `#DB2777` | hover/dark (pink-600) |
| `_kLightPink` | `#FCE7F3` | 칩 선택 배경 (pink-100) |
| `_kBg` | `#FDF2F8` | Scaffold 배경 (연핑크) |
| `_kDark` | `#374151` | 회원가입 버튼 (gray-700) |
| `_kDarkHover` | `#1F2937` | 회원가입 버튼 hover (gray-800) |

**공통 UI 변경**

- 로고: 핑크 원형 배경 (76x76, 핑크 glow shadow) + 흰색 하트(38px) + 연핑크 하트(28px) Stack 레이어 조합
- WEDDY 텍스트: `google_fonts.PlayfairDisplay`, `Colors.black87`
- `_AnimatedField` 위젯: `FocusNode` 감지, 포커스 시 `AnimatedScale(1.012)` + glow 효과, prefix 아이콘 색상 전환
- 푸터: `© 2025 CJH. All rights reserved.`

### Changed — login_screen.dart

| 항목 | 변경 내용 |
|------|-----------|
| 로그인 버튼 (`_PinkButton`) | 핑크 그라디언트 (`#EC4899` → `#F9A8D4`), hover/press 애니메이션 |
| 소셜 로그인 버튼 | Google / Naver / Kakao 3종 (UI only, tap 시 "준비중" SnackBar) |
| Google G 로고 (`_GoogleGPainter`) | `CustomPainter` + `dart:math` — 4색 분할 원호 + 파란색 가로 바로 실제 G 마크 구현 |
| 회원가입 링크 | `TextButton` → 인라인 Row 스타일 ("아직 계정이 없으신가요? 회원가입") |

### Changed — sign_up_screen.dart

| 항목 | 변경 내용 |
|------|-----------|
| 역할 선택 칩 | 세로 카드 → 가로 compact 칩 (높이 44px, 이모지 + 텍스트 한 줄) |
| 칩 선택 색상 | `_kLightPink` 배경 + `_kPink` 테두리 + `_kDarkPink` 텍스트 |
| 회원가입 버튼 (`_DarkButton`) | 다크 그레이 솔리드 (`#374151`), hover 시 `#1F2937`, 그라디언트 없음 |
| 입력 필드 prefix 아이콘 | 아이디: person / 비밀번호: lock / 이름: badge / 휴대폰: phone / 이메일: email |
| 로그인 링크 | `TextButton` → 인라인 Row 스타일 ("이미 계정이 있으신가요? 로그인")

---

## [3.1단계] 결혼일 설정 화면 + 홈 화면 재설계 (2026-03-14)

### Added — 결혼 예정일 API (Backend)

| 파일 | 내용 |
|------|------|
| `domain/user/controller/UserController.java` | `PATCH /api/v1/users/me/wedding-date` 엔드포인트 추가 |
| `domain/user/dto/request/UpdateWeddingDateRequest.java` | `@NotNull`, `@JsonFormat(pattern="yyyy-MM-dd")` |
| `domain/user/service/UserService.java` | `updateWeddingDate()` — userOid 조회 → `user.updateWeddingDate()` → `UserResponse` 반환 |
| `domain/user/entity/User.java` | `updateWeddingDate(LocalDate weddingDate)` setter 메서드 추가 |

### Added — 결혼일 설정 플로우 (Frontend)

| 파일 | 내용 |
|------|------|
| `lib/features/wedding_setup/presentation/screen/wedding_date_setup_screen.dart` | DatePicker, "저장하기" / "나중에 설정하기" 버튼, WEDDY 로고 (Playfair Display) |
| `lib/features/wedding_setup/presentation/notifier/wedding_setup_notifier.dart` | PATCH 호출 + 성공 시 `authNotifier.refreshUser()` 로 UserModel 갱신 |

### Changed — 라우팅 (Frontend)

| 파일 | 변경 내용 |
|------|-----------|
| `lib/core/router/app_router.dart` | `AuthAuthenticated` + `weddingDate == null` + `skipped == false` → `/setup/wedding-date` 리다이렉트 로직 추가 |
| `lib/features/wedding_setup/presentation/notifier/wedding_setup_notifier.dart` | `weddingSetupSkippedProvider`: "나중에 설정하기" 시 true (앱 재시작마다 초기화) |

### Changed — 홈 화면 전면 재작성 (Frontend)

**테마**: 기존 핑크 라이트 → 다크 테마 (`#1C1C1E`), `CustomScrollView` → `SingleChildScrollView`

| 섹션 | 위젯/설명 |
|------|-----------|
| 헤더 | Playfair Display "W" 핑크 원형 + 시간대 그리팅 + 알림벨 |
| D-DAY 칩 | `weddingDate != null`이면 날짜 + D-숫자 표시 |
| `_PartnerConnectCard` | 초대코드 표시/복사, 파트너 코드 입력 + 연동 버튼, 연결 완료 시 `_buildConnectedView` |
| `_buildProgressCard` | 전체 진행률 0%, 마감임박/이번주/완료 통계 |
| `_buildQuickCards` | 일정/예산 2열 카드 |
| `_buildTipsSection` | 가로 스크롤 팁 카드 3개 |
| `_buildPopularSection` | 인기글 3개 (순위, 카테고리 태그, 좋아요/댓글) |
| `_DarkBottomNavBar` | 홈/예산/커뮤니티/더보기 4탭, 홈 외 탭은 "준비 중" SnackBar |

### Fixed

| 버그 | 해결 |
|------|------|
| HomeScreen 헤더 하트 아이콘 (WEDDY 브랜딩 누락) | Playfair Display "W" 텍스트로 교체 |

---