---
name: 버그 신고 (Bug Report)
about: 점검 보고서·매니페스트의 잘못된 결과·회귀 발견
labels: bug
---

## 환경

- Skill 버전: `<예: isms-p-audit@0.7.0>` (manifest.skill_version 값)
- 점검 환경:
  - OS: `<macOS 14 / Ubuntu 22.04 / WSL2>`
  - Claude Code 버전:
  - 외부 도구 (설치된 것만):
    - [ ] aws-cli
    - [ ] gcloud
    - [ ] az
    - [ ] prowler
    - [ ] tfsec / checkov / trivy / semgrep
- 점검 대상:
  - 레포 역할: `<frontend / backend / fullstack / infra / mobile / unknown>`
  - 주요 stack: `<예: Next.js + SST + Supabase>`

## 문제 설명

`<현재 어떤 결과가 나왔는지>`

## 기대 결과

`<무엇이 맞는 결과여야 했는지>`

## 재현 단계

1.
2.
3.

## 첨부 파일

- [ ] manifest 파일 (`.isms-audit/runs/<ts>.json`) — 민감정보 마스킹 후 첨부
- [ ] 보고서 파일 (`.isms-audit/reports/<ts>.md`) — 민감정보 마스킹 후 첨부

> ⚠️ AWS/GCP 자격증명·계정 ID·실제 IP 등 민감정보는 마스킹 (`<MASKED>` 또는 `XXX`) 후 첨부.

## 추가 정보

`<관련 BLOCKING 항목 / 영향받는 통제 ID / 회귀 의심 fix 버전 등>`
