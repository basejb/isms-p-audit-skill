# Capability 모델 (v0.4 단계 1)

isms-p-audit Skill 의 핵심 추상화. ISMS-P 통제와 시그널 사이를 매개하는 **스택 무관 (stack-agnostic) 보안 능력 카탈로그**.

비전 — *"Skill = 컴플라이언스 인덱서 / 가능성 탐지기"* — 에서 출발한다 (a.txt). 3계층 아키텍처:

```
Core (capability)  ──>  Stack Adapter  ──>  Evidence Mapper
스택 무관 보안 능력      스택별 시그널 매핑     ISMS-P 통제 매핑/리포트
```

이 폴더의 자료는 **Core 계층**에 해당한다.

---

## 5단 흐름

```
control (ISMS-P 통제)
   ↓ required_capabilities
capability (스택 무관 보안 능력)
   ↓ verification_aspects
aspect (검증 측면)
   ↓ satisfied_by_signal_families
signal_family (시그널 그룹 식별자)
   ↓ controls.json + stacks/official/*.json
실제 시그널 (glob/grep/file_content/cloud_api/cluster_query/manual_review)
```

예시:

```yaml
control 2.7.1 (전송구간 암호화):
  required_capabilities:
    - encryption_in_transit
capability encryption_in_transit:
  verification_aspects:
    - cloudfront_tls_modern  → family: cloudfront_tls
    - alb_tls_modern         → family: alb_tls
    - tls_verify_enabled     → family: tls_verify_disabled
    - weak_cipher_absent     → family: crypto_weak, tls_weak, ...
signal_family cloudfront_tls:
  controls.json signals: grep_pattern, grep_absent, ...
```

---

## 파일 구조

```
references/
├── capability.schema.json      # JSON Schema (Draft 2020-12)
├── capabilities.json           # 17개 시드 capability 카탈로그
└── capabilities/
    └── README.md               # 이 문서
```

`capabilities.json` 의 `satisfied_by_signal_families` 필드는 `controls.json` 및 `stacks/official/*.json` 에 실제로 존재하는 `family` 값과 일치해야 한다 (단계 1 검증 통과).

---

## 17개 시드 (단계 1)

| Category         | Capability                  | Aspects | ISMS-P 관련 통제          |
|------------------|-----------------------------|---------|---------------------------|
| identity         | authentication              | 4       | 2.5.3, 2.5.4              |
| identity         | mfa_enforcement             | 2       | 2.5.3                     |
| identity         | account_lifecycle           | 3       | 2.5.1, 2.5.6              |
| access           | access_control              | 6       | 2.5.5, 2.6.2              |
| access           | application_access_control  | 2       | 2.6.3, 2.6.2              |
| network          | network_isolation           | 4       | 2.6.1, 2.6.4, 2.6.6       |
| network          | internet_egress_control     | 1       | 2.6.7                     |
| crypto           | encryption_at_rest          | 3       | 2.7.2, 3.2.5              |
| crypto           | encryption_in_transit       | 4       | 2.7.1, 2.10.5             |
| crypto           | secrets_management          | 3       | 2.7.2                     |
| logging          | audit_logging               | 2       | 2.9.4, 2.9.5              |
| logging          | log_monitoring              | 1       | 2.11.3, 2.9.5             |
| data-protection  | data_minimization           | 2       | 3.1.1, 3.1.2              |
| data-protection  | data_retention              | 2       | 3.4.1, 3.4.2              |
| data-protection  | subject_rights              | 3       | 3.5.1, 3.5.2, 3.5.3       |
| compliance       | third_party_disclosure      | 2       | 3.3.1, 3.3.2, 3.3.4       |
| compliance       | incident_response (보너스)  | 2       | 2.11.1, 2.11.4, 2.11.5    |

---

## Capability 추가 가이드

### 1. 무엇이 capability 인가?

**스택 무관한 보안 능력**. "AWS 의 KMS" 가 아니라 "저장 암호화 (encryption_at_rest)". "AWS 의 CloudTrail" 이 아니라 "감사로그 (audit_logging)".

### 2. 추가 절차

1. `capability.schema.json` 의 `category` enum 에 부합하는지 확인 (필요 시 enum 확장 PR).
2. `capabilities.json` 의 `capabilities` 배열에 신규 capability 추가:
   - `id` snake_case, 유니크
   - `verification_aspects` 1개 이상
   - 각 aspect 의 `satisfied_by_signal_families` 는 controls.json / stacks/official 에 실제 존재하는 family 만 사용 (또는 evidence_hint 에 신규 family 도입 후보 명시)
3. `isms_p_relevance` 에 관련 ISMS-P 통제 ID (e.g. "2.7.1") 명시.
4. 검증:
   ```bash
   python3 -c "
   import json
   from jsonschema import Draft202012Validator
   schema = json.load(open('references/capability.schema.json'))
   data   = json.load(open('references/capabilities.json'))
   Draft202012Validator.check_schema(schema)
   errors = list(Draft202012Validator(schema).iter_errors(data))
   assert not errors, errors
   print('OK')
   "
   ```

### 3. 신규 family 가 필요할 때

기존 family 로 표현되지 않는 검증이 필요하면:

- 단계 2 (controls.json 확장) 또는 단계 3 (stacks 확장) 에서 신규 family 가 controls.json / stacks/official/*.json 에 추가될 때까지 대기
- 그 동안 capability 의 `verification_aspects[].evidence_hint` 에 "단계 N 도입 후보" 로 명시
- 후보 family 예: `archive_separation` (3.4.2), `db_public_runtime` (2.6.4 런타임 검증)

---

## 단계 로드맵 (v0.4)

| 단계 | 작업                                                              | 상태       |
|------|-------------------------------------------------------------------|------------|
| 1    | Capability 모델 + 스키마 + 17개 시드                              | **(이번)** |
| 2    | controls.json 의 56개 통제에 `required_capabilities` 필드 주입   | 예정       |
| 3    | stacks/official/*.json 에 capability 매핑 보강 + 신규 family 추가 | 예정       |
| 4    | scan.sh 가 capability 단위로 시그널 묶음 처리                    | 예정       |
| 5    | report-template.md 가 capability 미충족 ↔ 통제 자동 매핑          | 예정       |
| 6    | 사용자 자체 capability 정의 (커뮤니티/조직별 확장 포인트)         | 예정       |

---

## 참고 비전 인용 (a.txt)

> Skill = 컴플라이언스 인덱서 / 가능성 탐지기.
> 사용자의 코드/IaC 에서 보안 capability 가 *얼마나 가능한가* 를 탐지하고,
> ISMS-P 통제 충족 가능성으로 인덱싱한다.

캡처된 통제 충족 여부는 capability aspect 충족 여부의 합으로 도출된다 — LLM 자율 판단 영역을 줄이고, 구조화된 매핑이 LLM 의 갭을 자연스럽게 메운다.
