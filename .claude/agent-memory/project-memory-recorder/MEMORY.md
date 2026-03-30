# Project Memory Recorder — Agent Memory

## 파일 경로 규칙
- 프로젝트 MEMORY.md: /c/Users/cjh/.claude/projects/D--workspace-weddy/memory/MEMORY.md
- 패턴 상세: /c/Users/cjh/.claude/projects/D--workspace-weddy/memory/patterns.md
- CHANGELOG.md: /d/workspace/weddy/CHANGELOG.md
- 항상 절대 경로 사용 (Windows bash에서 /c/, /d/ 마운트 포인트 사용)

## MEMORY.md 관리 원칙
- 200줄 한계 — 초과 시 상세 패턴을 patterns.md로 이동하고 요약 링크만 유지
- 구현 완료 항목은 단계별로 핵심만 압축 (3~6줄 이내)
- 보안 백로그는 [HIGH/MEDIUM/LOW] 태그 포함

## CHANGELOG.md 형식
- 섹션 구조: Added/Changed/Fixed/Security/Key Design Decisions
- 표 형식: | 파일 | 내용 | 또는 | 항목 | 내용 |
- 날짜는 YYYY-MM-DD

## 작업 시 주의사항
- 기존 파일 읽기 전에 절대 기록하지 않음
- 실제 구현된 내용만 기록, 계획은 '예정'으로 명시
- 보안 민감 정보(비밀번호, 토큰, 키) 절대 기록 금지
