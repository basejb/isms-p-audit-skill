# isms-p-audit

ISMS-P (한국 정보보호 및 개인정보보호 관리체계) 인증 사전 점검을 자동화하는 Claude Skill.

> 코드 / IaC / 클라우드 설정만 보고 56개 ISMS-P 통제의 OK · NG · 외부 증적 필요 여부를 점검 보고서로 만듭니다. 인증 심사 전 사내 보안 상태를 빠르게 점검하고 싶은 개발자 · CISO · CPO 가 대상입니다.

>
> **ISMS-P 인증을 준비하지 않더라도** 개발자 · DevOps 의 자체 클라우드 보안 진단 · 정기 위생 점검 도구로 활용 가능합니다. SOC 2 / ISO 27001 / NIST CSF 준비 baseline 으로도 활용 가능. 자세한 매핑은 `references/cross_framework_mapping.json` 참고.

---

## 이 Skill이 만드는 것

Claude Code 에서 ISMS-P 점검을 트리거하면 `<프로젝트 루트>/.isms-audit/` 아래 두 파일이 생성됩니다:

- **`reports/<timestamp>.md`** — 사람이 읽는 점검 보고서 (Markdown)
- **`runs/<timestamp>.json`** — 보고서의 원본 데이터 (JSON 매니페스트)

---

## 이 Skill의 점검 범위

이 Skill은 **코드와 인프라 설정만 보고 판단할 수 있는 항목만** 다룹니다. 정책 문서 · 교육 이수 · 물리 출입 통제 · CISO 임명 같이 코드로 보이지 않는 영역은 다루지 않습니다.

```
ISMS-P 공식 통제 (KISA 안내서 2023.11) = 101 개
  ├── 1. 관리체계 수립 및 운영      (16)
  ├── 2. 보호대책 요구사항          (64)
  └── 3. 개인정보 처리단계별 요구사항 (21)

이 Skill이 자동 점검하는 영역 = 56 통제 (약 55%)
  ├── 코드 / IaC 정적 분석으로 확인 가능
  ├── 클라우드 read-only API 호출로 확인 가능
  └── 컨테이너 / K8s 런타임 쿼리로 확인 가능

이 Skill이 다루지 않는 영역 = 45 통제 (외부 증적 영역)
  ├── 1.x 관리체계 12개      — 정책 수립 · CISO 임명 · 내부감사 (문서·인적 통제)
  ├── 2.1 ~ 2.4 영역 29개    — 정보보호 정책 · 인적보안 · 외주관리 · 물리보안 (계약·교육·물리)
  └── 3.x 일부 4개           — 정보주체 동의·고지 (LLM 본문 분석 + 외부 증적)
```

자동 점검 불가 영역은 보고서의 **"미검증 통제 + 사유"** 섹션에 명시적으로 분류되며, 사내 보안 문서고 또는 별도 증적 관리 채널에서 관리해야 합니다.

### 명시적 한계

- 이 Skill은 **공식 인증 심사가 아닙니다** — 사전 진단용. 최종 인증은 KISA · 인증기관 심사관이 수행
- 보안 **점수 · 등급을 부여하지 않습니다** — capability · 통제별 평가 결과만 제공
- 코드를 **자동으로 수정하지 않습니다** — 읽기 · 분석만, 수정 권한은 사용자에게
- 클라우드 자원을 **변경하지 않습니다** — 모든 API 호출은 read-only (`describe-*` / `list-*` / `get-*`)

---

## 클라우드 지원 범위

| 클라우드 | 지원 |
|---|---|
| AWS | ✅ 1차 지원 (cloud_api 시그널 52 / prowler 룰셋 매핑) |
| Kubernetes | ✅ 멀티클라우드 (EKS / GKE / AKS) |
| GCP | △ 베타 (25 시그널 매핑 + Cloud Run · SQL stack profile) |
| Azure | △ 베타 (36 시그널 매핑 + App Service · Functions stack profile) |
| NHN / KT / 네이버 | ❌ 향후 로드맵 |

GCP / Azure 는 실환경 dogfood 가 진행되면 안정으로 승격됩니다. 총 stack profile 20종.

---

## 설치

Claude Code 가 설치돼 있어야 합니다 (`~/.claude/skills/` 디렉터리 존재 확인). 세 가지 설치 방법 중 환경에 맞는 것을 고르세요.

### 옵션 1 — Claude Code 에 맡기기 (처음 사용자 권장)

Claude Code 를 열고 다음 문구를 그대로 붙여넣으세요:

