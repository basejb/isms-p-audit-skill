---
name: Stack Profile 추가 요청
about: 새 framework/SaaS/클라우드 stack 의 시그널 매핑 요청 또는 직접 PR 안내
labels: enhancement, stack-profile
---

## Stack 정보

- 이름: `<예: NestJS / Spring Boot / Cloud Run / Azure App Service>`
- 카테고리: `<iac / baas-db / framework-be / framework-fe / external-saas / korean-saas / hosting / auth / payment>`
- 공급사: `<예: VMware / Google LLC>`
- 공식 문서: `<URL>`

## ISMS-P 관련성

이 stack 이 영향을 주는 ISMS-P 통제 ID (controls.json 참조):

- `<예: 2.6.4 데이터베이스 접근, 2.7.2 암호키 관리, 3.3.4 국외이전>`

## 탐지 방법

이 stack 사용 여부 감지 방법:

- 파일 존재: `<예: nest-cli.json, src/main.ts>`
- package.json 의존성: `<예: @nestjs/core>`
- 기타:

## 시그널 후보

코드/IaC 정적 분석으로 잡을 수 있는 보안 패턴 (예시):

1. `<family>`: `<grep 패턴>` (어떤 보안 우려)
2. ...

## 직접 PR

이 요청을 직접 PR 로 구현하려는 경우 [CONTRIBUTING.md](../CONTRIBUTING.md) 참고. 기존 stack profile 예시:
- `references/stacks/official/nextjs.json` (framework-fe)
- `references/stacks/official/sst.json` (iac)
- `references/stacks/official/gcp-cloud-run.json` (hosting)

작업 후 `pytest tests/` 통과 확인.
