# ISMS-P Audit — Stack Profiles

`isms-p-audit` Skill v0.4 부터 **메이저 스택별 시그널** 을 별도 profile 로 분리한다.
controls.json 은 통제(ID/이름/카테고리) + **stack-agnostic 시그널** 만 보유하고,
SST/Supabase/Sentry/Next.js/Prisma 같은 스택 특화 시그널은 이 디렉터리의
profile 들이 담당한다.

## 5단계 커버리지 전략 (Tier S/C/U/A/G)

| Tier | 위치 | 설명 |
|------|------|------|
| **S** — Skill 내장 | `references/stacks/official/*.json` | 메이저 스택을 Skill 패키지에 동봉. v0.4 = 16개 (시드 5개 + Sprint 2-A 11개: 메이저 IaC/Hosting/Observability/BaaS 6개 + 한국 결제·인증 5개). |
| **C** — Community 공유 | `references/stacks/community/*.json` (별도 레포) | v0.5 에서 `<org>/stack-profiles` GitHub 레포로 공개 예정. 사용자가 PR 로 새 stack 기여. |
| **U** — User 로컬 | `<project>/.isms-audit/stacks/*.json` | 사용자 프로젝트 자산. Skill 은 자동수정 절대 금지. 같은 stack id 가 S/C 에 있으면 U 가 override. |
| **A** — LLM auto-discovery | (v0.5 영역) | 미지원 스택 탐지 시 LLM 이 임시 profile 을 추론. |
| **G** — Stack Profile Generator | (v0.5 영역) | LLM 결과를 검토 후 community profile 로 승격. |

## 우선순위·충돌 규칙

- **같은 stack id** 가 여러 Tier 에 있으면 가까운 위치 우선: **Tier U > C > S**.
- **같은 family 시그널** 이 여러 profile 에 있으면 가까운 위치 우선 + profile 의
  `disable_signals: [<family>]` 로 명시적 비활성화 가능.
- **detection 룰** (`detection.any_of`) 은 1개라도 매치하면 그 stack 활성.
- 사용자가 `.isms-audit.yml` 에 `stacks.force_disable: [<stack_id>]` 명시하면
  detection 매치되어도 비활성화한다 (§13 비대화 모드 참조).

## 새 stack profile 추가하기

1. **스키마 확인**: `references/stack-profile.schema.json` (Draft 2020-12).
2. **파일 생성**:
   - Tier U: `<your-project>/.isms-audit/stacks/<stack-id>.json`
   - Tier S/C: 본 레포에 PR.
3. **필수 필드**: `schema_version: "1"`, `stack`, `detection`, `signals` (최소 1개).
4. **검증**:
   ```bash
   python3 -c "
   import json
   from jsonschema import Draft202012Validator
   schema = json.load(open('references/stack-profile.schema.json'))
   profile = json.load(open('<your-profile>.json'))
   errors = list(Draft202012Validator(schema).iter_errors(profile))
   print('OK' if not errors else errors)
   "
   ```

## 기존 official profile 카탈로그 (v0.4)

### 시드 5개 (Sprint 1.5)

| stack id | category | detection 핵심 | 매핑 통제 |
|----------|----------|----------------|-----------|
| `sst` | iac | `sst.config.{ts,js,mjs}`, `sst` package | 2.5.5 / 2.6.1 / 2.7.2 |
| `supabase` | baas-db | `supabase/config.toml`, `@supabase/supabase-js` | 2.6.4 / 3.2.5 / 2.5.5 / 2.7.2 |
| `sentry` | external-saas | `sentry.{client,server}.config.*`, `@sentry/*` | 3.1.1 / 3.3.4 |
| `nextjs` | framework-fe | `next.config.*`, `next` package | 2.10.1 / 2.10.4 / 2.6.3 |
| `prisma` | baas-db | `prisma/schema.prisma`, `@prisma/client` | 2.7.2 / 3.2.5 / 3.2.4 |

### 메이저 IaC/Hosting/Observability/BaaS 6개 (Sprint 2-A)

| stack id | category | detection 핵심 | 매핑 통제 |
|----------|----------|----------------|-----------|
| `cdk` | iac | `cdk.json`, `aws-cdk-lib`, `lib/*-stack.{ts,py}` | 2.5.5 / 2.6.1 / 2.7.2 |
| `pulumi` | iac | `Pulumi.yaml`, `@pulumi/*` package | 2.5.5 / 2.6.1 / 2.7.2 |
| `firebase` | baas-db | `firebase.json`, `firestore.rules`, `firebase`/`firebase-admin` | 2.6.4 / 3.2.5 / 2.5.3 / 2.7.2 / 3.3.4 |
| `datadog` | external-saas | `dd-trace`, `@datadog/*`, `datadog-cdk-constructs*` | 3.1.1 / 3.3.4 / 2.7.2 |
| `vercel` | hosting | `vercel.json`, `@vercel/*` package | 2.7.2 / 2.10.1 / 3.3.4 |
| `cloudflare-workers` | hosting | `wrangler.toml`, `wrangler`, `@cloudflare/workers-types` | 2.7.2 / 2.6.1 / 2.6.4 / 3.3.4 |

### 한국 결제·인증 5개 (Sprint 2-A)

| stack id | category | detection 핵심 | 매핑 통제 |
|----------|----------|----------------|-----------|
| `nicepay` | payment | `nicepay.co.kr` 호스트, `AUTHNICE.requestPay` | 2.7.2 / 3.2.5 / 3.3.2 / 2.7.1 |
| `toss-payments` | payment | `@tosspayments/*` package, `api.tosspayments.com` | 2.7.2 / 3.2.5 / 3.3.2 |
| `kcp` | payment | `kcp.co.kr` 호스트 | 2.7.2 / 3.3.2 / 3.2.5 |
| `kakao-login` | auth | `kauth.kakao.com`, `KakaoProvider`, `@react-native-seoul/kakao-login` | 2.7.2 / 3.1.1 / 3.3.2 |
| `naver-login` | auth | `nid.naver.com`, `NaverProvider`, `react-naver-login` | 2.7.2 / 3.1.1 / 3.3.2 |

> 한국 결제 stack 의 핵심 시그널: **결제정보(카드번호/CVV/계좌) 자체 저장 부재** + **시크릿 평문 부재** + **PG 위탁 매트릭스 명시(3.3.2)**.
> 한국 OAuth stack 의 핵심 시그널: **client secret 평문 부재** + **동의 항목과 저장 컬럼 정합성** + **redirect_uri 운영 환경 검증**.

## Tier U 사용 가이드

1. 프로젝트 루트에 `.isms-audit/stacks/` 디렉터리 생성:
   ```bash
   mkdir -p .isms-audit/stacks
   ```
2. 사내 사용 스택 profile 작성 (`<id>.json`).
3. `.gitignore` 에 `.isms-audit/runs/` `.isms-audit/reports/` 만 추가, `stacks/`
   는 커밋 (사내 공유 자산).
4. 다음 audit 실행 시 자동 감지·로드 (Tier U > C > S 순).

> Skill 본체는 `<project>/.isms-audit/stacks/` 를 **읽기만** 한다. 자동 생성·
> 수정·삭제 일절 금지. 새 stack profile 작성은 사용자/팀 책임.

## community 레포 (v0.5 영역)

v0.5 에서 `<org>/stack-profiles` GitHub 레포로 공개 예정.
사용자는 `git submodule` 또는 `git submodule update` 로 community profile 을
받을 수 있게 된다 (현재 v0.4 에서는 placeholder 만 제공).
