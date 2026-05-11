#!/usr/bin/env bash
# init-gitignore.sh — isms-p-audit Skill 첫 실행 시 작업 디렉터리 초기화.
#
# 사용자 프로젝트에 부수효과를 주는 유일한 스크립트 — Skill Step 1.7 끝에서
# 명시 동의를 받고 호출한다. 사용자 프로젝트의 `.gitignore` 는 절대 자동
# 수정하지 않으며, 누락 시 안내 메시지만 출력한다.
#
# 사용법:
#   bash init-gitignore.sh [프로젝트 루트 경로]
#
# 출력: stdout 으로 JSON 1개 (Skill 본체가 파싱해 manifest.data_retention 채움)
# 종료코드: 0 성공, 1 경로 오류
set -euo pipefail

ROOT="${1:-$(pwd)}"
if [[ ! -d "$ROOT" ]]; then
  echo "{\"error\":\"path not found: $ROOT\"}" >&2
  exit 1
fi

DIR="$ROOT/.isms-audit"

# 1) 디렉터리 + 하위 폴더
mkdir -p "$DIR/runs" "$DIR/reports"

# 2) .isms-audit/.gitignore — 디렉터리 통째로 ignore
if [[ ! -f "$DIR/.gitignore" ]]; then
  cat > "$DIR/.gitignore" <<'EOF'
# isms-p-audit Skill v0.3+ 산출물 — git 에 commit 하지 않음.
# 매니페스트에 AWS profile 이름·리전·도구 버전 같은 환경 정보가 들어가서
# 외부 노출 시 정보 자산 식별 위험.
*
!.gitignore
EOF
fi

# 3) 프로젝트 .gitignore 에 권장 라인이 없으면 안내 메시지만 출력 (자동 수정 X)
PROJECT_GITIGNORE="$ROOT/.gitignore"
RECOMMENDED=".isms-audit/"
PROJECT_GI_PRESENT=false
PROJECT_GI_HAS_LINE=false

if [[ -f "$PROJECT_GITIGNORE" ]]; then
  PROJECT_GI_PRESENT=true
  if grep -qF "$RECOMMENDED" "$PROJECT_GITIGNORE"; then
    PROJECT_GI_HAS_LINE=true
  else
    echo "[isms-p-audit] 프로젝트 .gitignore 에 다음 줄 추가 권장:" >&2
    echo "    $RECOMMENDED" >&2
  fi
else
  echo "[isms-p-audit] 프로젝트 루트에 .gitignore 가 없습니다." >&2
  echo "[isms-p-audit] $RECOMMENDED 를 포함하는 .gitignore 작성 권장." >&2
fi

# 4) 결과 출력 (Skill 본체가 읽을 수 있는 JSON)
cat <<EOF
{
  "isms_audit_dir":             "$DIR",
  "manifest_dir":               "$DIR/runs",
  "report_dir":                 "$DIR/reports",
  "skill_gitignore_present":    true,
  "project_gitignore_present":  $PROJECT_GI_PRESENT,
  "project_gitignore_has_line": $PROJECT_GI_HAS_LINE
}
EOF
