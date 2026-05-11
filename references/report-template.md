# 출력 형식 정의 (Output Format Specification)

이 파일은 isms-p-audit Skill 이 사용자 프로젝트를 점검한 후 출력할 마크다운 골격을 정의한다.
Skill 본체(SKILL.md)에서 본 정의의 placeholder(`{{ }}`)를 실제 점검 결과로 채워 출력한다.

> 참고: 이 문서 자체는 사용자 코드를 점검한 결과 보고서가 아니라, 보고서를 만들 때 따라야 할
> 골격(스켈레톤)이다. 사용자에게 출력되는 실제 보고서는 Skill 실행 시 생성된다.

---

## 보고서 골격 (v0.4.6 — 10 섹션 + 부록 4개)

```markdown
# {{project_name}} ISMS-P 사전 점검 보고서

> 면책: 본 결과물은 isms-p-audit Skill 의 자동화 사전 점검 산출물이며,
> 한국인터넷진흥원(KISA) 또는 인증기관의 공식 인증 심사 결과가 아닙니다.
> 최종 판단은 사내 정보보호책임자(CISO/CPO) 및 공식 심사원의 검토를 받아야 합니다.

> ⚠️ **v0.4.6 — 보고서 작성 BLOCKING 체크리스트**
>
> 다음 10개 섹션은 모두 REQUIRED. 1개라도 누락 시 보고서를 처음부터 다시 작성하세요.
> - §-1 한눈에 / §1 통제별 결과 / §2 점검 결과 요약 / §3 우선순위 액션 플랜 /
>   §4 발견 항목 / §5 양호 사항 / §6 미검증 통제 / §7 증적 준비 체크리스트 /
>   부록 A 검증 범위 매니페스트 / 부록 B Capability 평가
> SKILL.md §3 Step 5.3 의 BLOCKING 체크리스트와 일치합니다.
>
> v0.4.5.2 의 "쉽게 말하면" / "안 고치면" 박스는 v0.4.6 부터 **사용 금지**.
> 비유는 §-1 "📌 가장 중요한 한 가지" 부분에만 1개 허용. 그 외 모든 섹션 비유 0.

## 메타데이터

| 항목         | 값                                                   |
|--------------|------------------------------------------------------|
| 프로젝트     | {{project_name}}                                     |
| 점검 일시    | {{audit_date}} (Asia/Seoul)                          |
| 점검 범위    | {{scanned_files}} 파일 / {{scanned_loc}} 라인        |
| 통제기준     | KISA 안내서 {{isms_p_version}} / controls.json v{{ctrl_ver}} |
| 도구 버전    | isms-p-audit Skill v{{skill_ver}}                    |
| 모드         | {{mode}} (quick / full / focus)                      |

## -1. 한눈에 (1페이지 비즈니스 요약) — REQUIRED

> 1페이지 — 1분 안에 읽을 수 있는 길이 (한 화면, 약 50줄 이하).
> 점검일: {{scan_local_time}} · Skill: {{skill_version}} · 점검 시간: {{duration_human}}

### 이 레포의 역할 (Scope) ⭐ NEW v0.5.1

**{{repo_role}}** 으로 식별됨 (신뢰도: {{confidence}})

근거: {{detection_signals_joined}}

> 📋 **점검 범위**: ISMS-P 공식 통제 101개 중 **56개 자동 검증 대상** (코드/IaC/클라우드 API 로 평가 가능). 나머지 45개는 외부 증적·정책 문서·교육·물리 보안 영역 — 사람이 별도 점검.

| 분류 | 갯수 | 의미 |
|------|------|------|
| ✅🟡🔴⚫ 평가 대상 | {{observable_count}} / 56 | 이 레포 역할에서 자동 검증 가능 |
| ⚪ N/A (역할 외) | {{not_observable_count}} | 다른 레포(backend/infra) 에서 봐야 — 자동 skip |

{{#if_not_fullstack}}
**전체 ISMS-P 점검 안내**: 본 점검은 **{{repo_role}}** 레포 한정. 전체 readiness 를 위해서는 {{needed_other_roles}} 레포 점검 결과와 병합 필요. 외부 증적 플랫폼 SaaS 또는 `mvp/scripts/merge-manifests.sh` (v0.5.3 예정) 로 통합 가능.
{{/if_not_fullstack}}

> 자동 감지 결과를 변경하려면 `.isms-audit.yml` 의 `repo_role` 옵션 또는 인터랙티브 모드의 AskUserQuestion 0 에서 override.
> 본 박스는 manifest.scope 객체의 1:1 미러 — 보고서 §1 통제별 결과 표의 `scope` 컬럼 및 ⚪ N/A 분류의 1차 출처.
> backward compat: manifest.scope 부재 (v0.4 이전) 시 본 박스는 생략 가능 — placeholder 미정의 fallback 으로 §-1 신호등 직접 표시.

{{#if_delta_vs}}
> 📊 **이전 점검 ({{delta_previous_run_basename}}, 커밋 차이 {{delta_code_commits_between}}건) 대비**: {{delta_summary}}
{{/if_delta_vs}}

> v0.6.1 — 위 박스는 manifest.delta_vs 가 존재하면 **BLOCKING REQUIRED**. 부재 (첫 점검) 시 placeholder 미정의 fallback 으로 생략 가능. 보고서 §9 운영 메모 또는 §-1 직후 둘 중 하나에 반드시 노출.

### 🚦 신호등 (한눈 평가)

- 🔴 **즉시 보완 ({{critical_count}}건)** — ISMS-P 인증 심사에서 결격 사유 가능
- 🟡 **보완 권장 ({{high_medium_count}}건)** — 심사관 재량. 보완 시 안정
- 🟢 **양호 ({{good_count}}건)** — 이미 갖춰진 보안 위생
- ⚫ **미검증 ({{manual_count}}건)** — 외부 증적·문서 필요
- ⚪ **N/A (역할 외) ({{scope_skipped_count}}건)** ⭐ NEW v0.5.1 — 다른 레포(backend/infra)에서 봐야

### ⏱ 이번 주 안에 (개발자 + DevOps)

{{this_week_actions}}

> 각 항목 형식 (v0.4.6 — 비유 없이): "🔴 **[통제 ID] [공식 통제명]** — [구체 조치] ([소요 시간])"
>
> 예시:
> 1. 🔴 **2.6.4 데이터베이스 접근** — Supabase 행 단위 접근 정책(RLS) `USING(true)` 5개 테이블 정정 (반나절)
> 2. 🔴 **2.9.4 로그 및 접속기록 관리** — CloudTrail 멀티리전 trail 1개 활성화 (1시간)
> 3. 🔴 **3.3.4 개인정보 국외이전** — `sendDefaultPii: true` 비활성화 + 처리방침 국외이전 항목 추가 (30분)

### 📅 이번 달 안에 (DevOps)

{{this_month_actions}}

### 🗓 다음 분기 (CISO + 법무)

{{next_quarter_actions}}

### 💰 비용 추정

- 즉시 보완 {{critical_count}}건: 약 {{critical_time_estimate}} + AWS/SaaS 비용 약 {{critical_cost_estimate}}/월
- 보완 권장 {{high_medium_count}}건: 약 {{hm_time_estimate}}
- 미검증 {{manual_count}}건: 약 {{manual_time_estimate}} (외부 자료 수령 포함)

### 📌 가장 중요한 한 가지

{{single_most_important_action}}

> 한 줄 — 이 보고서를 5분만에 읽고 끝내야 한다면 이것만은 처리.
> v0.4.6: 본 항목은 비유 1개 허용 (선택). 그 외 §-1 본문은 비유 0.
>
> 권장 형식 (사실 + ISMS-P 통제 ID + 법적 근거):
> "🔴 `orders` / `order_items` / `order_events` 의 행 단위 접근 정책(RLS) 이 `USING(true)` 로
>  설정되어 익명 사용자가 모든 주문 정보(이름·전화·주소) 를 조회 가능한 상태.
>  이는 ISMS-P 2.6.4 데이터베이스 접근, 3.2.5 가명정보 처리 통제 결격이며
>  개인정보보호법 제29조 안전조치 의무 위반 가능성. 즉시 정책 수정 권장."

## 1. 통제별 결과 (56 통제 한 페이지) — REQUIRED ⭐ v0.4.6 핵심

> ISMS 점검 보고서의 본질 = "통제별 OK/NG 일목요연". 이 섹션이 본 보고서의 중심.
> 56 통제를 ISMS-P 카테고리 그룹으로 묶어 각 그룹마다 표 1개로 정리.
> 컬럼: 통제 ID / 통제명 / 결과 (✅🟡🔴⚫⚪) / scope (✓ / ⚪) / 비고 (1줄, finding 참조).
> 비유 0 · 자세한 finding 내용은 §4 참조.

**범례 (결과)**: ✅ 통과 · 🟡 부분통과 · 🔴 보완 필요 · ⚫ 미검증 · ⚪ **N/A (역할 외, v0.5.1 신설)** · ☑ 미동의(Tier/도메인)

**범례 (scope, v0.5.1 신설)**: ✓ — 이 레포 역할에서 평가 가능 (observable) · ⚪ — N/A (다른 역할 필요; 예: backend-only)

> `scope` 컬럼이 ⚪ 이면 `결과` 컬럼은 자동 ⚪ N/A. 두 컬럼은 manifest.scope.observable_controls / not_observable_controls 와 1:1 미러.

**범례 (글로벌 매핑, v0.7-pre 신설 → v0.7-pre.1 BLOCKING)**: 각 통제는 ISO 27001:2022 / NIST CSF 2.0 / SOC 2 TSC 의 등가 통제와 자동 cross-mapping. **비고 컬럼에 `(≈ ISO A.5.16, NIST CSF PR.AA-01, SOC 2 CC6.1)` 형식으로 박제 필수** (v0.7-pre.1 BLOCKING — 14차 dogfood 회귀 fix). 1차 출처: `references/cross_framework_mapping.json` + `controls.json[].cross_mappings`.

**비고 컬럼 박제 형식 (v0.7-pre.1)**:
```
| 2.5.1 | 사용자 계정 관리 | ✅ | ✓ | (≈ ISO A.5.16+A.5.18, NIST CSF PR.AA-01+PR.AA-05, SOC 2 CC6.2+CC6.3) — F-NNN 없음 |
| 2.7.2 | 암호키 관리      | 🔴 | ✓ | (≈ ISO A.8.24, NIST CSF PR.DS-01, SOC 2 CC6.1) — F-024, F-027 보완 필요 |
```
- 각 framework 의 ids[] 배열 길이 ≥ 2 면 `+` 로 연결 (예: `A.5.16+A.5.18`)
- finding 참조 (F-NNN) 가 있으면 ` — F-NNN` 으로 뒤에 붙임
- finding 없고 결과 ✅ 면 ` — F-NNN 없음` 또는 ` — 통과` 생략 가능

> v0.7-pre — `cross_mappings` 박제는 controls.json 의 각 통제에 정식 필드. 매핑 신뢰도: verified 38 / candidate 14 / partial 4 (총 56 통제).
>
> self-check (v0.7-pre.1 BLOCKING): `grep -cE "≈ ISO A\\." report.md` ≥ 30 (56 통제 중 절반 이상).

### 1.1 관리체계 수립 (Category 1.1.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_1_1}}

> 이 그룹: ✅ {{group_1_1_pass}} · 🟡 {{group_1_1_partial}} · 🔴 {{group_1_1_fail}} · ⚫ {{group_1_1_unknown}} · ⚪ {{group_1_1_scope_na}} (역할 외)

### 1.2 위험관리 (Category 1.2.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_1_2}}

> 이 그룹: ✅ {{group_1_2_pass}} · 🟡 {{group_1_2_partial}} · 🔴 {{group_1_2_fail}} · ⚫ {{group_1_2_unknown}} · ⚪ {{group_1_2_scope_na}} (역할 외)

### 1.4 사후관리 (Category 1.4.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_1_4}}

> 이 그룹: ✅ {{group_1_4_pass}} · 🟡 {{group_1_4_partial}} · 🔴 {{group_1_4_fail}} · ⚫ {{group_1_4_unknown}} · ⚪ {{group_1_4_scope_na}} (역할 외)

### 2.5 인증 및 권한관리 (Category 2.5.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_2_5}}

> 이 그룹: ✅ {{group_2_5_pass}} · 🟡 {{group_2_5_partial}} · 🔴 {{group_2_5_fail}} · ⚫ {{group_2_5_unknown}} · ⚪ {{group_2_5_scope_na}} (역할 외)

### 2.6 접근통제 (Category 2.6.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_2_6}}

> 이 그룹: ✅ {{group_2_6_pass}} · 🟡 {{group_2_6_partial}} · 🔴 {{group_2_6_fail}} · ⚫ {{group_2_6_unknown}} · ⚪ {{group_2_6_scope_na}} (역할 외)

### 2.7 암호화 적용 (Category 2.7.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_2_7}}

> 이 그룹: ✅ {{group_2_7_pass}} · 🟡 {{group_2_7_partial}} · 🔴 {{group_2_7_fail}} · ⚫ {{group_2_7_unknown}} · ⚪ {{group_2_7_scope_na}} (역할 외)

### 2.8 정보시스템 도입 및 개발 보안 (Category 2.8.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_2_8}}

> 이 그룹: ✅ {{group_2_8_pass}} · 🟡 {{group_2_8_partial}} · 🔴 {{group_2_8_fail}} · ⚫ {{group_2_8_unknown}} · ⚪ {{group_2_8_scope_na}} (역할 외)

### 2.9 시스템 및 서비스 운영관리 (Category 2.9.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_2_9}}

> 이 그룹: ✅ {{group_2_9_pass}} · 🟡 {{group_2_9_partial}} · 🔴 {{group_2_9_fail}} · ⚫ {{group_2_9_unknown}} · ⚪ {{group_2_9_scope_na}} (역할 외)

### 2.10 시스템 및 서비스 보안관리 (Category 2.10.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_2_10}}

> 이 그룹: ✅ {{group_2_10_pass}} · 🟡 {{group_2_10_partial}} · 🔴 {{group_2_10_fail}} · ⚫ {{group_2_10_unknown}} · ⚪ {{group_2_10_scope_na}} (역할 외)

### 2.11 사고 예방 및 대응 (Category 2.11.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_2_11}}

> 이 그룹: ✅ {{group_2_11_pass}} · 🟡 {{group_2_11_partial}} · 🔴 {{group_2_11_fail}} · ⚫ {{group_2_11_unknown}} · ⚪ {{group_2_11_scope_na}} (역할 외)

### 2.12 재해복구 (Category 2.12.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_2_12}}

> 이 그룹: ✅ {{group_2_12_pass}} · 🟡 {{group_2_12_partial}} · 🔴 {{group_2_12_fail}} · ⚫ {{group_2_12_unknown}} · ⚪ {{group_2_12_scope_na}} (역할 외)

### 3.1 개인정보 수집 시 보호조치 (Category 3.1.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_3_1}}

> 이 그룹: ✅ {{group_3_1_pass}} · 🟡 {{group_3_1_partial}} · 🔴 {{group_3_1_fail}} · ⚫ {{group_3_1_unknown}} · ⚪ {{group_3_1_scope_na}} (역할 외)

### 3.2 개인정보 보유 및 이용 시 보호조치 (Category 3.2.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_3_2}}

> 이 그룹: ✅ {{group_3_2_pass}} · 🟡 {{group_3_2_partial}} · 🔴 {{group_3_2_fail}} · ⚫ {{group_3_2_unknown}} · ⚪ {{group_3_2_scope_na}} (역할 외)

### 3.3 개인정보 제공 시 보호조치 (Category 3.3.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_3_3}}

> 이 그룹: ✅ {{group_3_3_pass}} · 🟡 {{group_3_3_partial}} · 🔴 {{group_3_3_fail}} · ⚫ {{group_3_3_unknown}} · ⚪ {{group_3_3_scope_na}} (역할 외)

### 3.4 개인정보 파기 시 보호조치 (Category 3.4.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_3_4}}

> 이 그룹: ✅ {{group_3_4_pass}} · 🟡 {{group_3_4_partial}} · 🔴 {{group_3_4_fail}} · ⚫ {{group_3_4_unknown}} · ⚪ {{group_3_4_scope_na}} (역할 외)

### 3.5 정보주체 권리보호 (Category 3.5.x)

| 통제 ID | 통제명 | 결과 | scope | 비고 |
|---------|--------|------|-------|------|
{{controls_table_3_5}}

> 이 그룹: ✅ {{group_3_5_pass}} · 🟡 {{group_3_5_partial}} · 🔴 {{group_3_5_fail}} · ⚫ {{group_3_5_unknown}} · ⚪ {{group_3_5_scope_na}} (역할 외)

> 표 행 형식 (v0.5.1 — `scope` 컬럼 신설):
> - 관찰 가능 통제: `| 2.6.4 | 데이터베이스 접근 | 🔴 | ✓ | F-001 (행 단위 접근 정책 USING(true) 5개 테이블) |`
> - 역할 외 통제: `| 2.6.1 | 네트워크 접근 | ⚪ | ⚪ | scope_not_applicable — infra 레포에서 평가 |`
> 비고는 1줄 자연어 + finding ID 참조 (자세한 내용은 §4 finding 본문 참조).
> 영어 코드는 코드 블록 안에만 (`USING(true)` 같은 짧은 식별자는 비고 컬럼 허용).
> scope ⚪ 행의 비고는 `scope_not_applicable — <needed_role> 레포에서 평가` 형식.

## 2. 점검 결과 요약 (숫자 + 한 줄 평) — REQUIRED

### 한 줄 평

{{one_line_korean_compliance_summary}}

> v0.4.6: ISMS-P 통제 카테고리 기반 한 줄 평. 비유 0. 영어 약어 첫 등장 시 풀어쓰기.
> v0.5.1: scope 정보 (레포 역할 / 평가 가능 통제 수) 첫 문장에 추가.
>
> 예시 (v0.5.1):
> "{{repo_role}} 레포로 식별. 56 통제 중 {{observable_count}} 통제 평가 가능 —
>  통과 3 / 부분통과 13 / 보완 필요 11 / 미검증 {{unknown_count}} / N/A {{scope_skipped_count}}.
>  행 단위 접근 정책(RLS) 과 활동 감사로그(CloudTrail) 누락이 가장 큰 보완 영역. 양호한 부분
>  (다중 인증·KMS 키 회전·처리방침 페이지) 도 있으나 capability 6/23 실패는 인증 심사 전 보완 필수."

### 📊 숫자

- ✅ 잘 됨: {{passed_count}} / 56
- 🟡 일부 OK / 보완 권장: {{partial_count}}
- 🔴 보완 필요: {{failed_count}}
- ⚫ 사람이 봐야 함: {{unknown_count}}
- ⚪ **N/A (이 레포 역할 외)**: {{scope_skipped_count}} ⭐ NEW v0.5.1
- ☑ 미동의 (Tier/도메인): {{tier_skipped_count}}

리스크 분포: Critical {{c}} · High {{h}} · Medium {{m}} · Low {{l}} · Info {{i}}

> v0.5.1 — `scope_skipped_count` = manifest.scope.not_observable_controls.length (자동 skip, reason=scope_not_applicable).
> `tier_skipped_count` = manifest.controls.skipped[] 중 reason ∈ {tier_not_consented, domain_not_consented} 의 카운트.
> 두 값은 분리 집계 — Tier 미동의는 사용자 추가 동의로 해소 가능, scope 외는 다른 레포에서만 해소.

> 평가 경로 분포:
>   - Tier 0 정적: skill_grep {{path_skill_grep}} 건 / skill_glob {{path_skill_glob}} 건 (= {{path_tier0_total}} 건)
>   - Tier 1 외부 도구: {{path_tier1_total}} 건 ({{path_tier1_tools_summary}})
>   - Tier 2 클라우드: direct_cli {{path_direct_cli}} 건 / prowler {{path_prowler}} 건 ({{path_tier2_note}})
>   - skipped: {{path_skipped}} 건
>   - **총 평가 시그널 {{path_grand_total}} 건** (정적 {{path_tier0_total}} + 외부 {{path_tier1_total}} + 클라우드 {{path_tier2_total}}) + {{path_skipped}} 건 skip
>
> (prowler/검증된 OSS 비중이 높을수록 신뢰도 향상. 본 분포는 manifest.signals_evaluation_path 의 모든 필드를 1:1 미러)

## 3. 우선순위 액션 플랜 (이번 주 / 이번 달 / 분기) — REQUIRED

> §-1 의 액션을 표 형식으로 정리. 비유 없이 공식 통제명·기술 용어.

| 우선순위 | 기한        | 통제 ID | 조치 내용 | 담당 | 소요 시간 |
|----------|-------------|---------|-----------|------|----------|
| P0       | 이번 주     | {{p0_control_id}} | {{p0_action}} | {{p0_owner}} | {{p0_time}} |
| P1       | 이번 달     | {{p1_control_id}} | {{p1_action}} | {{p1_owner}} | {{p1_time}} |
| P2       | 다음 분기   | {{p2_control_id}} | {{p2_action}} | {{p2_owner}} | {{p2_time}} |

> 예시 행 (v0.4.6 — 비유 없이 공식 통제명):
>
> | P0 | 이번 주 | 2.6.4 | 행 단위 접근 정책(RLS) 5개 테이블 정정 (`TO authenticated USING(auth.uid()=user_id)`) | 백엔드 리드 | 반나절 |
> | P0 | 이번 주 | 2.9.4 | CloudTrail 멀티리전 trail 활성화 | DevOps | 1시간 |
> | P1 | 이번 달 | 2.5.1 | IAM Identity Center 도입 + AdministratorAccess 직접 attach 해제 | DevOps | 1~2일 |

## 4. 발견 항목 상세 (Findings) — REQUIRED

> v0.4.6: "💡 쉽게 말하면" / "⚠️ 안 고치면" 박스 **사용 금지**.
> 영향 라인 1줄에 사실 (비유 없이) + 통제 ID + 법적 근거.
> 영어 코드는 "증거" / "재현 명령" 코드 블록 안에만 — 본문 인라인 코드 자제.

### [{{severity}}] F-{{seq}} — {{title_korean_first}}

- 통제항목: **{{controls_primary}}** (1차) / {{controls_secondary}} (2차)
- 영향: {{impact_one_line}}
  - 작성 톤 가이드: 1줄 자연어. 비유 0. 사실 + 통제 ID + (해당 시) 법적 근거.
  - 단정 표현 금지 — "...로 확인됨", "...될 가능성" 톤 유지 (risk-rubric.md 와 일관).
  - 예: "익명 사용자가 모든 주문 정보(이름·전화·주소) 조회 가능. ISMS-P 인증 심사 결함 확정 가능성 매우 높음. 개인정보보호법 제29조 안전조치 의무 위반 가능."
- 영향 Capability (v0.4.5): {{affected_capabilities}}
  - 형식: `<capability_id>.<aspect_id> (unsatisfied|partial|fail)`
  - 예: `secrets_management.cloud_credential_inline_absent (unsatisfied)`
- 카테고리: {{control_category}}
- 출처: {{evaluation_source}}
  - 라벨 규칙 — 다음 중 하나:
    - `[검증된 OSS: prowler/<check_id>]` (1순위, 높은 신뢰도)
    - `[검증된 OSS: scoutsuite/<id>]` / `[검증된 OSS: kube-bench/<id>]`
    - `[LLM aws CLI 직접 호출]` (fallback, 낮은 신뢰도)
    - `[Skill grep_absent]` / `[Skill grep_pattern]` / `[Skill glob_exists]`
    - `[CLI <ruleId>]` (e.g. `[CLI IAM-001]`)
    - `[LLM 코드 분석]`

**증거 (코드 위치)**:

```
{{file}}:{{line}} — {{evidence_redacted}}
```

(영어 코드·파일 경로는 위 코드 블록 안에만. 본문 인라인 코드 최소화.)

**권장 조치**:
1. {{action_1}}
2. {{action_2}}

**재현 명령**:

```bash
{{repro_command}}
```

(반복 — 모든 finding 동일 형식)

> finding 제목 형식 (v0.4.6 — 한글 통제명이 메인, 영어 코드는 부차적):
>
> ❌ 회피: "Supabase RLS `USING (true)` 가 PII 보유 5개 테이블에 `TO` 절 없이 적용"
> ✅ 권장: "행 단위 접근 정책(RLS) `USING(true)` 가 개인정보 보유 5개 테이블에 적용"
>
> 한글 우선 + 약어 풀어쓰기 (영어 약어는 괄호 안). 영어 코드는 최소.

## 5. 양호 사항 (이미 잘 되어 있는 것) — REQUIRED

> 부족한 것만 보면 자신감을 잃기 쉽습니다. 이 프로젝트가 이미 갖춘 보안 위생.
> v0.4.5.2 §0.7 → v0.4.6 §5 로 이동 (내용 동일).

| 영역 | 상태 | 코드/시스템 위치 |
|------|------|----------------|
{{good_signals_table}}

> 예시:
> | 시크릿 | ✅ 평문 시크릿 0건 (AWS 키, Slack 토큰, 개인키 모두 없음) | gitleaks/grep 검증 |
> | .env 추적 | ✅ git 에 올라가지 않음 | .gitignore 정상 |
> | RLS 일부 정책 | ✅ graphic_assets 등은 TO authenticated 명시 | supabase/migrations/ |
> | MFA | ✅ AWS 콘솔 사용자 MFA 등록 | iam-<user>-iphone |
>
> 시그널 통과 / 구현된 통제 / capability satisfied aspect 모두 포함.

## 6. 미검증 통제 + 사유 — REQUIRED

> §1 통제별 결과 표의 ⚫ 항목을 통제 단위로 펼친 표.
> manifest.controls.skipped[] 의 행을 그대로 매핑.

| 통제 ID | 통제명 | 사유 | 해소 방법 |
|---------|--------|------|----------|
{{unverified_controls_table}}

> v0.4.5 부터 manual_review_only 통제 (1.4.3 / 2.8.1 / 2.8.2 / 2.8.3 / 2.9.6 /
> 3.2.1 / 3.2.2 / 3.2.3 / 3.2.4 / 3.3.3) 은 자동 attempt 되지만 결과는 항상
> unknown — 사람이 외부 증적으로 평가합니다. 사유 라벨:
>
> - `capability_unknown` — capability 결과 unknown 으로 통제도 unknown
> - `manual_review_only` — required_capabilities 가 빈 배열인 manual-only 통제

## 7. 증적 준비 체크리스트 (Evidence Checklist) — REQUIRED

### 7.1 코드로 검증 완료

| ✓ | 항목 | 매핑 통제 | 자동 추출 위치 |
|---|------|----------|---------------|
| {{check_box}} | {{evidence_item}} | {{control_id}} | {{auto_source}} |

### 7.2 외부 증적 필요 (사람이 준비)

| ☐ | 항목 | 매핑 통제 | 권장 보관 위치 |
|---|------|----------|--------------|
| ☐ | 정보보호 정책 문서 (사내 위키/PDF) | 1.1.5 | Confluence / Notion / `/docs/security/policy.pdf` |
| ☐ | 직원 보안교육 이수 기록 | 2.2.4 | LMS / HRIS — 분기별 export |
| ☐ | 개인정보 처리방침 게시 화면 | 3.1.5 | 서비스 footer 스크린샷 + 변경 이력 |
| ☐ | 위탁사 점검 결과 자료 | 3.3.1 | `/docs/vendor-audits/` + 점검 회의록 |
| ☐ | 침해사고 대응 모의훈련 결과 | 2.11.5 | DR 훈련 보고서 PDF + 시나리오 결과 |
| ☐ | 분기별 권한 검토 회의록 | 2.5.6 | 검토 회의록 + IAM 사용자/권한 스냅샷 |
| ☐ | DR 모의훈련 결과 자료 | 2.12.2 | DR 훈련 보고서 + RTO/RPO 측정 |
| ☐ | 자산 인벤토리 (CMDB) | 1.2.1 | CMDB / spreadsheet — 자산 ID·소유자·등급 |
| ☐ | {{custom_evidence_item}} | {{control_id}} | {{recommended_location}} |

---

## 부록 A. 검증 범위 매니페스트 — REQUIRED

> 본 부록은 `audit-manifest.json` (저장: `./.isms-audit/runs/{{manifest_ts}}.json`,
> schema: `references/manifest.schema.json`) 의 1차 출처 데이터이며,
> 보고서가 manifest 와 어긋나면 **manifest 우선** (SKILL.md §9 운영 메모).

### A.1 점검 환경

| 항목 | 값 |
|------|-----|
| Skill 버전 | {{skill_version}} |
| ISMS-P 기준 | KISA 안내서 {{isms_p_version}} |
| 점검 시각 | {{scan_local_time}} (런타임 데이터 as-of: {{as_of_utc}}) |
| Tier 동의 | {{consent_tier}}  (출처: {{consent_source}}) |
| 도메인 동의 | {{consent_domains}} |
| 사용 도구 | {{tools_summary}} |
| AWS profile / regions | {{aws_profile}} / {{aws_regions}} |
| 클라우드 호출 횟수 | {{api_calls_total}} (모두 read-only) |
| **활성 Stack Profile** | {{stacks_detected_summary}} (v0.4.5 신설) |
| **Capability 평가 통과** | {{capability_satisfied_count}} / {{capability_total}} (v0.4.5 신설) |
| ISMS-P 공식 통제 수 | 101 (KISA 안내서 2023.11 기준) |
| 자동 검증 대상 | 56 (코드/IaC/클라우드 API) |
| 외부 증적 영역 | 45 (정책·교육·물리·운영 — Skill 영역 외) |

**서비스별 호출 분포** (v0.5.1.1 신설):

{{api_calls_by_service_table}}

> 예시 (호출 수 내림차순 정렬):
>
> | AWS 서비스 | 호출 수 | 비고 |
> |---|---|---|
> | iam | 8 | 사용자/정책/MFA |
> | s3 | 8 | 버킷 ACL/암호화/로깅 |
> | kms | 4 | 키 회전/암호화 |
> | cloudfront | 3 | 배포 TLS/WAF |
> | cloudtrail | 2 | 트레일 존재 여부 |
> | guardduty | 2 | 탐지기 활성화 |
> | ec2 | 2 | SG 인그레스 |
> | securityhub | 1 | 활성화 |
> | configservice | 1 | 활성화 |
> | rds | 1 | 백업/암호화 |
> | elbv2 | 1 | TLS 정책 |
> | wafv2 | 1 | ACL 연결 |
> | backup | 1 | 백업 플랜 |
> | **합계** | **28** | |

### A.2 통제 커버리지 (v0.5.1.1 — 자동 56 vs 공식 101 명시)

```
                                       자동 검증     ISMS-P 공식
