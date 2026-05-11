# PR 체크리스트

## 변경 영역

- [ ] Stack Profile 추가/수정 (`references/stacks/`)
- [ ] Cross-framework mapping (`references/cross_framework_mapping.json`)
- [ ] controls.json 통제 추가/변경 (KISA 안내서 개정 대응)
- [ ] capabilities.json aspect 변경
- [ ] SKILL.md 워크플로우 변경
- [ ] scan.sh / init-gitignore.sh 변경
- [ ] 테스트 추가
- [ ] 문서 (README / CONTRIBUTING / CHANGELOG)
- [ ] 기타: `<설명>`

## 변경 요약

`<1~3 문장 — 무엇을 / 왜>`

## 검증

- [ ] `pytest tests/ -v` 통과 (51 tests, 0 failure)
- [ ] 변경된 `*.json` 파일이 해당 `*.schema.json` 통과
- [ ] BLOCKING 체크리스트 19항 (`SKILL.md §5.3`) 영향 없음
- [ ] dogfood 수행 후 보고서 정합성 확인 (자체 환경)
- [ ] `CHANGELOG.md` 에 변경 사항 1줄 추가

## dogfood 결과 (해당 시)

- 환경: `<프로젝트명 + stack>`
- skill_version: `isms-p-audit@<X.Y.Z>`
- BLOCKING 19항 모두 통과: yes/no
- Schema validation: PASS/위반 N건
- 통제 결과: passed N / partial N / failed N / unknown N

## 관련 이슈

Closes #`<issue#>`