```
isms-p-audit Skill 을 설치해줘.
git clone https://github.com/basejb/isms-p-audit-skill ~/.claude/skills/isms-p-audit
설치 후 ls -la ~/.claude/skills/isms-p-audit/SKILL.md 로 확인
```

Claude 가 git clone + 검증까지 자동 수행합니다. 처음 사용자에게 가장 권장.

### 옵션 2 — 한 줄 명령어 (자동화·CI 권장)

```bash
git clone https://github.com/basejb/isms-p-audit-skill ~/.claude/skills/isms-p-audit && \
  echo "설치 완료 — Claude Code 에서 '/isms-p-audit' 또는 'ISMS-P 점검' 트리거"
```

- 자동화 스크립트 · CI 환경에 적합. `git pull` 로 즉시 최신 버전 반영.

### 설치 확인 · 업그레이드

```bash
# 설치 확인
head -5 ~/.claude/skills/isms-p-audit/SKILL.md   # SKILL.md frontmatter 출력 시 정상

# 업그레이드
cd ~/.claude/skills/isms-p-audit && git pull
```

---

## 권장 외부 도구

Skill 자체는 외부 도구 없이도 동작합니다 (Tier 0 정적 분석만 사용). 단 **prowler 설치는 강력 권장** — Tier 2 클라우드 점검의 96% 가 prowler 검증된 OSS 룰셋으로 평가됩니다.

```bash
brew install prowler-cloud/tap/prowler
```

도구가 없으면 manifest 에 `tool_missing` 으로 기록되고 자동 skip — 점검 중단 안 됨.

---

## 사용법

### 기본 사용 — 인터랙티브 모드

Claude Code 를 점검할 프로젝트 디렉터리에서 실행:

```bash
cd /path/to/your-project
claude
```

그리고 트리거:

```
ISMS-P 점검 좀 해줘
```

또는:

```
/isms-p-audit
```

Skill 이 자동으로 다음 흐름을 따릅니다:

1. 프로젝트 메타정보 추출 (언어 / 프레임워크 / IaC / DB / Stack)
2. **레포 역할 자동 감지** (frontend / backend / fullstack 등) + 사용자 확인
3. 환경 탐지 (외부 도구 / 자격증명 / 통제 커버리지)
4. **Tier 선택** (검증 범위) — 4개 옵션 중 선택:
   - 코드만 검증 (외부 권한·도구 0) — 약 16 통제
   - 코드 + 외부 정적 도구 — 약 24 통제
   - 코드 + 외부 도구 + AWS read-only — 약 42 통제 (권장)
   - 모든 영역 (Kubernetes 포함) — 약 48 통제
5. **AWS 자격증명 출처** 선택 (Tier 2 선택 시) — 감지된 모든 profile 중에서 선택
6. 통제별 평가 + 보고서 생성

## 동작 환경

- **macOS / Linux**: 네이티브 지원
- **Windows**: WSL2 필요 (Windows native 미지원 — helper 스크립트 `scan.sh` · `init-gitignore.sh` 와 부록 C self-check 명령이 모두 bash 3.x+ 기반). `wsl --install -d Ubuntu-22.04` 후 WSL2 셸에서 Claude Code + 본 Skill 설치
- Claude Code v2.0+ (Skills 지원 버전)
- Bash 3.x 이상
- Python 3.6+ (manifest schema 검증용, 선택)
- 외부 도구 (선택): prowler / tfsec / Checkov / Trivy / Semgrep / aws-cli / gcloud / az / kubectl

---

## 기여

새 Stack Profile / Capability / 외부 도구 어댑터 기여 환영:

- Stack profile: `references/stacks/community/` 에 PR
- Capability: `references/capabilities.json` 에 PR (스키마 검증 통과 필요)
- 외부 도구 어댑터: 별도 문서 참고

기여 가이드는 `CONTRIBUTING.md` (별도 작성 예정).

---

## 라이선스

Apache-2.0

---

## 인용

```bibtex
@software{isms_p_audit_skill,
  title  = {isms-p-audit Claude Skill},
  author = {basejb},
  year   = {2026},
  url    = {https://github.com/basejb/isms-p-audit-skill}
}
```

---

## 면책

본 Skill 의 점검 결과는 **자동화 사전 진단** 이며 KISA / 인증기관의 공식 인증 심사 결과가 아닙니다. 최종 판단은 사내 정보보호책임자(CISO/CPO) 및 공식 심사원의 검토를 받아야 합니다.

자세한 통제 매핑 검증 출처는 `references/manifest.schema.json` / `references/controls.json` / `mapping/verification-report.md` 참고.