─────────────────────────────────────────────────────────────
                            검증됨  미검증  소계   공식 통제
1. 관리체계 ({{c1_auto_total}} / 16)         {{c1_passed}}    {{c1_unverified}}   {{c1_auto_total}}     16
2. 보호대책 ({{c2_auto_total}} / 64)         {{c2_passed}}    {{c2_unverified}}   {{c2_auto_total}}     64
3. 개인정보 ({{c3_auto_total}} / 21)         {{c3_passed}}    {{c3_unverified}}   {{c3_auto_total}}     21
─────────────────────────────────────────────────────────────
전체 (자동 56 / 공식 101)    {{total_passed}}   {{total_unverified}}  56     101

자동 검증 미포함 (45 통제):
  - 1.x 관리체계 12개 — 정책 수립 / 위험관리 / CISO 임명 / 내부감사 (문서·인적 통제)
  - 2.1 ~ 2.4 (29개) — 정책·조직 / 인적보안 / 외부자보안 / 물리보안 (계약·교육·물리)
  - 3.x 일부 (4개) — 정보주체 동의·고지 등 (LLM 본문 분석 또는 외부 증적)
```

> 위 분포는 ISMS-P 공식 통제 101개 (KISA 안내서 2023.11 기준) 와 본 Skill 의 자동 검증 대상 56개의 차이를 명시.
> 자동 검증 대상 56개 = controls.json 의 전체 통제 (1.x 4개 / 2.5~2.12 35개 / 3.x 17개).
> 외부 증적 영역 45개 = ISMS-P 공식 101개에서 본 Skill 의 56개를 뺀 나머지 (정책 문서·교육 기록·물리 보안 등).

미검증 사유 분포:
{{unverified_reason_breakdown}}

> 본 보고서는 위 동의 범위 내에서만 자동 검증한 결과입니다. 동의받지 않은
> Tier·도메인의 통제는 §6 "미검증 통제 + 사유" 표에서 확인할 수 있습니다.

### A.3 추가 검증 가능 영역 (도구 설치 시)

> 도구 설치 안내가 사용자의 다음 액션을 결정합니다.
> manifest.signals_evaluation_path.direct_cli 카운트를 정량 표시.

본 점검 환경에서 **현재 미설치된 도구를 설치하면** 추가로 검증 가능한 통제:

| 도구 | 설치 명령 | 추가 가능 통제 (대략) | 이번 점검에서 LLM 직접 호출 N건 |
|------|----------|---------------------|--------------------------------|
| prowler ({{prowler_status}}) | `brew install prowler-cloud/tap/prowler` | Tier 2 의 **모든 시그널** — 이 도구 설치가 가장 큰 신뢰도 향상 | {{prowler_fallback_count}} 건 |
| trivy ({{trivy_status}})     | `brew install aquasecurity/trivy/trivy`  | 컨테이너 CVE / 의존성 취약점 (2.10.8, 2.11.2) | {{trivy_fallback_count}} 건 |
| tfsec ({{tfsec_status}})     | `brew install tfsec`                     | Terraform IaC 정적 분석 (해당 시) | {{tfsec_fallback_count}} 건 |
| checkov ({{checkov_status}}) | `pipx install checkov`                   | 멀티 IaC 정적 분석 (해당 시) | {{checkov_fallback_count}} 건 |
| semgrep ({{semgrep_status}}) | `brew install semgrep`                   | 소스 패턴 (TLS 약함, 해시 약함 등) | {{semgrep_fallback_count}} 건 |

> prowler 우선 — Tier 2 시그널이 **검증된 룰셋** 으로 평가되어 정확도가
> LLM 직접 호출 대비 높습니다.

### A.4 인증 범위 (Scope) 정의

> AWS 계정에 점검 대상 외 자산이 같이 있으면 인증 범위 정의가 첫 단계입니다.

> ⚠️ **본 점검은 다음 범위 내 자산에 한정합니다.**
> 인증 심사 대상 자산이 아래에 명시되지 않으면 추가 점검 후 재실행이 필요합니다.

| 항목 | 본 점검 범위 |
|------|-------------|
| AWS 계정 | {{aws_account_id}} (alias: {{aws_account_alias_or_none}}) |
| 인증 대상 프로젝트 | {{project_name}} |
| 같은 계정의 다른 프로젝트 자산 | {{out_of_scope_resources_list}} |
| 인증 범위 분리 권장 | {{scope_separation_recommendation}} |

본 점검 결과 다음 자산이 같은 AWS 계정에 존재하나 인증 범위 외로 분류됨:

{{out_of_scope_table}}

> 권장: 인증 심사 전 **별도 AWS 계정 분리** 또는 **범위 명문화 문서**를 준비하세요.
> ISMS-P 인증은 자산 식별(1.2.1) + 범위 정의를 첫 단계로 요구합니다.

> 본 §A.4 는 매니페스트의 1차 출처가 아닌 **보고서 가이드** 영역입니다.
> 사용자가 직접 명시해야 정확하며, 자동 추출은 명명규칙 기반 추정값입니다.

#### A.4.1 레포 Scope (v0.5.1)

> 본 절은 manifest.scope 의 1차 출처. §-1 의 "이 레포의 역할" 박스 + §1 통제별
> 결과 표의 `scope` 컬럼이 이 데이터를 인용. 자동 감지 + 사용자 override 결과 박제.

| 항목 | 값 |
|------|-----|
| 레포 역할 | {{repo_role}} ({{confidence}}) |
| 자동 감지 신호 | {{detection_signals_joined_full}} |
| 사용자 override | {{repo_role_override_or_none}} |
| 평가 가능 통제 | {{observable_count}} / 56 |
| N/A 통제 | {{not_observable_count}} (자동 skip, manifest.controls.skipped[] 참조) |

##### N/A 통제 상세 (이 레포에서 못 보는 영역)

| 통제 ID | 통제명 | 필요한 역할 |
|--------|------|-----------|
{{not_observable_controls_table}}

예시 (frontend 레포):

| 통제 ID | 통제명 | 필요한 역할 |
|--------|------|-----------|
| 2.5.5 | 특수 계정 및 권한관리 | backend / infra |
| 2.6.1 | 네트워크 접근 | infra |
| 2.9.4 | 로그 및 접속기록 관리 | backend / infra |

이 통제들은 backend / infra 레포 점검 결과와 병합 필요. 외부 증적 플랫폼 SaaS 또는
`mvp/scripts/merge-manifests.sh` (v0.5.3 예정) 로 통합 가능.

> backward compat: manifest.scope 부재 (v0.4 이전 manifest) 시 본 §A.4.1 은 생략 가능.
> placeholder 미정의 fallback 으로 자동 skip — 보고서 §-1 / §1 / §2 의 ⚪ N/A 표기도 함께 생략.

---

## 부록 B. Capability 평가 (참고용 — 추적 매트릭스) — REQUIRED

> 23 capability 의 verification_aspects 합산 결과. 통제 결과(§1) 의 1차 출처.
> manifest.capability_evaluation[] 에서 직접 채움 (schema: `references/manifest.schema.json`).
> 한국어 ISMS-P 보고서 본문에서는 부차적 정보이지만, capability 단위 추적에 필요해 박제.

*aspect 분포 (4 카테고리 합 = 해당 capability 의 verification_aspects 총 갯수). 합산 행은 capability **결과** 분포 (capability_evaluation[].result enum 기반).*

| Capability | Category | 결과 | satisfied / partial / unsatisfied / unknown aspects | 영향 통제 (ISMS-P) |
|-----------|---------|------|---------------------------------------------------|------------------|
| {{cap_id}} | {{cap_category}} | {{cap_result}} | {{cap_aspect_breakdown}} | {{cap_affecting_controls}} |
| (23 capability 모두 박제) | | | | |
| **합산** | — | satisfied {{cap_satisfied_n}} / partial {{cap_partial_n}} / fail {{cap_fail_n}} / unknown {{cap_unknown_n}} | — | — |

> capability 결과가 fail/partial 이면 §4 발견 항목과 §1 통제별 결과 표에서
> 해당 capability 의 unsatisfied aspect 가 어떤 시그널 family 에 의해 발동됐는지
> 추적 가능 (역추적 표기는 §4 finding 의 `affected_capabilities` 라인 참조).

---

## 부록 C. 자체 검증 명령

작성한 보고서가 v0.4.6 표준을 충족하는지 다음 명령으로 검증:

```bash
# 1. v0.4.6 10 섹션 + 부록 3개 헤더 모두 존재
for s in "## -1\. " "## 1\. " "## 2\. " "## 3\. " "## 4\. " "## 5\. " "## 6\. " "## 7\. " "## 부록 A" "## 부록 B"; do
  grep -qE "^$s" report.md || echo "누락: $s"
