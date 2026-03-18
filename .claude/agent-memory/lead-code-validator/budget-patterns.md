# Budget 기능 구현 패턴 (5단계)

## 검토 완료 (2026-03-17)

### [CRITICAL - 수정됨] schema.sql에 updated_at 컬럼 누락
- 엔티티에 @UpdateTimestamp(updated_at)가 있으면 schema.sql에도 반드시 컬럼 추가 필요
- ddl-auto: none 환경에서 누락 시 INSERT/UPDATE 시 "Unknown column 'updated_at'" SQL 오류 발생
- weddy_budgets, weddy_budget_items 모두 updated_at 추가로 수정 완료

### [CRITICAL - 수정됨] 엔티티 컬럼 length와 schema.sql VARCHAR 크기 불일치
- BudgetItem.title: @Column(length=200) vs schema.sql VARCHAR(100) → schema.sql을 VARCHAR(200)으로 수정
- 새 도메인 추가 시 엔티티 @Column 어노테이션과 schema.sql 컬럼 크기가 반드시 일치해야 함

### [IMPORTANT - 수정됨] getSummary() N+1 쿼리 패턴
- budgets.stream().flatMap(b -> budgetItemRepository.findByBudgetOidOrderByCreatedAtAsc(b.getOid()).stream())
  → 예산 카테고리 수만큼 SELECT 쿼리 발생
- 해결: BudgetItemRepository에 findAllByBudgetOidIn(@Query("... WHERE i.budgetOid IN :budgetOids")) 추가
  → 단일 IN 쿼리로 모든 항목 조회

### [IMPORTANT - 수정됨] Flutter sealed state에서 403(커플 미연결)과 정상 빈 목록 미구분
- BudgetLoaded([])가 403 응답과 실제 빈 목록 양쪽에 동일하게 사용 → UI 메시지 혼란
- 해결: BudgetLoaded에 isCoupleRequired: bool 필드 추가
  - 403 응답 시 BudgetLoaded([], isCoupleRequired: true)
  - 정상 빈 목록 시 BudgetLoaded([], isCoupleRequired: false) (기본값)
- 빈 상태 화면에서 isCoupleRequired에 따라 안내 메시지 분기 처리

### [MINOR - 수정됨] 다이얼로그 입력 필드 위젯 중복 정의
- _BudgetScreenState._buildDialogField와 _BudgetSectionState._dialogField가 완전히 동일한 코드
- 해결: top-level _buildBudgetDialogField()로 추출하여 두 State에서 공유

### [확인됨] 낙관적 업데이트 미구현 (deleteItem, deleteBudget)
- 체크리스트와 달리 budget의 deleteItem/deleteBudget은 낙관적 업데이트 없이 서버 응답 후 loadBudgets() 재조회
- 예산은 금액 집계 등 서버 계산 결과를 재사용하므로 재조회 방식이 더 안전하고 적절함
- 체크리스트의 toggle은 로컬 상태 변경만 필요하지만 예산 삭제는 집계 재계산이 필요함

### [확인됨] Budget 업데이트 API 미구현 (카테고리명/계획금액 수정)
- PATCH /api/v1/budgets/{budgetOid} 엔드포인트 없음
- 현재는 삭제 후 재생성이 유일한 수정 방법
- 6단계 이후 구현 권고 (현재 UI에서 수정 버튼 미노출로 사용자 영향 없음)

### [확인됨] UpdateBudgetItemRequest.memo null vs 빈 문자열
- null이면 기존 값 유지, ""이면 빈 문자열로 저장 → 의도적으로 memo를 지우려면 "" 전송
- 이 동작은 허용 가능하고 클라이언트에서 ""로 제어 가능
- 단, paidAt은 null=유지 패턴이어서 paidAt을 지우고 싶은 경우 별도 처리 필요

---

## 검토 완료 (2026-03-19) — 전체 예산 설정 기능

### [CRITICAL - 수정됨] _buildSummaryCard usageRatio clamp 후 isOver 판정 불가
- budget_screen.dart: `(totalSpent / denominator).clamp(0.0, 1.0)` 적용 후 `usageRatio > 1.0`을 검사
- clamp(0.0, 1.0)으로 인해 실제 초과 여부가 항상 false → 초과 시 빨간 표시/초과율 계산 모두 무동작
- 해결: rawRatio(클램프 전) / usageRatio(클램프 후 ProgressBar용) 분리
  - `isOver = rawRatio > 1.0`
  - 초과율 표시: `(rawRatio - 1.0) * 100`
  - ProgressBar value: `usageRatio` (클램프된 값)

### [IMPORTANT - 수정됨] _showEditTotalBudgetDialog에서 loadBudgets() 미호출
- upsertSettings 성공 후 ref.invalidate(budgetSettingsProvider)만 실행 → 요약 카드 집계 금액 미갱신
- 해결: ref.invalidate 후 budgetNotifierProvider.notifier.loadBudgets() 추가 호출

### [IMPORTANT - 수정됨] 다이얼로그 금액 하한 검증 불일치 (amount < 0 → amount < 1)
- _showAddBudgetDialog, _showAddItemDialog 양쪽에서 `amount < 0` 허용 → 0원 입력 가능
- 서버 @Min(value=1) 검증과 불일치 → 서버에서 400 반환됨
- 해결: `amount < 1`로 수정 (두 다이얼로그 모두)

### [MINOR - 수정됨] BudgetService.upsertSettings() orElseGet 블록 불필요한 totalAmount 초기화
- 신규 생성 시 빌더에서 `.totalAmount(req.getTotalAmount())` 설정 후 `settings.updateTotalAmount()` 재호출
- 기능 오류는 아니나 코드 중복. 빌더에서 totalAmount 제거, updateTotalAmount()로 일원화

### [확인됨] BudgetSettings @PrePersist oid 생성 정상
- orElseGet에서 빌더로 생성 시 oid를 지정하지 않으면 null → @PrePersist에서 OidGenerator.generate() 호출
- save() 호출 시점에 @PrePersist 트리거되므로 oid 생성 누락 없음 (정상)

### [확인됨] budgetSettingsProvider 파싱 패턴 차이 (budgetSummaryProvider와 비교)
- budgetSummaryProvider: ApiResponse 래퍼 클래스 사용 (ApiResponse.fromJson)
- budgetSettingsProvider: res.data 직접 파싱 (data['success'] == true && data['data'] != null)
- 두 패턴 모두 동작하나 팀 내 일관성을 위해 ApiResponse 래퍼 클래스 사용 권고 (향후 통일 필요)

### [확인됨] DataInitializer 주석/로그 체크리스트 항목 수 불일치 (11개→12개, 13개→12개) - 수정됨
- 클래스 Javadoc: "항목 11개" → 실제 insertChecklistItem 12개 호출. 수정: "항목 12개"
- log.info 메시지: "항목 13개 생성 완료" → 실제 12개. 수정: "항목 12개"
