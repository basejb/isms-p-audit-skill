# tests/ — Skill 무결성 자동 검증

pytest 기반 정적 검증.

13회 dogfood 의 정적 검증 가능한 부분을 자동화 — 회귀 방어.

## 실행

```bash
cd skill-design/isms-p-audit
pip install -r tests/requirements.txt
python3 -m pytest tests/ -v
```

## 검증 영역

| 섹션 | 영역 | 테스트 수 (대략) |
|---|---|---|
| A | JSON Schema 자체 무결성 (Draft 2020-12) | 4 |
| B | 데이터 ↔ Schema 검증 (controls / capabilities / 20 stack profile) | 22 |
| C | 참조 무결성 (cross-file ID 매칭) | 3 |
| D | Phase 3 cross-cloud 매핑 일관성 | 1 |
| E | SKILL.md BLOCKING 키워드 정적 검증 | 8 |
| F | 스택 프로필 개수 검증 (Phase 3.3) | 2 |
| G | 통제 카운트 정합성 (56 / 23 / 52+) | 3 |
| H | README 메타 검증 (dogfood 13회 / BLOCKING 갯수 일관성) | 2 |

**총 약 45개 테스트** — 모두 통과 시 v0.7-pre 표준 충족.

## CI 통합

`.github/workflows/test.yml` (별도 추가 예정):

```yaml
name: skill-integrity
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -r skill-design/isms-p-audit/tests/requirements.txt
      - run: python3 -m pytest skill-design/isms-p-audit/tests/ -v
```

## 새 테스트 추가 가이드

1. `test_skill_integrity.py` 에 함수 추가 — `test_` prefix
2. BLOCKING 항목에 대응되는 정적 검증이면 섹션 E 의 `BLOCKING_REQUIRED_TOKENS` 에 키워드 추가
3. 스택 추가 시 섹션 F 의 `expected` 리스트 갱신
4. 통제 개수 변경 시 (v0.7+) 섹션 G 의 expected 갱신