done

# 2. capability 단어 등장 (부록 B + §4 finding affected_capabilities)
[ "$(grep -c -i 'capability' report.md)" -ge 5 ] || echo "capability 단어 부족 — 부록 B 누락 의심"

# 3. "쉽게 말하면" / "안 고치면" 박스 사용 금지 (v0.4.6 변경)
[ "$(grep -c '쉽게 말하면' report.md)" -eq 0 ] || echo "위반: 쉽게 말하면 박스 사용 금지 (v0.4.6)"
[ "$(grep -c '안 고치면' report.md)" -eq 0 ] || echo "위반: 안 고치면 박스 사용 금지 (v0.4.6)"

# 4. §-1 한눈에 1페이지 분량 (한 화면 — 대략 50줄 이하 권장)
awk '/^## -1\. /{flag=1; n=0; next} /^## 1\. /{flag=0} flag{n++} END{print "§-1 라인 수:", n}' report.md

# 5. manifest 와 일관성
jq '.controls.attempted | length' manifest.json
# = §1 통제별 결과 표 모든 행 합계 (16개 카테고리 그룹) 와 같아야

# 6. §1 통제별 결과 표 행 수 = 56 (controls.json 의 모든 통제)
[ "$(grep -cE '^\| [0-9]+\.[0-9]+\.[0-9]+ \|' report.md)" -eq 56 ] || echo "§1 통제 행 수 != 56"

