# CHANGELOG

본 Skill 의 모든 주요 변경 사항을 기록합니다. [Semantic Versioning](https://semver.org/lang/ko/) 을 따릅니다.

## [0.7.0] - 2026-05-11 — 안정 릴리즈 (베타 공개)

### Added

- **Cross-framework mapping** (Phase 5.2) — ISMS-P 56 통제 × ISO 27001:2022 + NIST CSF 2.0 + SOC 2 TSC. `references/cross_framework_mapping.json` + controls.json 56 통제에 `cross_mappings` 필드 박제. 보고서 §1 비고 컬럼에 `(≈ ISO A.5.16, NIST CSF PR.AA-01, SOC 2 CC6.1)` 형식 자동 노출. 매핑 신뢰도: verified 38 / candidate 14 / partial 4.
- **pytest 자동 회귀 방어** (Phase 5.1) — `tests/test_skill_integrity.py` 51 tests (9 섹션: Schema / 데이터 / 참조 / Phase 3 / BLOCKING 키워드 / Stack / 카운트 / README / Cross-framework). GRC repo 패턴 차용.
- **GCP / Azure stack profile 4개** (Phase 3.3) — `gcp-cloud-run.json` / `gcp-cloud-sql.json` / `azure-app-service.json` / `azure-functions.json`. 총 stack profile 16 → 20.
- **GCP / Azure cloud_api 매핑** (Phase 3.2) — controls.json 의 52 cloud_api 시그널 중 41개에 `prowler_check_id_by_cloud` + `cloud_provider: "multi"` 박제. GCP 25 매핑 + Azure 36 매핑.
- **멀티클라우드 동의 흐름** (Phase 1) — `consent.cloud_providers` multi-select + per-cloud profile/project/subscription. `scan.sh` 의 GCP `available_projects[]` + Azure `available_subscriptions[]` prober.
- **README "ISMS-P 외 활용" 박스** — 글로벌 framework cross-mapping 실증 데이터 박제. SOC 2 / ISO 27001 / NIST CSF baseline 활용 안내.

### Changed (BLOCKING 19항 — v0.4.6 → v0.7.0)

- **v0.7-pre.1** — cross_mappings 보고서 §1 비고 컬럼 노출 BLOCKING (체크리스트 #19). 14차 dogfood 회귀 fix.
- **v0.6.5** — delta_vs prior 알고리즘 = `scan.ended_at` 내림차순 (mtime fallback). v0.6.4 의 파일명 lex sort 가 LLM 의 임의 timestamp 명명 환경에서 실패 (14차 dogfood 회귀). 15차 dogfood 검증.
- **v0.6.4** — skill_version 정확 시맨틱 (`MAJOR.MINOR.PATCH`) + delta_vs.previous_run 가장 최근 manifest 선택 BLOCKING.
- **v0.6.3** — unknown ↔ skipped 양쪽 박제 BLOCKING (cross-validation 발견 fix).
- **v0.6.2** — manifest 구조 schema 준수 BLOCKING (10차 회귀 fix — tools array, api_calls 객체, scan 필수 필드, findings_summary 부재).
- **v0.6.1** — prowler service-level 묶음 호출 패턴 + signals_evaluation_path BLOCKING + delta_vs 보고서 노출.
- **v0.6** — 멀티클라우드 기반 + AWS cloud_api 시그널 26 → 52 + Capability aspect 11개 신규.

### Fixed

- 14차 dogfood 의 v0.6.4 파일명 lex sort 회귀 → v0.6.5 에서 `scan.ended_at` 기반으로 fix
- 14차 dogfood 의 cross_mappings 보고서 노출 0건 → v0.7-pre.1 BLOCKING 으로 fix
- 13차 dogfood 의 skill_version truncated 회귀 (`"isms-p-audit@0.6"`) → v0.6.4 BLOCKING + 정규식 self-check 로 fix

### Dogfood 검증 (총 16회)

- 환경 A (Next.js + SST + Supabase + Sentry, AWS Seoul) 15회 + 환경 B (CDK + Lambda + ECS) 1회
- prowler 96% 활용 검증 (10~14차) + prowler 미설치 graceful degradation 검증 (15차)
- 모든 BLOCKING 19항 통과 + Schema validation 0 위반

---

## [0.6.3] - 2026-05-11

### Added

- unknown ↔ skipped 양쪽 박제 BLOCKING (체크리스트 #16) — cross-validation 발견 fix

### Changed

- BLOCKING 항목 15 → 16
- 13차 dogfood 검증 완료

---

## [0.6.2] - 2026-05-11

### Added

- manifest 구조 BLOCKING (§4.1 신설) — tools array, api_calls, scan 필수 필드, findings_summary 부재
- jsonschema validation self-check (`tests/` + 부록 C #13)

### Fixed

- 10차 dogfood 의 자율 형식 변경 17건 회귀 fix

---

## [0.6.1] - 2026-05-11

### Added

- **prowler 처음 정상 작동** (52건, 96%) — service-level 묶음 호출 패턴
- signals_evaluation_path BLOCKING (체크리스트 #13)
- delta_vs 보고서 §-1 노출 BLOCKING (체크리스트 #12)

### Fixed

- 1~9차 dogfood 모두 prowler timeout 회귀 → service-level 묶음 + `timeout: 600000` (10분) 명시
- aspect.result enum 완화 (`"fail"` 추가)

---

## [0.6] - 2026-05-11 — 멀티클라우드 기반

### Added

- AWS cloud_api 시그널 26 → 52 (Phase 2)
- Capability aspect 74 → 85 (+11 신규: database_storage_encrypted, ebs_encryption_default, vpc_flow_log_enabled, root_account_hardening 등)
- `consent.cloud_providers` multi-select

### Changed

- controls.schema.json — `commands_by_cloud` + `prowler_check_id_by_cloud` + `cloud_provider` 옵션 필드

---

## [0.5.1.2] - 2026-05-11

### Added

- delta_vs manifest 박제 BLOCKING — 8차 회귀 fix

---

## [0.5.1.1] - 2026-05-10

### Added

- 보고서 정량 일관성 5개 갭 fix (§-1 scope · 평가 경로 5축 · 101 vs 56 명시 · by_service 표 · delta_vs)

---

## [0.5.1] - 2026-05-10 — 레포 역할 인지

### Added

- scope 객체 (`repo_role` / `confidence` / `observable_controls[]` / `not_observable_controls[]`)
- §1 표에 `scope` 컬럼 + ⚪ N/A 분류

---

## [0.4.6] - 2026-05-10 — 보고서 격식 회복

### Changed

- 보고서 목차 재구성: 10 섹션 + 부록 4개
- 톤 정책: ISMS 점검 보고서 격식 우선, 비유 0~1개만, "쉽게 말하면"/"안 고치면" 박스 사용 금지

---

## [0.4.5] - 2026-05-10 — Capability 모델

### Added

- 23 capability + 74 verification_aspect 도입
- 통제 결과 도출 = capability roll-up (보수적 결정론)

---

## [0.4] - 2026-05-10

### Added

- Stack Profile (Tier S/C/U) 16종 — sst / supabase / sentry / nextjs / prisma / cdk / pulumi / firebase / datadog / vercel / cloudflare-workers / nicepay / toss-payments / kcp / kakao-login / naver-login

---

## [0.3] - 2026-05-10 — MVP 베이스라인

### Added

- 56 통제 controls.json + 시그널 평가 (5 type)
- 4-Tier 동의 모델 (0=정적 / 1=외부도구 / 2=클라우드RO / 3=런타임)
- manifest + 보고서 자동 생성

---

[향후 버전]: TBD
