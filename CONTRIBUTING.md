# Contributing to isms-p-audit

이 Skill 에 기여하기 전에 [README.md](README.md) + [SKILL.md](SKILL.md) 를 먼저 읽어주세요.

## 기여 영역

### 1. Stack Profile 추가 (가장 환영)

새로운 framework / SaaS / 클라우드 stack 의 ISMS-P 통제 시그널 매핑:

```bash
# 1. 기존 stack profile 참고
cp references/stacks/official/nextjs.json references/stacks/community/<your-stack>.json

# 2. detection 룰 + signals[] + capabilities 매핑 작성
#    스키마: references/stack-profile.schema.json

# 3. pytest 통과 확인
python3 -m pytest tests/ -v

# 4. PR
```

**참고 — 시그널 family 가 capabilities.json 의 satisfied_by_signal_families 에 포함돼야** orphaned 검증 실패 (tests/test_skill_integrity.py:test_capability_families_match_existing_signals).

### 2. Cross-framework 매핑 보강

ISMS-P 56 통제 ↔ 글로벌 framework 매핑 (`references/cross_framework_mapping.json`):

- candidate / partial 매핑을 verified 로 격상
- ISO 27701 (PIMS) / NIST Privacy Framework / CIS Controls v8 등 추가 framework
- 출처 (KISA 공식 매핑 표 / NIST informative reference / ISO 공식 매핑) 함께 PR

### 3. controls.json 통제 추가

KISA ISMS-P 안내서 개정 시 (현재 v2023.11):

```bash
# 1. controls.json 갱신 + cross_framework_mapping.json 매핑 추가
# 2. schema_version + last_verified 업데이트
# 3. pytest 통과 확인
```

### 4. 외부 도구 어댑터 추가

prowler / tfsec / Checkov / Trivy / Semgrep 외의 OSS 도구:

- `SKILL.md` §2 Step 2.1 의 도구 우선순위 표에 추가
- frontmatter `allowed-tools` 에 도구 명령 추가
- 시그널의 `fallback_tool` 필드에 도구 이름 박제

## 개발 환경 설정

```bash
# 클론 + 개발 셋업
git clone https://github.com/basejb/isms-p-audit-skill
cd isms-p-audit-skill

# Python 의존성 (pytest + jsonschema)
pip install -r tests/requirements.txt

# pytest 자동 회귀 방어
python3 -m pytest tests/ -v
```

## PR 체크리스트

PR 제출 전:

- [ ] `pytest tests/ -v` 통과 (51 tests, 0 failure)
- [ ] 변경된 `*.json` 파일이 해당 `*.schema.json` 통과
- [ ] BLOCKING 체크리스트 19항 (`SKILL.md §5.3`) 영향 없음
- [ ] dogfood 수행 후 보고서 정합성 확인 (자체 환경)
- [ ] `CHANGELOG.md` 에 변경 사항 1줄 추가
- [ ] 새 시그널·매핑은 `references/<해당 파일>` 의 `last_verified` 갱신

## 코드 스타일

- **JSON 파일**: 2-space indent. signal 객체는 1줄 (controls.json + stack profile)
- **마크다운**: 본문 비유 금지 (SKILL.md §5.2 톤 정책)
- **bash 스크립트**: shellcheck 무경고 권장. `bash -n` 통과 필수.
- **Python 테스트**: pytest + jsonschema 만. 외부 의존성 추가 시 PR 에 사유

## 코드 검토 절차

1. PR 제출 → GitHub Actions 자동 `pytest tests/` 실행
2. 회귀 0 확인
3. Reviewer 가 dogfood 1회 (자기 환경 또는 환경 A) 검증 후 merge
4. 새 dogfood 결과는 README 의 dogfood 표에 행 추가

## 보안 이슈 보고

ISMS-P 점검 자체의 보안 이슈 발견 시:
- 공개 issue 대신 `security@yourdomain.example` (또는 별도 채널) 으로 비공개 보고
- 점검 보고서 의 마스킹 누락·민감정보 노출 같은 이슈 우선순위

## 라이선스 합의

본 레포에 기여 시 [Apache-2.0 License](LICENSE) 조건에 동의함을 명시합니다.