# 7. (v0.5.1) §-1 "이 레포의 역할 (Scope)" 박스 존재 — manifest.scope 가 있는 경우 REQUIRED
if jq -e '.scope.repo_role' manifest.json >/dev/null 2>&1; then
  grep -q "이 레포의 역할 (Scope)" report.md || echo "위반: §-1 레포 역할 박스 누락 (v0.5.1)"
fi

# 8. (v0.5.1) §1 통제별 결과 표 헤더에 `scope` 컬럼 존재
[ "$(grep -c '| 통제 ID | 통제명 | 결과 | scope | 비고 |' report.md)" -ge 16 ] \
  || echo "위반: §1 표 헤더의 scope 컬럼 누락 (16 카테고리 그룹 모두 필요, v0.5.1)"

# 9. (v0.5.1) §2 ⚪ N/A 라인 존재 — manifest.scope 가 있는 경우 REQUIRED
if jq -e '.scope.repo_role' manifest.json >/dev/null 2>&1; then
  grep -q '⚪ \*\*N/A (이 레포 역할 외)' report.md || echo "위반: §2 ⚪ N/A 분류 누락 (v0.5.1)"
fi

# 10. (v0.5.1.2) manifest.delta_vs 박제 — `.isms-audit/runs/*.json` 1개 이상 존재 시 REQUIRED
RUNS_DIR="$(dirname "$(realpath manifest.json)")"
PRIOR_COUNT=$(find "$RUNS_DIR" -maxdepth 1 -name '*.json' ! -wholename "$(realpath manifest.json)" 2>/dev/null | wc -l | tr -d ' ')
if [ "$PRIOR_COUNT" -ge 1 ]; then
  jq -e '.delta_vs.previous_run and .delta_vs.summary' manifest.json >/dev/null \
    || echo "위반: 이전 manifest $PRIOR_COUNT 개 존재하나 .delta_vs 박제 누락 (v0.5.1.2 BLOCKING)"
fi

# 11. (v0.6.1) delta_vs 보고서 노출 — manifest.delta_vs 가 박제되면 보고서에도 1줄 REQUIRED
if jq -e '.delta_vs.summary' manifest.json >/dev/null 2>&1; then
  grep -qE "이전 점검.*대비" report.md \
    || echo "위반: manifest.delta_vs 박제됐으나 보고서에 '이전 점검 ... 대비' 라인 누락 (v0.6.1 BLOCKING)"
fi

# 12. (v0.6.1) manifest.signals_evaluation_path 박제 — 7개 키 정수 REQUIRED
jq -e '
  .signals_evaluation_path
  | (has("skill_grep") and has("skill_glob") and has("tool_invoke")
     and has("direct_cli") and has("prowler") and has("cluster_query") and has("skipped"))
  and ([.skill_grep, .skill_glob, .tool_invoke, .direct_cli, .prowler, .cluster_query, .skipped]
       | all(type == "number" and . >= 0))
' manifest.json >/dev/null \
  || echo "위반: signals_evaluation_path 객체 부재 또는 7개 키 (skill_grep/skill_glob/tool_invoke/direct_cli/prowler/cluster_query/skipped) 미충족 (v0.6.1 BLOCKING)"

# 12b. signals_evaluation_path 합계 ≥ controls.attempted.length
SEP_SUM=$(jq '[.signals_evaluation_path.skill_grep, .signals_evaluation_path.skill_glob, .signals_evaluation_path.tool_invoke, .signals_evaluation_path.direct_cli, .signals_evaluation_path.prowler, .signals_evaluation_path.cluster_query, .signals_evaluation_path.skipped] | add' manifest.json 2>/dev/null)
CTRL_CNT=$(jq '.controls.attempted | length' manifest.json)
if [ -n "$SEP_SUM" ] && [ -n "$CTRL_CNT" ] && [ "$SEP_SUM" -lt "$CTRL_CNT" ]; then
  echo "경고: signals_evaluation_path 합계 ($SEP_SUM) < controls.attempted ($CTRL_CNT) — 시그널 박제 누락 의심"
fi

# 15. (v0.6.4 BLOCKING) skill_version 정확 시맨틱
jq -r '.skill_version' manifest.json | grep -qE '^isms-p-audit@[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)?$' \
  || echo "위반: skill_version 형식 부정확 — 'isms-p-audit@MAJOR.MINOR.PATCH' 형식 필수 (v0.6.4 BLOCKING)"

# 16. (v0.6.5 BLOCKING) delta_vs.previous_run = scan.ended_at 가장 최근 prior manifest
# v0.6.4 의 파일명 lex sort 가 14차 dogfood 에서 회귀 — v0.6.5 부터 scan.ended_at 기반.
RUNS_DIR="$(dirname "$(realpath manifest.json)")"
CURRENT_BASE="$(basename "$(realpath manifest.json)")"
EXPECTED_PRIOR=""
for f in "$RUNS_DIR"/*.json; do
  [ "$(basename "$f")" = "$CURRENT_BASE" ] && continue
  ended=$(jq -r '.scan.ended_at // .scan.started_at // empty' "$f" 2>/dev/null)
  [ -n "$ended" ] && echo "$ended $(basename "$f")"
done 2>/dev/null | sort | tail -1 | { read -r line; echo "$line" | awk '{print $2}'; } > /tmp/_isms_expected_prior 2>/dev/null
EXPECTED_PRIOR=$(cat /tmp/_isms_expected_prior 2>/dev/null)
# Fallback to mtime if ended_at unavailable
if [ -z "$EXPECTED_PRIOR" ]; then
  EXPECTED_PRIOR=$(ls -1t "$RUNS_DIR"/*.json 2>/dev/null | grep -v "/$CURRENT_BASE\$" | head -1 | xargs -n1 basename 2>/dev/null)
fi
ACTUAL_PRIOR=$(jq -r '.delta_vs.previous_run // empty' manifest.json | xargs -n1 basename 2>/dev/null)
if [ -n "$EXPECTED_PRIOR" ] && [ -n "$ACTUAL_PRIOR" ] && [ "$EXPECTED_PRIOR" != "$ACTUAL_PRIOR" ]; then
  echo "위반(v0.6.5 BLOCKING): delta_vs.previous_run = '$ACTUAL_PRIOR' (기대: '$EXPECTED_PRIOR' — scan.ended_at 기반 가장 최근)"
fi

# 17. (v0.7-pre.1 BLOCKING) 보고서 §1 통제별 결과 표에 cross_mappings 노출
# controls.json 의 56 cross_mappings 박제 → 보고서 비고 컬럼에 `(≈ ISO A.X.Y, NIST CSF XX.YY-NN, SOC 2 ZZN.M)` 형식
CROSS_COUNT=$(grep -cE "≈ ISO A\.[0-9]" report.md 2>/dev/null || echo 0)
if [ "$CROSS_COUNT" -lt 30 ]; then
  echo "위반(v0.7-pre.1 BLOCKING): 보고서 cross_mappings 노출 $CROSS_COUNT 행 < 30 (56 통제 중 절반 이상 필수)"
fi

# 14. (v0.6.3 BLOCKING) unknown 통제의 skipped[] 양쪽 박제 — 환경 B vs 환경 A 박제 일관성 회귀 fix
# 11차 dogfood 에서 manual_review_only 통제를 unknown[] 에만 박제, skipped[] 미박제 (0건) → 타 환경 박제는 양쪽 31건 = schema 정합.
UNKNOWN_CNT=$(jq '.controls.unknown | length' manifest.json)
SKIPPED_NOT_SCOPE=$(jq '[.controls.skipped[] | select(.reason != "scope_not_applicable")] | length' manifest.json)
if [ "$UNKNOWN_CNT" -gt 0 ] && [ "$SKIPPED_NOT_SCOPE" -eq 0 ]; then
  echo "위반: unknown 통제 $UNKNOWN_CNT 건 존재하나 skipped[] 메타데이터 0건 (v0.6.3 BLOCKING — manual_review_only / capability_unknown 등 사유 박제 필수)"
fi
# 추가 — unknown[] ID 가 skipped[] 에 매칭되는지 (scope_not_applicable 제외)
jq -e '
  ([.controls.unknown[]] | sort) as $u |
  ([.controls.skipped[] | select(.reason != "scope_not_applicable") | .id] | sort) as $s |
  ($u == $s)
' manifest.json >/dev/null \
  || echo "경고: unknown[] 와 skipped[] (non-scope) 의 통제 ID 가 일치하지 않음 — 박제 누락 가능성"

# 13. (v0.6.2 BLOCKING) manifest 구조 schema 준수 — 자율 형식 변경 회귀 fix
# 10차 dogfood 에서 LLM 자율 형식 변경 (tools array→object, api_calls 부재, findings_summary 추가
# 등) 으로 schema 17건 위반 — v0.6.2 부터 BLOCKING.
if command -v python3 >/dev/null 2>&1 && python3 -c "import jsonschema" 2>/dev/null; then
  SCHEMA_PATH="$(dirname "$(realpath manifest.json)")/../../skill-design/isms-p-audit/references/manifest.schema.json"
  [ -f "$SCHEMA_PATH" ] || SCHEMA_PATH="$HOME/.claude/skills/isms-p-audit/references/manifest.schema.json"
  if [ -f "$SCHEMA_PATH" ]; then
    python3 -c "
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open('$SCHEMA_PATH'))
m = json.load(open('manifest.json'))
errs = list(Draft202012Validator(schema).iter_errors(m))
if errs:
  print(f'위반: manifest schema {len(errs)}건 위반 (v0.6.2 BLOCKING)')
  for e in errs[:5]: print(f'  - {e.json_path}: {e.message[:150]}')
  sys.exit(1)
" || true
  else
    # Fallback to jq-based key checks
    jq -e '.schema_version == "1"
           and (.skill_version | type == "string")
           and (.scan.started_at and .scan.ended_at and .scan.duration_s and .scan.project_root)
           and (.tools | type == "array")
           and (.api_calls.total | type == "number")
           and (.data_retention.uploaded_external | type == "boolean")
           and (.stacks_detected | all(has("profile_path")))' manifest.json >/dev/null \
      || echo "위반: manifest 기본 구조 키 누락/형식 위반 (v0.6.2 BLOCKING — jq fallback check)"
  fi
fi
```

## 부록 D. 무결성 안내

- LLM 생성 결과로 누락/오탐 가능성 존재
- 모든 finding 은 file:line 으로 재현 가능
- 민감정보(시크릿, 주민번호, 이메일 원문)는 마스킹됨
```

---

## Placeholder 치환 가이드

### 메타데이터 / 발견 항목

| Placeholder              | 치환 값 출처                                          |
|--------------------------|-------------------------------------------------------|
| `{{project_name}}`       | scan.sh 의 디렉터리 basename 또는 package.json `name` |
| `{{audit_date}}`         | 점검 시작 시각 (ISO8601)                              |
| `{{scanned_files}}`      | scan.sh stdout 의 file_count                          |
| `{{scanned_loc}}`        | scan.sh stdout 의 line_count                          |
| `{{ctrl_ver}}`           | controls.json 의 schema_version                       |
| `{{isms_p_version}}`     | controls.json 의 isms_p_version (e.g. `2023.11`)      |
| `{{skill_ver}}`          | SKILL.md 본문에서 명시된 버전                          |
| `{{mode}}`               | argument-hint 에서 받은 값                             |
| `{{evidence_redacted}}`  | 매칭된 라인의 민감정보 마스킹된 요약                   |
| `{{repro_command}}`      | `Grep "패턴" --path=경로` 형태                         |
| `{{controls_primary}}`   | finding.controls 의 1차 통제 ID·이름 (굵게 표기)       |
| `{{controls_secondary}}` | finding.controls 의 2차 (영향) 통제 ID 목록 (콤마)     |
| `{{evaluation_source}}`  | finding.evaluated_via 값을 라벨 형태로 (예: `[검증된 OSS: prowler/iam_password_policy_minimum_length_14]`) |
| `{{impact_one_line}}`    | 1줄 자연어 영향 (v0.4.6 — 비유 0, 사실 + 통제 ID + 법적 근거). 단정 표현 금지 |
| `{{title_korean_first}}` | finding 제목 — 한글 통제명 우선 + 약어 풀어쓰기 (영어 약어는 괄호 안) |

### §1 통제별 결과 (v0.4.6 핵심 → v0.5.1 scope 컬럼 추가)

| Placeholder                            | 치환 값 출처                                                            |
|----------------------------------------|---------------------------------------------------------------------------|
| `{{controls_table_1_1}}` ~ `{{controls_table_3_5}}` | 각 ISMS-P 카테고리 그룹의 통제 행. 형식 (v0.5.1): `\| <ID> \| <통제명> \| <결과 이모지> \| <scope 이모지> \| <비고 1줄 + finding 참조> \|`. controls.json + manifest.controls.{passed,failed,partial,unknown,skipped} + manifest.scope.{observable,not_observable}_controls 에서 직접 채움 |
| `{{group_<x>_<y>_pass}}` / `_partial` / `_fail` / `_unknown` / `_scope_na` (v0.5.1) | 각 카테고리 그룹의 결과별 카운트. 그룹 헤더 끝 mini-summary 행에 표시. `_scope_na` = scope 외 통제 갯수 |

> 결과 이모지 매핑:
> - manifest.controls.passed[] → ✅
> - manifest.controls.partial[] → 🟡
> - manifest.controls.failed[] → 🔴
> - manifest.controls.unknown[] → ⚫
> - manifest.controls.skipped[] (reason ∈ {tier_not_consented, domain_not_consented}) → ☑
> - manifest.controls.skipped[] (reason = scope_not_applicable, v0.5.1) → ⚪ N/A

> scope 컬럼 이모지 매핑 (v0.5.1):
> - manifest.scope.observable_controls[] 에 포함 → ✓
> - manifest.scope.not_observable_controls[] 에 포함 → ⚪ (이 행의 `결과` 컬럼도 자동 ⚪ N/A)
> - manifest.scope 부재 (v0.4 이전 backward compat) → scope 컬럼 자체 생략 가능

> 비고 컬럼 형식 (1줄):
> - pass 인 경우: 빈 셀 또는 양호 사항 출처 (예: "bcrypt 사용")
> - partial 인 경우: 부분 통과 사유 1줄 (예: "RDS 암호화 ✓ / S3 SSE 미확인")
> - fail 인 경우: finding 참조 + 1줄 사유 (예: "F-001 (행 단위 접근 정책 USING(true) 5개 테이블)")
> - unknown 인 경우: 사유 라벨 (예: "외부 증적 필요" / "Tier 2 미동의")
> - **scope_not_applicable (v0.5.1)**: `scope_not_applicable — <needed_role> 레포에서 평가` (예: "scope_not_applicable — infra 레포에서 평가")

### §3 우선순위 액션 플랜 (v0.4.6 신설)

| Placeholder                              | 치환 값 출처                                                            |
|------------------------------------------|---------------------------------------------------------------------------|
| `{{p0_control_id}}` / `{{p0_action}}` / `{{p0_owner}}` / `{{p0_time}}` | P0 항목별 통제 ID · 조치 · 담당 · 소요 시간 (여러 행) |
| `{{p1_control_id}}` ...                  | P1 항목 (동일 패턴)                                                      |
| `{{p2_control_id}}` ...                  | P2 항목 (동일 패턴)                                                      |

### 부록 A.3 추가 검증 가능 영역 (v0.3.1)

| Placeholder              | 치환 값 출처                                          |
|--------------------------|-------------------------------------------------------|
| `{{prowler_status}}`     | manifest.tools[name=prowler].found ? `설치됨 ✓` : `미설치 ✗` |
| `{{trivy_status}}`       | manifest.tools[name=trivy].found 동일 패턴            |
| `{{tfsec_status}}`       | manifest.tools[name=tfsec].found 동일 패턴            |
| `{{checkov_status}}`     | manifest.tools[name=checkov].found 동일 패턴          |
| `{{semgrep_status}}`     | manifest.tools[name=semgrep].found 동일 패턴          |

### 부록 A.4 인증 범위 (v0.3.1)

| Placeholder                            | 치환 값 출처                                            |
|----------------------------------------|---------------------------------------------------------|
| `{{aws_account_id}}`                   | scan.sh 가 `aws sts get-caller-identity` 로 추출 (Tier 2 동의 시) |
| `{{aws_account_alias_or_none}}`        | `aws iam list-account-aliases` 결과 또는 `(없음)`       |
| `{{out_of_scope_resources_list}}`      | scan.sh + AWS API 명명규칙 추정 (예: `<your-project>-*` prefix 자원이 발견되면 그것). 사용자 확정 필요 |
| `{{scope_separation_recommendation}}`  | LLM 자동 판단 (예: `권장: 별도 계정 분리` / `사내 명문화 문서로 충분`) |
| `{{out_of_scope_table}}`               | 식별된 범위 외 자산을 표 형식으로 (resource_type / name / 추정 소속 프로젝트) |

### §7 증적 체크리스트 (v0.4.6 — 기존 §5)

| Placeholder                  | 치환 값 출처                                            |
|------------------------------|---------------------------------------------------------|
| `{{check_box}}`              | 항상 `✓` (7.1 코드 증적 완료 행) 또는 `☐` (7.2 외부 증적 필요 행) |
| `{{evidence_item}}`          | 검증된 항목 이름 또는 외부 증적 항목 이름                |
| `{{control_id}}`             | 매핑된 통제 ID (예: `2.5.1`)                            |
| `{{auto_source}}`            | 자동 추출 위치 (예: `infra/iam.tf:23`, `prowler check`) |
| `{{recommended_location}}`   | 외부 증적 권장 보관 위치                                 |
| `{{custom_evidence_item}}`   | 본 점검에서 추가로 권고된 외부 증적 항목                  |

### 부록 A.1 매니페스트 섹션 (v0.3+ — 기존 §0)

> 모두 manifest.json (schema: `references/manifest.schema.json`) 에서 직접 채운다.

| Placeholder                       | 치환 값 출처                                                                |
|-----------------------------------|------------------------------------------------------------------------------|
| `{{manifest_ts}}`                 | manifest 파일명의 timestamp (e.g. `20260510T134500Z`)                       |
| `{{skill_version}}`               | manifest.skill_version (e.g. `isms-p-audit@0.3`)                            |
| `{{scan_local_time}}`             | manifest.scan.started_at 을 Asia/Seoul 로 변환 (e.g. `2026-05-10 22:45 KST`) |
| `{{as_of_utc}}`                   | manifest.scan.as_of (RFC3339 UTC). 24h 이상 지나면 보고서 상단 stale 경고   |
| `{{consent_tier}}`                | manifest.consent.tier 를 `0, 1` 형태로 표기                                  |
| `{{consent_source}}`              | manifest.consent.source enum (env / yaml / interactive)                      |
| `{{consent_domains}}`             | manifest.consent.domains 한국어 라벨 (e.g. `IAM, 네트워크, 로깅`)            |
| `{{tools_summary}}`               | manifest.tools[] 를 `name version 상태` 표기 (e.g. `tfsec 1.28.5 ✓`)         |
| `{{aws_profile}}`                 | manifest.consent.aws_profile (없으면 `-`)                                    |
| `{{aws_regions}}`                 | manifest.consent.aws_regions (없으면 `-`)                                    |
| `{{api_calls_total}}`             | manifest.api_calls.total                                                     |
| `{{api_calls_by_service_table}}` (v0.5.1.1) | manifest.api_calls 객체에서 `total` 제외한 service 키를 호출 수 내림차순 정렬 후 표 생성. 형식: `\| AWS 서비스 \| 호출 수 \| 비고 \|` 헤더 + service 별 행 + **합계** 행. 비고는 service 의 주요 호출 영역 (e.g. `iam` → "사용자/정책/MFA") — LLM 자동 생성 |
| `{{c1_passed}}`...`{{total_pct}}` | manifest.controls 카운트를 카테고리별 집계 (1.* / 2.* / 3.*)                 |
| `{{c1_auto_total}}` (v0.5.1.1) | 카테고리 1 의 자동 검증 통제 수 (= 4 — controls.json 의 1.x 통제 갯수)                                |
| `{{c2_auto_total}}` (v0.5.1.1) | 카테고리 2 의 자동 검증 통제 수 (= 35 — controls.json 의 2.x 통제 갯수)                               |
| `{{c3_auto_total}}` (v0.5.1.1) | 카테고리 3 의 자동 검증 통제 수 (= 17 — controls.json 의 3.x 통제 갯수)                               |
| `{{unverified_reason_breakdown}}` | manifest.controls.skipped[].reason 의 카운트 분포를 `▢ 라벨: N개` 형식       |
| `{{unverified_controls_table}}`   | manifest.controls.skipped[] 를 `통제ID 통제명 \| 사유라벨 \| 해소가이드` 행으로 |
| `{{path_skill_grep}}` (v0.5.1.1) | manifest.signals_evaluation_path.skill_grep — Tier 0 grep 시그널 평가 횟수 |
| `{{path_skill_glob}}` (v0.5.1.1) | manifest.signals_evaluation_path.skill_glob — Tier 0 glob 시그널 평가 횟수 |
| `{{path_tier0_total}}` (v0.5.1.1) | skill_grep + skill_glob 합 |
| `{{path_tier1_total}}` (v0.5.1.1) | tfsec + checkov + trivy + semgrep 합 (manifest.signals_evaluation_path 의 Tier 1 도구별 카운트 합산) |
| `{{path_tier1_tools_summary}}` (v0.5.1.1) | Tier 1 도구 상태 요약 (e.g. `tfsec/checkov/trivy/semgrep 미설치` 또는 `tfsec 12건 / trivy 3건`) |
| `{{path_direct_cli}}` (v0.5.1.1) | manifest.signals_evaluation_path.direct_cli — Tier 2 LLM 직접 CLI 호출 횟수 |
| `{{path_prowler}}` (v0.5.1.1)    | manifest.signals_evaluation_path.prowler — Tier 2 prowler 검증된 OSS 호출 횟수 |
| `{{path_tier2_note}}` (v0.5.1.1) | Tier 2 도구 상태 보조 메모 (e.g. `(설치되어 있으나 본 점검 미사용)`) |
| `{{path_tier2_total}}` (v0.5.1.1) | direct_cli + prowler + (다른 Tier 2 도구) 합 |
| `{{path_skipped}}` (v0.5.1.1)    | manifest.signals_evaluation_path.skipped — 평가 skip 된 시그널 수 |
| `{{path_grand_total}}` (v0.5.1.1) | tier0 + tier1 + tier2 합 (skip 제외) |
| `{{tier2_path_breakdown}}` (deprecated v0.5.1.1) | v0.5.1 까지의 단축 형식. v0.5.1.1 부터 위 path_* 분해 placeholder 사용 권장 |

### skipped reason 한국어 라벨 매핑

| reason enum                    | 라벨                            | 해소 가이드 예시                          |
|--------------------------------|---------------------------------|-------------------------------------------|
| `tier_not_consented`           | Tier 미동의                     | "Tier {{needed_tier}} 동의 후 재실행"     |
| `domain_not_consented`         | 도메인 미동의                   | "도메인 '{{needed_domain}}' 추가 후 재실행" |
| `tool_missing`                 | 도구 미설치                     | "{{needed_tool}} 설치 (e.g. brew install)" |
| `tier_not_available`           | 환경에서 Tier 차단됨            | "{{needed_tier}} 도구·자격증명 준비 후 재실행" |
| `outside_automatable_scope`    | 자동화 범위 외 (외부 증적 필요) | manifest.note 그대로 표시                 |
| `access_denied`                | 권한 부족                       | "AccessDenied — IAM 권한 추가 후 재실행"  |
| `capability_unknown` (v0.4.5)  | Capability 결과 unknown         | "해당 capability 의 unknown aspect 해소 후 재실행" |
| `manual_review_only` (v0.4.5)  | 수동 검토 전용                  | "외부 증적(정책 문서·교육 기록 등)로 사람이 평가" |

### 부록 B Capability 평가 결과 (v0.4.5 신설 — 기존 §0.6)

> manifest.capability_evaluation[] (schema: `references/manifest.schema.json`)
> 의 결과를 그대로 매핑.

| Placeholder                       | 치환 값 출처                                                                |
|-----------------------------------|------------------------------------------------------------------------------|
| `{{cap_id}}`                      | manifest.capability_evaluation[].capability_id (예: `authentication`)        |
| `{{cap_category}}`                | capabilities.json 의 해당 capability 의 `category` (예: `identity`)          |
| `{{cap_result}}`                  | manifest.capability_evaluation[].result (`satisfied` / `partial` / `fail` / `unknown`) |
| `{{cap_aspect_breakdown}}`        | aspects[] 의 result 카운트를 `1 / 2 / 1 / 0` 형식 (satisfied/partial/unsatisfied/unknown). aspect result enum 은 `satisfied/partial/unsatisfied/unknown` (`fail` 은 capability 결과 enum 전용). 4개 컬럼 합 = 해당 capability 의 verification_aspects 총 갯수. `+ N unsatisfied` 별도 표기 금지 (v0.5.1.1) — unsatisfied 는 컬럼 안에 통합 |
| `{{cap_affecting_controls}}`      | controls.json 에서 해당 capability 를 required_capabilities 에 포함하는 통제 ID 목록 |
| `{{cap_satisfied_n}}`             | manifest.capability_evaluation[] 중 result=satisfied 카운트                  |
| `{{cap_partial_n}}` / `{{cap_fail_n}}` / `{{cap_unknown_n}}` | 동일 패턴 (각 result 별 카운트)                  |

### 부록 A.1 매니페스트 신규 행 (v0.4.5)

| Placeholder                          | 치환 값 출처                                                              |
|--------------------------------------|----------------------------------------------------------------------------|
| `{{stacks_detected_summary}}`        | manifest.stacks_detected[] 를 `name (S)` 형태로 압축. 예: `sst (S) / supabase (S) / sentry (S) / nextjs (S)` (S = Strong / W = Weak / N = None 매칭) |
| `{{capability_satisfied_count}}`     | manifest.capability_evaluation[] 중 result=satisfied 카운트 (= `{{cap_satisfied_n}}`) |
| `{{capability_total}}`               | manifest.capability_evaluation[] 총 행 수 (capabilities.json 의 capability 총 23 개와 일치해야 함) |

### 부록 A.3 LLM 직접 호출 카운트 (v0.4.5)

> manifest.signals_evaluation_path 의 evaluated_via 카운트를 도구별로 분해.
> 사용자가 도구 설치 시 "검증된 룰셋" 으로 자동 전환되는 시그널 수의 정량화.

| Placeholder                  | 치환 값 출처                                                              |
|------------------------------|----------------------------------------------------------------------------|
| `{{prowler_fallback_count}}` | manifest.signals_evaluation_path.direct_cli 중 도구 후보가 prowler 였던 시그널 수 (`tool_missing` 으로 fallback 된 카운트) |
| `{{trivy_fallback_count}}`   | 동일 패턴 — trivy 후보 시그널 수                                          |
| `{{tfsec_fallback_count}}`   | 동일 패턴 — tfsec 후보 시그널 수                                          |
| `{{checkov_fallback_count}}` | 동일 패턴 — checkov 후보 시그널 수                                        |
| `{{semgrep_fallback_count}}` | 동일 패턴 — semgrep 후보 시그널 수                                        |

### §4 finding 메타 신규 (v0.4.5 — 기존 §2)

| Placeholder                       | 치환 값 출처                                                                |
|-----------------------------------|------------------------------------------------------------------------------|
| `{{affected_capabilities}}`       | finding 의 시그널 family → capability aspect 역추적 표기. manifest.capability_evaluation[].aspects[] 중 finding 시그널 family 와 매칭되는 aspect 의 `<capability_id>.<aspect_id> (unsatisfied|partial|fail)` 형식 |

### §-1 한눈에 (v0.4.5.2 신설 → v0.4.6 톤 갱신 → v0.5.1 scope 박스 추가)

> 가장 위 — 메타데이터 표 다음. 1분 안에 읽을 수 있는 길이 (한 화면).

| Placeholder                            | 치환 값 출처                                                            |
|----------------------------------------|---------------------------------------------------------------------------|
| `{{duration_human}}`                   | manifest.scan.duration_seconds → "15분 38초" 형태 (한국어). 938초 → "15분 38초" |
| `{{critical_count}}`                   | manifest.findings[] 중 severity=critical 갯수                            |
| `{{high_medium_count}}`                | manifest.findings[] 중 severity ∈ {high, medium} 갯수                    |
| `{{good_count}}`                       | 양호 사항 (시그널 통과 / 구현된 통제) 갯수 — F-021 류 + capability satisfied aspect 합산 |
| `{{manual_count}}`                     | manifest.controls.unknown.length (외부 증적 필요)                        |
| `{{this_week_actions}}`                | §3 Action Plan 의 P0 항목들. 형식 (v0.4.6 — 비유 없이): "🔴 **[통제 ID] [공식 통제명]** — [구체 조치] ([소요 시간])" 의 번호 매겨진 리스트 |
| `{{this_month_actions}}`               | §3 Action Plan 의 P1 항목들                                              |
| `{{next_quarter_actions}}`             | §3 Action Plan 의 P2 + 외부 증적 항목                                    |
| `{{critical_time_estimate}}`           | P0 합산 소요 시간 (예: "3~5 인일")                                       |
| `{{critical_cost_estimate}}`           | AWS/SaaS 비용 추정 (예: "$50~200")                                       |
| `{{hm_time_estimate}}`                 | P1 합산 소요 시간                                                        |
| `{{manual_time_estimate}}`             | 외부 증적 합산 소요 시간 (외부 자료 수령 포함)                           |
| `{{single_most_important_action}}`     | TOP 1 항목. v0.4.6: 비유 1개 허용 (선택). 사실 + ISMS-P 통제 ID + 법적 근거 |

### §-1 / §1 / §2 / 부록 A.4.1 — Scope 박스 (v0.5.1 신설)

> manifest.scope 객체 (schema: `references/manifest.schema.json`) 의 1:1 미러.
> backward compat: manifest.scope 부재 시 모든 placeholder 미정의 fallback —
> §-1 박스 / §1 scope 컬럼 / §2 ⚪ N/A 라인 / 부록 A.4.1 모두 자동 생략.

| Placeholder                            | 치환 값 출처                                                            |
|----------------------------------------|---------------------------------------------------------------------------|
| `{{repo_role}}`                        | manifest.scope.repo_role (`frontend` / `backend` / `fullstack` / `infra` / `mobile` / `unknown`) |
| `{{confidence}}`                       | manifest.scope.confidence (`high` / `medium` / `low`)                    |
| `{{detection_signals_joined}}`         | manifest.scope.detection_signals[] 의 첫 5개 (쉼표 구분, §-1 박스용)     |
| `{{detection_signals_joined_full}}`    | manifest.scope.detection_signals[] 전체 (쉼표 구분, 부록 A.4.1 용)       |
| `{{observable_count}}`                 | manifest.scope.observable_controls.length                                |
| `{{not_observable_count}}`             | manifest.scope.not_observable_controls.length                            |
| `{{scope_skipped_count}}`              | manifest.controls.skipped[] 중 reason=`scope_not_applicable` 카운트 (= `{{not_observable_count}}` 와 동일해야 함) |
| `{{tier_skipped_count}}`               | manifest.controls.skipped[] 중 reason ∈ {`tier_not_consented`, `domain_not_consented`} 카운트 |
| `{{repo_role_override_or_none}}`       | consent.repo_role_override 값 (사용자 변경 시) 또는 `(없음)`             |
| `{{not_observable_controls_table}}`    | manifest.scope.not_observable_controls[] 를 `\| <control_id> \| <통제명> \| <needs_role[] join '/'> \|` 행으로 |
| `{{#if_not_fullstack}}` ... `{{/if_not_fullstack}}` | scope.repo_role ∉ {`fullstack`, `all`} 일 때만 본문 출력 (보고서 작성 시 conditional 처리). fullstack 은 대부분 통제 포함하므로 "전체 ISMS-P 점검 안내" 박스 자동 숨김 |
| `{{needed_other_roles}}`               | manifest.scope.not_observable_controls[].needs_role 의 unique 합집합 (예: `backend / infra`) |

> §1 통제별 결과 표의 행 단위 `scope` 컬럼 (✓ / ⚪) 은 manifest.scope.observable_controls (포함이면 ✓) / not_observable_controls (포함이면 ⚪) 에 따라 결정.
> scope ⚪ 행은 `결과` 컬럼도 자동 ⚪ 로 표기.

### §5 양호 사항 (v0.4.5.2 → v0.4.6 §5)

| Placeholder                            | 치환 값 출처                                                            |
|----------------------------------------|---------------------------------------------------------------------------|
| `{{good_signals_table}}`               | 양호 사항 표 본문 행. 형식: `\| 영역 \| ✅ 상태 설명 \| 코드/시스템 위치 \|`. 시그널 통과 + capability satisfied + F-021 류 양호 finding 모두 포함 |

### §2 점검 결과 요약 (v0.4.6 갱신 → v0.5.1 scope 분류 추가)

| Placeholder                              | 치환 값 출처                                                            |
|------------------------------------------|---------------------------------------------------------------------------|
| `{{one_line_korean_compliance_summary}}` | 한 줄 평. v0.4.6 — ISMS-P 통제 카테고리 기반. 비유 0. 영어 약어 첫 등장 시 풀어쓰기. v0.5.1 — repo_role / observable_count 첫 문장에 포함 |
| `{{passed_count}}` / `{{total}}`         | 통과 카운트 / 총 카운트 (manifest.controls.passed.length / attempted.length). v0.5.1: total 은 항상 56 표기 |
| `{{partial_count}}`                      | 부분통과 카운트 (manifest.controls.partial.length)                       |
| `{{failed_count}}`                       | 보완 필요 카운트 (manifest.controls.failed.length)                       |
| `{{unknown_count}}`                      | 미검증 카운트 (manifest.controls.unknown.length)                         |
| `{{skipped_consent_count}}` (deprecated) | v0.5.0 까지 — `{{tier_skipped_count}}` 로 대체                            |
| `{{tier_skipped_count}}` (v0.5.1)        | Tier/도메인 미동의 카운트 (manifest.controls.skipped[].reason ∈ {tier_not_consented, domain_not_consented}) |
| `{{scope_skipped_count}}` (v0.5.1)       | scope 외 카운트 (manifest.controls.skipped[].reason = scope_not_applicable). manifest.scope.not_observable_controls.length 와 일치 |

## v0.5.1.1 변경 요약 (보고서 정량 정확성 5개 갭 fix)

- 부록 B Capability 표 컬럼명: `satisfied / partial / fail / unknown aspects` → `satisfied / partial / **unsatisfied** / unknown aspects` (aspect result enum 일관). 표 위에 1줄 안내 추가 (4 카테고리 합 = verification_aspects 총 갯수, 합산 행은 capability 결과 분포)
- 부록 B 의 `+ N unsatisfied` 별도 표기 폐지 — unsatisfied 카운트를 컬럼 안으로 통합
- §2 평가 경로 분포에 Tier 0 (skill_grep / skill_glob) / Tier 1 (tfsec/checkov/trivy/semgrep) / Tier 2 (direct_cli / prowler) / skipped 모든 평가량 표시. 총 평가 시그널 수 명시
- 부록 A.1 에 **서비스별 호출 분포** 표 추가 (`{{api_calls_by_service_table}}`). manifest.api_calls 객체에서 service 별 호출 수 내림차순 정렬
- §-1 "이 레포의 역할 (Scope)" 박스에 56 vs 101 명시 (1줄 점검 범위 안내)
- 부록 A.2 통제 커버리지 표 확장 — 자동 56 vs 공식 101 분리, 자동 검증 미포함 45 통제 카테고리별 breakdown
- 부록 A.1 메타데이터 표에 3 행 추가 (ISMS-P 공식 통제 수 101 / 자동 검증 대상 56 / 외부 증적 영역 45)
- Placeholder 신규: `{{path_skill_grep}}` `{{path_skill_glob}}` `{{path_tier0_total}}` `{{path_tier1_total}}` `{{path_tier1_tools_summary}}` `{{path_direct_cli}}` `{{path_prowler}}` `{{path_tier2_note}}` `{{path_tier2_total}}` `{{path_skipped}}` `{{path_grand_total}}` `{{api_calls_by_service_table}}` `{{c1_auto_total}}` `{{c2_auto_total}}` `{{c3_auto_total}}`
- `{{tier2_path_breakdown}}` deprecated (v0.5.1 까지 사용 — v0.5.1.1 부터 분해 placeholder 권장)
- backward compat: 기존 manifest 1~7차 모두 통과 — manifest.signals_evaluation_path 부재 시 placeholder 미정의 fallback, manifest.api_calls.by_service 부재 시 표 본문 행은 LLM 추정 또는 단일 합계 행만 표시

## v0.5.1 변경 요약

- §-1 "이 레포의 역할 (Scope)" 박스 신설 (메타데이터 표 직후 / 신호등 직전).
  manifest.scope 객체 1:1 미러. fullstack 외 레포에서 "전체 ISMS-P 점검 안내"
  박스 자동 표시 (`{{#if_not_fullstack}}` conditional)
- §1 통제별 결과 표 헤더에 `scope` 컬럼 추가 (16 카테고리 그룹 모두). ✓ / ⚪ 표기
- §1 범례에 ⚪ N/A (역할 외) 분류 신설 — scope ⚪ 행은 `결과` 컬럼도 자동 ⚪
- 16 카테고리 그룹 mini summary 에 ⚪ {{group_X_Y_scope_na}} (역할 외) 카운트 추가
- §-1 신호등 ⚪ N/A 라인 신설 ({{scope_skipped_count}})
- §2 📊 숫자 표현 변경 ("잘 됨" / "일부 OK / 보완 권장" / "보완 필요" / "사람이 봐야 함")
  + ⚪ N/A (이 레포 역할 외) 라인 신설
- §2 한 줄 평 예시 — repo_role / observable_count 첫 문장에 포함
- 부록 A.4.1 "레포 Scope" 절 신설 — manifest.scope 의 1차 출처. N/A 통제 상세 표 + frontend 레포 예시
- 부록 C 자체 검증 명령에 §-1 박스 / §1 scope 컬럼 / §2 ⚪ N/A 검증 3개 추가
- Placeholder 신규: `{{repo_role}}` `{{confidence}}` `{{detection_signals_joined}}`
  `{{detection_signals_joined_full}}` `{{observable_count}}` `{{not_observable_count}}`
  `{{scope_skipped_count}}` `{{tier_skipped_count}}` `{{repo_role_override_or_none}}`
  `{{not_observable_controls_table}}` `{{needed_other_roles}}` `{{group_X_Y_scope_na}}` (×16)
  `{{#if_not_fullstack}}` ... `{{/if_not_fullstack}}` (conditional)
- backward compat: manifest.scope 부재 (v0.4 이전) 시 §-1 박스 / §1 scope 컬럼 /
  §2 ⚪ N/A 라인 / 부록 A.4.1 모두 자동 생략 — placeholder 미정의 fallback

## v0.4.6 변경 요약

- v0.4.5.2 의 §-1 / §0~§0.7 / §1~§7 / 부록 A·B / 부록 X 구조 → v0.4.6 의
  §-1 / §1~§7 / 부록 A/B/C/D 로 재구성
- §1 통제별 결과 (16 카테고리 그룹 × 표) 가 보고서 중심으로 승격 (이전엔 §3 통제 매핑 표)
- §0 매니페스트 / §0.2 도구 / §0.5 인증 범위 → 부록 A 로 이동
- §0.6 Capability 평가 → 부록 B 로 이동
- §0.7 양호 사항 → §5
- §7 미검증 → §6 (이름·내용 동일)
- §5 증적 체크리스트 → §7 (이름·내용 동일)
- "💡 쉽게 말하면" / "⚠️ 안 고치면" 박스 **사용 금지** — finding 본문은 "영향" 1줄 자연어로 통일
- 비유는 §-1 "📌 가장 중요한 한 가지" 부분에만 1개 허용. 그 외 모든 섹션 비유 0
- 영어 코드는 코드 블록·증거 섹션 안에만 (본문 인라인 자제)
- 폐기된 placeholder: `{{friendly_explanation}}`, `{{consequence_if_not_fixed}}`,
  `{{top3_friendly_format}}`, `{{one_line_natural_language_summary}}`,
  `{{required_capabilities_summary}}` (§1 controls_table_* 가 대신함)

## 마스킹 규칙

- 시크릿 토큰: 앞 4자리 + `***REDACTED***` + 끝 4자리
- 주민번호: `XXXXXX-X******` 형태(원본 절대 노출 금지)
- 이메일: `j***@e***.com` 형태
- IP 주소: 사내 IP 는 `10.x.x.x` 옥텟 마스킹, 공인 IP 는 노출 가능
