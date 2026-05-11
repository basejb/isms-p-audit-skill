#!/usr/bin/env bash
# scan.sh — isms-p-audit Skill 의 프로젝트 메타정보 추출 + 환경 탐지 스크립트
#
# 사용법:
#   bash scan.sh [프로젝트 루트 경로] [--tools-only] [--no-coverage]
#
# 출력: stdout 으로 JSON 1개 (Skill 본체가 파싱)
# 종료코드: 0 성공, 1 경로 오류
#
# v0.3 추가 섹션: tools_inventory, cloud_creds, coverage_estimate
# 자격증명 값(키/토큰) 은 절대 출력하지 않음. boolean / 이름 / 경로만.

set -uo pipefail
# NOTE: -e 를 의도적으로 끔. 외부 도구 탐지/자격증명 감지 단계에서
# 어떤 명령이 실패해도 스크립트 자체가 죽으면 안 됨.

# ---- 인자 파싱 ----
TOOLS_ONLY=false
NO_COVERAGE=false
ROOT=""
for arg in "$@"; do
  case "$arg" in
    --tools-only)  TOOLS_ONLY=true ;;
    --no-coverage) NO_COVERAGE=true ;;
    *)             [[ -z "$ROOT" ]] && ROOT="$arg" ;;
  esac
done
ROOT="${ROOT:-$(pwd)}"

if [[ ! -d "$ROOT" ]]; then
  echo "{\"error\":\"path not found: $ROOT\"}" >&2
  exit 1
fi

# Skill 디렉터리 (controls.json 위치 기준)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTROLS_JSON="$SCRIPT_DIR/../references/controls.json"

cd "$ROOT"

# ---- 0. 보조 함수 ----
has_file() { [[ -e "$1" ]] && echo "true" || echo "false"; }

# JSON 문자열 escape (백슬래시 + 큰따옴표 + 제어문자 최소).
json_escape() {
  # stdin → escaped string (값 부분만, 따옴표는 호출자가 붙임)
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  # 줄바꿈/탭 제거 (단일 라인 가정)
  s="${s//$'\n'/ }"
  s="${s//$'\t'/ }"
  s="${s//$'\r'/ }"
  printf '%s' "$s"
}

# 명령이 hang 하지 않도록 timeout(있으면) 으로 래핑. 첫 줄만 캡처.
HAS_TIMEOUT="$(command -v timeout 2>/dev/null || command -v gtimeout 2>/dev/null || true)"
run_capture_first_line() {
  # $@: 명령 + 인자
  local out=""
  if [[ -n "$HAS_TIMEOUT" ]]; then
    out="$("$HAS_TIMEOUT" 5 "$@" 2>/dev/null | head -1 || true)"
  else
    out="$("$@" 2>/dev/null | head -1 || true)"
  fi
  printf '%s' "$out"
}

# 도구 1개 탐지: name / version-cmd-args
# 출력: JSON object {"found": bool, "version": ..., "path": ...}
detect_tool() {
  local name="$1"; shift
  local path
  path="$(command -v "$name" 2>/dev/null || true)"
  if [[ -z "$path" ]]; then
    printf '{ "found": false, "version": null, "path": null }'
    return
  fi
  local version=""
  if [[ $# -gt 0 ]]; then
    version="$(run_capture_first_line "$@")"
  fi
  # 결과 normalize: null 이면 null, 아니면 escaped string
  if [[ -z "$version" ]]; then
    printf '{ "found": true, "version": null, "path": "%s" }' "$(json_escape "$path")"
  else
    printf '{ "found": true, "version": "%s", "path": "%s" }' \
      "$(json_escape "$version")" "$(json_escape "$path")"
  fi
}

count_files() {
  find . \
    -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name .terraform -o -name venv -o -name __pycache__ \) -prune \
    -o -type f -name "$1" -print 2>/dev/null | wc -l | tr -d ' '
}

count_lines_in() {
  find . \
    -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name .terraform -o -name venv -o -name __pycache__ \) -prune \
    -o -type f -name "$1" -print 2>/dev/null \
    | xargs -I{} wc -l {} 2>/dev/null \
    | awk '{s+=$1} END {print s+0}'
}

# ============================================================
# 섹션 A: tools_inventory  (--tools-only 시 이것만 출력)
# ============================================================

TFSEC_JSON="$(detect_tool   tfsec   tfsec   --version)"
CHECKOV_JSON="$(detect_tool checkov checkov --version)"
TRIVY_JSON="$(detect_tool   trivy   trivy   --version)"
SEMGREP_JSON="$(detect_tool semgrep semgrep --version)"

AWS_JSON="$(detect_tool    aws    aws    --version)"
GCLOUD_JSON="$(detect_tool gcloud gcloud --version)"
AZ_JSON="$(detect_tool     az     az     --version)"

PROWLER_JSON="$(detect_tool    prowler    prowler    --version)"
STEAMPIPE_JSON="$(detect_tool  steampipe  steampipe  --version)"
SCOUTSUITE_JSON="$(detect_tool scoutsuite scoutsuite --version)"

KUBECTL_JSON="$(detect_tool    kubectl    kubectl    version --client --short)"
# kubectl --short 는 신버전에서 deprecated. fallback 으로 client 만 yaml head.
if [[ "$KUBECTL_JSON" == *'"version": null'* ]] && command -v kubectl >/dev/null 2>&1; then
  KUBECTL_JSON="$(detect_tool kubectl kubectl version --client)"
fi
KUBEBENCH_JSON="$(detect_tool kube-bench kube-bench version)"

TOOLS_INVENTORY_JSON="$(cat <<EOF
{
    "tier1": {
      "tfsec":   $TFSEC_JSON,
      "checkov": $CHECKOV_JSON,
      "trivy":   $TRIVY_JSON,
      "semgrep": $SEMGREP_JSON
    },
    "tier2_cli": {
      "aws":    $AWS_JSON,
      "gcloud": $GCLOUD_JSON,
      "az":     $AZ_JSON
    },
    "tier2_compliance": {
      "prowler":    $PROWLER_JSON,
      "steampipe":  $STEAMPIPE_JSON,
      "scoutsuite": $SCOUTSUITE_JSON
    },
    "tier3": {
      "kubectl":    $KUBECTL_JSON,
      "kube-bench": $KUBEBENCH_JSON
    }
  }
EOF
)"

# 도구 발견 여부 boolean 캐시 (coverage_estimate 에서 사용)
tool_found() {
  # 인자: 위에서 만든 JSON 변수 이름
  case "$1" in
    *'"found": true'*) echo true ;;
    *) echo false ;;
  esac
}
TFSEC_FOUND="$(tool_found "$TFSEC_JSON")"
CHECKOV_FOUND="$(tool_found "$CHECKOV_JSON")"
TRIVY_FOUND="$(tool_found "$TRIVY_JSON")"
SEMGREP_FOUND="$(tool_found "$SEMGREP_JSON")"
AWS_FOUND="$(tool_found "$AWS_JSON")"
KUBECTL_FOUND="$(tool_found "$KUBECTL_JSON")"

# --tools-only 모드: 빠른 출력 후 종료
if [[ "$TOOLS_ONLY" == "true" ]]; then
  cat <<EOF
{
  "scan_version": "0.3",
  "scanned_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "mode": "tools-only",
  "tools_inventory": $TOOLS_INVENTORY_JSON
}
EOF
  exit 0
fi

# ============================================================
# 섹션 B: cloud_creds  (값 절대 안 봄, 존재 여부만)
# ============================================================

# --- AWS ---
AWS_PROFILE_ENV="${AWS_PROFILE:-}"
AWS_CONFIG_EXISTS=false;      [[ -f "$HOME/.aws/config"      ]] && AWS_CONFIG_EXISTS=true
AWS_CREDS_EXISTS=false;       [[ -f "$HOME/.aws/credentials" ]] && AWS_CREDS_EXISTS=true
AWS_KEY_ENV_SET=false;        [[ -n "${AWS_ACCESS_KEY_ID:-}" ]] && AWS_KEY_ENV_SET=true
AWS_ACTIVE_PROFILE=""
if [[ "$AWS_FOUND" == "true" ]]; then
  # `aws configure list` 첫 출력의 profile 라인 — 이름만 추출
  if [[ -n "$HAS_TIMEOUT" ]]; then
    AWS_ACTIVE_PROFILE="$("$HAS_TIMEOUT" 5 aws configure list 2>/dev/null \
      | awk '/^[[:space:]]*profile/ {print $2}' | head -1 || true)"
  else
    AWS_ACTIVE_PROFILE="$(aws configure list 2>/dev/null \
      | awk '/^[[:space:]]*profile/ {print $2}' | head -1 || true)"
  fi
  # "<not" (부분: "<not set>") 같은 placeholder 는 빈값 처리
  case "$AWS_ACTIVE_PROFILE" in
    "<not"*) AWS_ACTIVE_PROFILE="" ;;
  esac
fi

# AWS 자격증명이 1개라도 감지되었나 (Tier 2 게이트 판정용)
AWS_CREDS_DETECTED=false
if [[ -n "$AWS_PROFILE_ENV" ]] || [[ "$AWS_CONFIG_EXISTS" == "true" ]] \
   || [[ "$AWS_CREDS_EXISTS" == "true" ]] || [[ "$AWS_KEY_ENV_SET" == "true" ]] \
   || [[ -n "$AWS_ACTIVE_PROFILE" ]]; then
  AWS_CREDS_DETECTED=true
fi

# --- AWS 사용 가능 profile 목록 추출 (v0.4.6.1) ---
# 이름만 봄 — 값은 절대 안 봄. ~/.aws/config + ~/.aws/credentials 합집합.
# config:  [default] / [profile xxx]
# creds:   [default] / [xxx]
# 두 리스트 합집합, 정렬, 중복 제거. timeout 5초 wrap.
AWS_AVAILABLE_PROFILES_RAW=""
if [[ "$AWS_CONFIG_EXISTS" == "true" ]]; then
  if [[ -n "$HAS_TIMEOUT" ]]; then
    CFG_PROFILES="$("$HAS_TIMEOUT" 5 awk '
      /^\[profile / {gsub(/[\[\]]/,""); print $2; next}
      /^\[default\][[:space:]]*$/ {print "default"; next}
    ' "$HOME/.aws/config" 2>/dev/null || true)"
  else
    CFG_PROFILES="$(awk '
      /^\[profile / {gsub(/[\[\]]/,""); print $2; next}
      /^\[default\][[:space:]]*$/ {print "default"; next}
    ' "$HOME/.aws/config" 2>/dev/null || true)"
  fi
  AWS_AVAILABLE_PROFILES_RAW="$CFG_PROFILES"
fi
if [[ "$AWS_CREDS_EXISTS" == "true" ]]; then
  if [[ -n "$HAS_TIMEOUT" ]]; then
    CRED_PROFILES="$("$HAS_TIMEOUT" 5 awk '
      /^\[[^]]+\][[:space:]]*$/ {gsub(/[\[\]]/,""); print}
    ' "$HOME/.aws/credentials" 2>/dev/null || true)"
  else
    CRED_PROFILES="$(awk '
      /^\[[^]]+\][[:space:]]*$/ {gsub(/[\[\]]/,""); print}
    ' "$HOME/.aws/credentials" 2>/dev/null || true)"
  fi
  AWS_AVAILABLE_PROFILES_RAW="$(printf '%s\n%s\n' "$AWS_AVAILABLE_PROFILES_RAW" "$CRED_PROFILES")"
fi
AWS_AVAILABLE_PROFILES="$(printf '%s\n' "$AWS_AVAILABLE_PROFILES_RAW" \
  | sed '/^[[:space:]]*$/d' \
  | sort -u \
  | head -50 || true)"

# JSON 배열로 직렬화 (이름만 — 값/credentials 내용 절대 안 봄)
AWS_AVAILABLE_PROFILES_JSON='['
_first_prof=true
while IFS= read -r profile; do
  [[ -z "$profile" ]] && continue
  if [[ "$_first_prof" == "true" ]]; then _first_prof=false; else AWS_AVAILABLE_PROFILES_JSON+=','; fi
  AWS_AVAILABLE_PROFILES_JSON+="\"$(json_escape "$profile")\""
done <<< "$AWS_AVAILABLE_PROFILES"
AWS_AVAILABLE_PROFILES_JSON+=']'

# JSON 직렬화
aws_str_or_null() {
  local v="$1"
  if [[ -z "$v" ]]; then printf 'null'
  else printf '"%s"' "$(json_escape "$v")"; fi
}

CLOUD_AWS_JSON="$(cat <<EOF
{
      "profile_env":             $(aws_str_or_null "$AWS_PROFILE_ENV"),
      "config_file_exists":      $AWS_CONFIG_EXISTS,
      "credentials_file_exists": $AWS_CREDS_EXISTS,
      "active_profile":          $(aws_str_or_null "$AWS_ACTIVE_PROFILE"),
      "key_env_set":             $AWS_KEY_ENV_SET,
      "available_profiles":      $AWS_AVAILABLE_PROFILES_JSON
    }
EOF
)"

# --- GCP ---
GCP_ACTIVE_ACCOUNT_PRESENT=false
GCP_ACTIVE_ACCOUNT=""
GCP_ACTIVE_PROJECT=""
GCP_CREDS_FILE_EXISTS=false
[[ -f "$HOME/.config/gcloud/credentials.db" ]] && GCP_CREDS_FILE_EXISTS=true
if command -v gcloud >/dev/null 2>&1; then
  if [[ -n "$HAS_TIMEOUT" ]]; then
    GCP_ACTIVE_ACCOUNT="$("$HAS_TIMEOUT" 5 gcloud config list account --format='value(core.account)' 2>/dev/null || true)"
  else
    GCP_ACTIVE_ACCOUNT="$(gcloud config list account --format='value(core.account)' 2>/dev/null || true)"
  fi
  [[ -n "$GCP_ACTIVE_ACCOUNT" ]] && GCP_ACTIVE_ACCOUNT_PRESENT=true
  if [[ -n "$HAS_TIMEOUT" ]]; then
    GCP_ACTIVE_PROJECT="$("$HAS_TIMEOUT" 5 gcloud config list project --format='value(core.project)' 2>/dev/null || true)"
  else
    GCP_ACTIVE_PROJECT="$(gcloud config list project --format='value(core.project)' 2>/dev/null || true)"
  fi
fi

# v0.6: 사용 가능한 GCP project 목록 (이름만 — 권한 토큰은 안 봄)
GCP_AVAILABLE_PROJECTS_JSON='[]'
if [[ "$GCP_ACTIVE_ACCOUNT_PRESENT" == "true" ]]; then
  if [[ -n "$HAS_TIMEOUT" ]]; then
    gcp_projs_raw="$("$HAS_TIMEOUT" 10 gcloud projects list --format='value(projectId)' 2>/dev/null | head -50 || true)"
  else
    gcp_projs_raw="$(gcloud projects list --format='value(projectId)' 2>/dev/null | head -50 || true)"
  fi
  if [[ -n "$gcp_projs_raw" ]]; then
    GCP_AVAILABLE_PROJECTS_JSON='['
    _first_proj=true
    while IFS= read -r proj; do
      [[ -z "$proj" ]] && continue
      if [[ "$_first_proj" == "true" ]]; then _first_proj=false; else GCP_AVAILABLE_PROJECTS_JSON+=','; fi
      GCP_AVAILABLE_PROJECTS_JSON+="\"$(json_escape "$proj")\""
    done <<< "$gcp_projs_raw"
    GCP_AVAILABLE_PROJECTS_JSON+=']'
  fi
fi

CLOUD_GCP_JSON="$(cat <<EOF
{
      "active_account_present":  $GCP_ACTIVE_ACCOUNT_PRESENT,
      "active_account":          $(aws_str_or_null "$GCP_ACTIVE_ACCOUNT"),
      "active_project":          $(aws_str_or_null "$GCP_ACTIVE_PROJECT"),
      "credentials_file_exists": $GCP_CREDS_FILE_EXISTS,
      "available_projects":      $GCP_AVAILABLE_PROJECTS_JSON
    }
EOF
)"

# --- Azure ---
AZURE_LOGGED_IN=false
AZURE_ACTIVE_USER=""
AZURE_ACTIVE_SUBSCRIPTION_ID=""
AZURE_ACTIVE_TENANT_ID=""
AZURE_AVAILABLE_SUBSCRIPTIONS_JSON='[]'
if command -v az >/dev/null 2>&1; then
  if [[ -n "$HAS_TIMEOUT" ]]; then
    AZURE_ACTIVE_USER="$("$HAS_TIMEOUT" 5 az account show --query 'user.name' -o tsv 2>/dev/null || true)"
  else
    AZURE_ACTIVE_USER="$(az account show --query 'user.name' -o tsv 2>/dev/null || true)"
  fi
  [[ -n "$AZURE_ACTIVE_USER" ]] && AZURE_LOGGED_IN=true
  if [[ "$AZURE_LOGGED_IN" == "true" ]]; then
    if [[ -n "$HAS_TIMEOUT" ]]; then
      AZURE_ACTIVE_SUBSCRIPTION_ID="$("$HAS_TIMEOUT" 5 az account show --query 'id' -o tsv 2>/dev/null || true)"
      AZURE_ACTIVE_TENANT_ID="$("$HAS_TIMEOUT" 5 az account show --query 'tenantId' -o tsv 2>/dev/null || true)"
      az_subs_raw="$("$HAS_TIMEOUT" 10 az account list --query "[].{id:id, name:name}" -o tsv 2>/dev/null | head -50 || true)"
    else
      AZURE_ACTIVE_SUBSCRIPTION_ID="$(az account show --query 'id' -o tsv 2>/dev/null || true)"
      AZURE_ACTIVE_TENANT_ID="$(az account show --query 'tenantId' -o tsv 2>/dev/null || true)"
      az_subs_raw="$(az account list --query "[].{id:id, name:name}" -o tsv 2>/dev/null | head -50 || true)"
    fi
    if [[ -n "$az_subs_raw" ]]; then
      AZURE_AVAILABLE_SUBSCRIPTIONS_JSON='['
      _first_sub=true
      while IFS=$'\t' read -r sub_id sub_name; do
        [[ -z "$sub_id" ]] && continue
        if [[ "$_first_sub" == "true" ]]; then _first_sub=false; else AZURE_AVAILABLE_SUBSCRIPTIONS_JSON+=','; fi
        AZURE_AVAILABLE_SUBSCRIPTIONS_JSON+="{\"id\":\"$(json_escape "$sub_id")\",\"name\":\"$(json_escape "$sub_name")\"}"
      done <<< "$az_subs_raw"
      AZURE_AVAILABLE_SUBSCRIPTIONS_JSON+=']'
    fi
  fi
fi
CLOUD_AZURE_JSON="$(cat <<EOF
{
      "logged_in":              $AZURE_LOGGED_IN,
      "active_user":            $(aws_str_or_null "$AZURE_ACTIVE_USER"),
      "active_subscription_id": $(aws_str_or_null "$AZURE_ACTIVE_SUBSCRIPTION_ID"),
      "active_tenant_id":       $(aws_str_or_null "$AZURE_ACTIVE_TENANT_ID"),
      "available_subscriptions": $AZURE_AVAILABLE_SUBSCRIPTIONS_JSON
    }
EOF
)"

# --- Kubernetes ---
KUBECONFIG_ENV="${KUBECONFIG:-}"
KUBE_DEFAULT_EXISTS=false
[[ -f "$HOME/.kube/config" ]] && KUBE_DEFAULT_EXISTS=true
KUBE_CURRENT_CONTEXT=""
if command -v kubectl >/dev/null 2>&1; then
  if [[ -n "$HAS_TIMEOUT" ]]; then
    KUBE_CURRENT_CONTEXT="$("$HAS_TIMEOUT" 5 kubectl config current-context 2>/dev/null || true)"
  else
    KUBE_CURRENT_CONTEXT="$(kubectl config current-context 2>/dev/null || true)"
  fi
fi
CLOUD_K8S_JSON="$(cat <<EOF
{
      "kubeconfig_env":            $(aws_str_or_null "$KUBECONFIG_ENV"),
      "default_kubeconfig_exists": $KUBE_DEFAULT_EXISTS,
      "current_context":           $(aws_str_or_null "$KUBE_CURRENT_CONTEXT")
    }
EOF
)"

CLOUD_CREDS_JSON="$(cat <<EOF
{
    "aws":        $CLOUD_AWS_JSON,
    "gcloud":     $CLOUD_GCP_JSON,
    "azure":      $CLOUD_AZURE_JSON,
    "kubernetes": $CLOUD_K8S_JSON
  }
EOF
)"

# ============================================================
# 섹션 C: coverage_estimate  (--no-coverage 시 생략)
# ============================================================

build_coverage_estimate() {
  # controls.json 못 찾으면 빈 객체 반환 (호출자가 처리)
  if [[ ! -f "$CONTROLS_JSON" ]]; then
    printf 'null'
    return
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    # python3 없으면 최소 정보만
    printf '{ "controls_total": null, "signals_total": null, "note": "python3 not available — coverage skipped" }'
    return
  fi

  # python3 로 controls.json 파싱 + Tier 분포 카운트
  python3 - <<PYEOF "$CONTROLS_JSON" "$TFSEC_FOUND" "$CHECKOV_FOUND" "$TRIVY_FOUND" "$SEMGREP_FOUND" "$AWS_FOUND" "$AWS_CREDS_DETECTED" "$KUBECTL_FOUND" "$KUBE_CURRENT_CONTEXT"
import json, sys

(_, path, tfsec, checkov, trivy, semgrep, aws_cli, aws_creds, kubectl, kube_ctx) = sys.argv

def b(s): return s == "true"
tfsec, checkov, trivy, semgrep = b(tfsec), b(checkov), b(trivy), b(semgrep)
aws_cli, aws_creds = b(aws_cli), b(aws_creds)
kubectl = b(kubectl)
kube_ctx_set = bool(kube_ctx.strip())

try:
    with open(path) as f:
        data = json.load(f)
except Exception as e:
    print(json.dumps({
        "controls_total": None,
        "signals_total":  None,
        "note": f"failed to load controls.json: {e}"
    }, indent=2))
    sys.exit(0)

controls = data.get("controls", [])
schema_version = str(data.get("schema_version", "0"))
controls_total = len(controls)
signals_total = 0
by_tier = {"0": 0, "1": 0, "2": 0, "3": 0}
schema_lt_0_3 = False

# v0.3 이상이면 access_tier 활용
try:
    parts = schema_version.split(".")
    sv_major = int(parts[0]) if parts and parts[0].isdigit() else 0
    sv_minor = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 0
    if (sv_major, sv_minor) < (0, 3):
        schema_lt_0_3 = True
except Exception:
    schema_lt_0_3 = True

for c in controls:
    for s in c.get("signals", []):
        signals_total += 1
        if not schema_lt_0_3:
            t = s.get("access_tier")
            if t in (0, 1, 2, 3):
                by_tier[str(t)] += 1

# Tier 가용성 판정
available = [0]  # Tier 0 항상
tier1_any = any([tfsec, checkov, trivy, semgrep])
if tier1_any:
    available.append(1)
if aws_cli and aws_creds:
    available.append(2)
if kubectl and kube_ctx_set:
    available.append(3)

# blockers
blockers = {}
if 1 not in available:
    blockers["1"] = ["tier1 정적 도구가 모두 미설치 (tfsec/checkov/trivy/semgrep)"]
else:
    blockers["1"] = []
if 2 not in available:
    reasons = []
    if not aws_cli:
        reasons.append("aws CLI 미설치")
    elif not aws_creds:
        reasons.append("aws CLI 설치되어 있으나 자격증명 미감지")
    blockers["2"] = reasons or ["unknown"]
else:
    blockers["2"] = []
if 3 not in available:
    reasons = []
    if not kubectl:
        reasons.append("kubectl 미설치")
    elif not kube_ctx_set:
        reasons.append("kubectl 설치되어 있으나 current-context 미설정")
    blockers["3"] = reasons or ["unknown"]
else:
    blockers["3"] = []

# 추정 커버리지 (KISA 102 통제 기준 — design 문서 §2 참조)
# 정적-only 27%, +Tier1 35%, +Tier2 60%, +Tier3 95%
result = {
    "controls_total": controls_total,
    "signals_total":  signals_total,
    "by_access_tier": {k: by_tier[k] for k in ("0","1","2","3")},
    "available_tiers": available,
    "tier_blockers": blockers,
    "estimated_coverage": {
        "static_only":  "27% (28/102)",
        "with_tools":   ("35% (현재 환경 기준)" if 1 in available else "27% (Tier 1 도구 미설치)"),
        "with_cloud":   ("60% (Tier 2 동의 시)" if 2 in available else "60% (Tier 2 진입 차단됨)"),
        "with_runtime": ("95% (Tier 3 동의 시)" if 3 in available else "95% (Tier 3 진입 차단됨)")
    }
}
if schema_lt_0_3:
    result["note"] = "controls.json schema_version < 0.3 — Tier 정보 미반영"

print(json.dumps(result, ensure_ascii=False, indent=2))
PYEOF
}

if [[ "$NO_COVERAGE" == "true" ]]; then
  COVERAGE_JSON="null"
else
  COVERAGE_JSON="$(build_coverage_estimate)"
  [[ -z "$COVERAGE_JSON" ]] && COVERAGE_JSON="null"
fi

# ============================================================
# 섹션 D: stacks_detected  (v0.4 신설 — Stack Profile 감지)
# ============================================================
#
# references/stacks/{official,community} 와 <project>/.isms-audit/stacks/
# 의 모든 *.json profile 을 순회하며 detection.any_of 룰을 평가한다.
# 매치된 것만 출력 (Tier U > C > S 우선, 같은 stack id 는 한 번만).

STACKS_OFFICIAL_DIR="$SCRIPT_DIR/../references/stacks/official"
STACKS_COMMUNITY_DIR="$SCRIPT_DIR/../references/stacks/community"
STACKS_USER_DIR="$ROOT/.isms-audit/stacks"

build_stacks_detected() {
  if ! command -v python3 >/dev/null 2>&1; then
    printf '[]'
    return
  fi

  python3 - <<'PYEOF' "$ROOT" "$STACKS_USER_DIR" "$STACKS_COMMUNITY_DIR" "$STACKS_OFFICIAL_DIR"
import json, os, re, sys, glob, fnmatch
from pathlib import Path

(_, root, user_dir, community_dir, official_dir) = sys.argv
root_p = Path(root)

def load_profiles(dirpath, tier):
    out = []
    if not dirpath or not os.path.isdir(dirpath):
        return out
    for name in sorted(os.listdir(dirpath)):
        if not name.endswith(".json"):
            continue
        fp = os.path.join(dirpath, name)
        try:
            data = json.load(open(fp))
        except Exception:
            continue
        out.append({"tier": tier, "path": fp, "data": data})
    return out

# Tier U > C > S 순서로 로드
profiles = []
profiles.extend(load_profiles(user_dir,      "U"))
profiles.extend(load_profiles(community_dir, "C"))
profiles.extend(load_profiles(official_dir,  "S"))

# 같은 stack id 는 가장 가까운 Tier 만
seen_ids = set()
unique = []
for p in profiles:
    sid = p["data"].get("stack", {}).get("id")
    if not sid or sid in seen_ids:
        continue
    seen_ids.add(sid)
    unique.append(p)

# 프로젝트 manifest 캐시 — 모노레포 지원: 워크스페이스 package.json 도 모두 스캔
package_jsons = []
def _load_pj(p):
    try:
        return json.load(open(p))
    except Exception:
        return None

# 루트 package.json
pj_root = root_p / "package.json"
if pj_root.is_file():
    pj = _load_pj(pj_root)
    if pj is not None:
        package_jsons.append(pj)

# 모노레포 워크스페이스 (apps/*, packages/*) — node_modules 제외, 깊이 3 이내
def _walk_pjs(base):
    found = []
    if not base.is_dir():
        return found
    for entry in sorted(base.iterdir()):
        if not entry.is_dir() or entry.name.startswith('.'):
            continue
        if entry.name in ("node_modules", ".next", "dist", "build", ".turbo"):
            continue
        sub = entry / "package.json"
        if sub.is_file():
            pj = _load_pj(sub)
            if pj is not None:
                found.append(pj)
    return found

for sub_dir in ("apps", "packages", "services", "libs"):
    package_jsons.extend(_walk_pjs(root_p / sub_dir))

package_json = package_jsons[0] if package_jsons else None  # version_capture 용 (루트 우선)

# 노이즈 디렉터리 (성능 + false positive 방지)
SKIP_DIR_PARTS = {"node_modules", ".git", ".next", "dist", "build",
                  ".terraform", "venv", "__pycache__", ".turbo", "cdk.out"}

def _is_in_skip_dir(rel_path):
    parts = Path(rel_path).parts
    return any(part in SKIP_DIR_PARTS for part in parts)

def glob_match(pattern):
    try:
        results = list(root_p.glob(pattern))
    except Exception:
        return []
    out = []
    for p in results:
        if not p.exists():
            continue
        try:
            rel = str(p.relative_to(root_p))
        except ValueError:
            continue
        if _is_in_skip_dir(rel):
            continue
        out.append(rel)
    return out

def package_dep_match(name, manifest_name):
    # manifest 가 'package.json' 인 경우만 지원 (v0.4 시드)
    if manifest_name not in (None, "package.json"):
        return False
    if not package_jsons:
        return False
    sections = ["dependencies", "devDependencies", "peerDependencies", "optionalDependencies"]
    for pj in package_jsons:
        keys = []
        for s in sections:
            d = pj.get(s) or {}
            keys.extend(d.keys())
        if name.endswith("/*"):
            prefix = name[:-1]
            if any(k.startswith(prefix) for k in keys):
                return True
        elif name in keys:
            return True
    return False

def grep_match(pattern, paths):
    # 간단한 grep — paths 중 각 glob 안에서 정규식 검색
    try:
        rx = re.compile(pattern)
    except re.error:
        return False
    if not paths:
        # paths 미지정 — 안전상 skip (전체 스캔은 너무 비쌈)
        return False
    for path_glob in paths:
        for fp in glob_match(path_glob):
            full = root_p / fp
            if not full.is_file():
                continue
            try:
                if rx.search(full.read_text(errors="ignore")):
                    return True
            except Exception:
                continue
    return False

def evaluate_detection(profile):
    matched = []
    det = profile["data"].get("detection", {})
    for rule in det.get("any_of", []):
        t = rule.get("type")
        if t == "file_exists":
            pat = rule.get("pattern", "")
            if glob_match(pat):
                matched.append(f"file_exists:{pat}")
        elif t == "package_dependency":
            n = rule.get("name", "")
            m = rule.get("manifest", "package.json")
            if package_dep_match(n, m):
                matched.append(f"package_dependency:{n}")
        elif t == "grep_pattern":
            pat = rule.get("pattern", "")
            paths = rule.get("paths") or []
            if grep_match(pat, paths):
                matched.append(f"grep_pattern:{pat[:40]}")
    return matched

def capture_version(profile):
    vc = profile["data"].get("detection", {}).get("version_capture")
    if not vc or not package_jsons:
        return None
    if vc.get("from") != "package.json":
        return None
    key_path = vc.get("key", "")
    # 모든 package.json 순회, 첫 매치 반환
    for pj in package_jsons:
        cur = pj
        ok = True
        for part in key_path.split("."):
            if isinstance(cur, dict) and part in cur:
                cur = cur[part]
            else:
                ok = False
                break
        if ok and isinstance(cur, str):
            return cur
    return None

results = []
for p in unique:
    matched = evaluate_detection(p)
    if matched:
        sid = p["data"].get("stack", {}).get("id")
        results.append({
            "id": sid,
            "tier": p["tier"],
            "profile_path": os.path.abspath(p["path"]),
            "detection_matched": matched,
            "version": capture_version(p)
        })

print(json.dumps(results, ensure_ascii=False, indent=2))
PYEOF
}

STACKS_DETECTED_JSON="$(build_stacks_detected)"
[[ -z "$STACKS_DETECTED_JSON" ]] && STACKS_DETECTED_JSON="[]"

# ============================================================
# 기존 섹션 (v0.2 호환): 언어/프레임워크/IaC/CI/컨테이너/DB/시크릿/통계
#
# repo_role 섹션 (E) 도 이 변수들에 의존하므로 출력 직전에 한 번에 계산.
# ============================================================

# ---- 1. 백엔드 언어/프레임워크 감지 ----
LANG_NODE="$(has_file package.json)"
if [[ "$LANG_NODE" == "false" ]]; then
  if find . -maxdepth 6 -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \) \
       -not -path '*/node_modules/*' -not -path '*/.git/*' \
       -not -path '*/dist/*' -not -path '*/build/*' \
       2>/dev/null | head -1 | grep -q .; then
    LANG_NODE="true"
  fi
fi
LANG_PYTHON="$(has_file requirements.txt)"
[[ "$LANG_PYTHON" == "false" ]] && LANG_PYTHON="$(has_file pyproject.toml)"
LANG_JAVA="$(has_file pom.xml)"
[[ "$LANG_JAVA" == "false" ]] && LANG_JAVA="$(has_file build.gradle)"
[[ "$LANG_JAVA" == "false" ]] && LANG_JAVA="$(has_file build.gradle.kts)"
LANG_GO="$(has_file go.mod)"
LANG_RUBY="$(has_file Gemfile)"
LANG_RUST="$(has_file Cargo.toml)"
LANG_DOTNET="$(find . -maxdepth 2 -name '*.csproj' -o -name '*.sln' 2>/dev/null | head -1 | grep -q . && echo true || echo false)"

FW_NESTJS=false
FW_EXPRESS=false
FW_NEXT=false
FW_DJANGO=false
FW_FLASK=false
FW_FASTAPI=false
FW_SPRING=false
FW_RAILS=false

if [[ "$LANG_NODE" == "true" ]] && [[ -f package.json ]]; then
  grep -q '"@nestjs/core"' package.json 2>/dev/null && FW_NESTJS=true || true
  grep -q '"express"' package.json 2>/dev/null && FW_EXPRESS=true || true
  grep -q '"next"' package.json 2>/dev/null && FW_NEXT=true || true
fi
if [[ "$LANG_PYTHON" == "true" ]]; then
  { grep -q -i 'django' requirements.txt 2>/dev/null || grep -q -i 'django' pyproject.toml 2>/dev/null; } && FW_DJANGO=true || true
  { grep -q -i 'flask' requirements.txt 2>/dev/null || grep -q -i 'flask' pyproject.toml 2>/dev/null; } && FW_FLASK=true || true
  { grep -q -i 'fastapi' requirements.txt 2>/dev/null || grep -q -i 'fastapi' pyproject.toml 2>/dev/null; } && FW_FASTAPI=true || true
fi
if [[ "$LANG_JAVA" == "true" ]]; then
  { grep -q 'spring-boot' pom.xml 2>/dev/null || grep -q 'spring-boot' build.gradle 2>/dev/null || grep -q 'spring-boot' build.gradle.kts 2>/dev/null; } && FW_SPRING=true || true
fi
if [[ "$LANG_RUBY" == "true" ]]; then
  grep -q -i 'rails' Gemfile 2>/dev/null && FW_RAILS=true || true
fi

# ---- 2. IaC 감지 ----
IAC_TERRAFORM_COUNT="$(count_files '*.tf')"
IAC_CFN_COUNT="$(find . -type d \( -name .git -o -name node_modules -o -name .terraform \) -prune -o -type f \( -name 'cloudformation*.yaml' -o -name 'cloudformation*.yml' -o -name 'cfn*.yaml' \) -print 2>/dev/null | wc -l | tr -d ' ')"
IAC_K8S_COUNT="$(find . -type d \( -name .git -o -name node_modules \) -prune -o -type f \( -name 'deployment.yaml' -o -name 'service.yaml' -o -name 'ingress.yaml' -o -name 'kustomization.yaml' \) -print 2>/dev/null | wc -l | tr -d ' ')"
IAC_HELM_COUNT="$(find . -type f -name 'Chart.yaml' 2>/dev/null | wc -l | tr -d ' ')"

# --- Pulumi 강화: Pulumi.yaml 존재 + stack 파일 (Pulumi.*.yaml) 카운트
IAC_PULUMI="$(has_file Pulumi.yaml)"
IAC_PULUMI_STACK_COUNT="$(find . -maxdepth 3 -type f -name 'Pulumi.*.yaml' 2>/dev/null | wc -l | tr -d ' ')"

# --- CDK 강화: cdk.json + lib/*-stack.{ts,js,py} 패턴
IAC_CDK="$(find . -maxdepth 3 -name 'cdk.json' 2>/dev/null | head -1 | grep -q . && echo true || echo false)"
IAC_CDK_STACK_COUNT="$(find . -maxdepth 5 -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name cdk.out \) -prune -o -type f \( -name '*-stack.ts' -o -name '*-stack.js' -o -name '*-stack.py' \) -print 2>/dev/null | wc -l | tr -d ' ')"

# --- SST 인식
HAS_SST_CONFIG=false
SST_CONFIG_FILE=""
if [[ -f sst.config.ts ]]; then
  HAS_SST_CONFIG=true; SST_CONFIG_FILE="sst.config.ts"
elif [[ -f sst.config.js ]]; then
  HAS_SST_CONFIG=true; SST_CONFIG_FILE="sst.config.js"
elif [[ -f sst.config.mjs ]]; then
  HAS_SST_CONFIG=true; SST_CONFIG_FILE="sst.config.mjs"
elif [[ -f sst.json ]]; then
  HAS_SST_CONFIG=true; SST_CONFIG_FILE="sst.json"
fi
HAS_SST_DEP=false
if [[ -f package.json ]]; then
  grep -qE '"(sst|@serverless-stack/[^"]+)"[[:space:]]*:' package.json 2>/dev/null && HAS_SST_DEP=true
fi
SST_PRESENT=false
if [[ "$HAS_SST_CONFIG" == "true" || "$HAS_SST_DEP" == "true" ]]; then
  SST_PRESENT=true
fi

# ---- 3. CI/CD 감지 ----
CI_GH_ACTIONS=$([[ -d .github/workflows ]] && echo "true" || echo "false")
CI_GH_ACTIONS_COUNT="0"
if [[ "$CI_GH_ACTIONS" == "true" ]]; then
  CI_GH_ACTIONS_COUNT="$(find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | wc -l | tr -d ' ')"
fi
CI_GITLAB="$(has_file .gitlab-ci.yml)"
CI_JENKINS="$(has_file Jenkinsfile)"
CI_CIRCLE="$(has_file .circleci/config.yml)"

# ---- 4. 컨테이너 ----
HAS_DOCKERFILE="$(find . -maxdepth 3 -iname 'Dockerfile*' 2>/dev/null | head -1 | grep -q . && echo true || echo false)"
HAS_DOCKER_COMPOSE=$([[ -f docker-compose.yml || -f docker-compose.yaml || -f compose.yaml ]] && echo "true" || echo "false")

# ---- 5. DB 마이그레이션 ----
DB_PRISMA=$([[ -d prisma ]] && echo "true" || echo "false")
DB_MIGRATIONS_DIR=$([[ -d migrations || -d db/migrate || -d src/migrations ]] && echo "true" || echo "false")

# --- Supabase 인식 (DB IaC 의 일종)
HAS_SUPABASE_DIR=false
[[ -d supabase/migrations ]] && HAS_SUPABASE_DIR=true
HAS_SUPABASE_CONFIG=false
[[ -f supabase/config.toml ]] && HAS_SUPABASE_CONFIG=true
SUPABASE_PRESENT=false
if [[ "$HAS_SUPABASE_DIR" == "true" || "$HAS_SUPABASE_CONFIG" == "true" ]]; then
  SUPABASE_PRESENT=true
fi
SUPABASE_MIGRATION_COUNT="0"
if [[ "$HAS_SUPABASE_DIR" == "true" ]]; then
  SUPABASE_MIGRATION_COUNT="$(find supabase/migrations -maxdepth 2 -type f -name '*.sql' 2>/dev/null | wc -l | tr -d ' ')"
fi

# ---- 6. 시크릿/환경 파일 ----
HAS_ENV_FILE=$([[ -f .env || -f .env.local || -f .env.production ]] && echo "true" || echo "false")
HAS_GITIGNORE_ENV="false"
if [[ -f .gitignore ]] && grep -q '^\.env' .gitignore 2>/dev/null; then
  HAS_GITIGNORE_ENV="true"
fi

# ---- 7. 라인 카운트 ----
LOC_TS="$(count_lines_in '*.ts')"
LOC_JS="$(count_lines_in '*.js')"
LOC_PY="$(count_lines_in '*.py')"
LOC_GO="$(count_lines_in '*.go')"
LOC_JAVA="$(count_lines_in '*.java')"
LOC_RB="$(count_lines_in '*.rb')"
LOC_TOTAL=$(( LOC_TS + LOC_JS + LOC_PY + LOC_GO + LOC_JAVA + LOC_RB ))

FILE_COUNT_TOTAL="$(find . \
  -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name .terraform -o -name venv -o -name __pycache__ \) -prune \
  -o -type f \( -name '*.ts' -o -name '*.js' -o -name '*.py' -o -name '*.go' -o -name '*.java' -o -name '*.rb' -o -name '*.tf' -o -name '*.yaml' -o -name '*.yml' \) -print 2>/dev/null \
  | wc -l | tr -d ' ')"

# ---- 8. 의존성 ----
DEPS_FILE=""
if [[ "$LANG_NODE" == "true" ]]; then DEPS_FILE="package.json"; fi
if [[ -z "$DEPS_FILE" && "$LANG_PYTHON" == "true" ]]; then
  [[ -f requirements.txt ]] && DEPS_FILE="requirements.txt" || DEPS_FILE="pyproject.toml"
fi
if [[ -z "$DEPS_FILE" && "$LANG_GO" == "true" ]]; then DEPS_FILE="go.mod"; fi
if [[ -z "$DEPS_FILE" && "$LANG_RUBY" == "true" ]]; then DEPS_FILE="Gemfile"; fi

# ============================================================
# 섹션 E: repo_role  (v0.5.0-A 신설)
#
# 레포 전체의 "역할" 을 frontend / backend / infra / mobile / fullstack
# / unknown 중 하나로 분류한다. 모노레포는 root 와 apps/*, services/*,
# libs/*, packages/* 의 manifest 들도 함께 검사한다.
#
# 자격증명 / 코드 내용은 보지 않음. 마커 파일 + manifest 의존성 키 이름만.
# ============================================================

# --- 워크스페이스 manifest 수집 ---
# node_modules 제외. apps/services/libs/packages 의 1~3 depth 까지.
WORKSPACE_PKG_JSONS="$(
  find apps services libs packages -maxdepth 3 -name package.json \
    -not -path '*/node_modules/*' -not -path '*/.next/*' \
    -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.turbo/*' \
    2>/dev/null
)"

# 마커 검사 (root package.json 우선, 없으면 워크스페이스 manifest 들)
_grep_pkg() {
  # $1: 정규식. root + 워크스페이스 모두 검사.
  local pat="$1"
  if [[ -f package.json ]] && grep -qE "$pat" package.json 2>/dev/null; then
    return 0
  fi
  if [[ -n "$WORKSPACE_PKG_JSONS" ]]; then
    # xargs 가 빈 입력에 hang 하지 않도록 stdin 통해 전달
    if printf '%s\n' "$WORKSPACE_PKG_JSONS" \
      | xargs grep -lE "$pat" 2>/dev/null \
      | head -1 | grep -q .; then
      return 0
    fi
  fi
  return 1
}

# 1. frontend 마커 (next / react / vue / nuxt / svelte / solid / astro)
HAS_FRONTEND=false
if [[ "$LANG_NODE" == "true" ]]; then
  if _grep_pkg '"(next|react|vue|nuxt|svelte|solid|astro)"[[:space:]]*:'; then
    HAS_FRONTEND=true
  fi
fi

# 2. backend 마커 (Node 진영)
HAS_BACKEND_NODE=false
if [[ "$LANG_NODE" == "true" ]]; then
  if _grep_pkg '"(@nestjs/core|express|fastify|koa|@hono/[^"]+|hapi)"[[:space:]]*:'; then
    HAS_BACKEND_NODE=true
  fi
fi

# 3. backend 마커 (Python/Java/Go/Ruby)
HAS_BACKEND_PY=false
if [[ "$LANG_PYTHON" == "true" ]]; then
  if grep -qE -i '(django|fastapi|flask|aiohttp|tornado)' requirements.txt pyproject.toml 2>/dev/null; then
    HAS_BACKEND_PY=true
  fi
fi
HAS_BACKEND_JAVA=false
if [[ "$LANG_JAVA" == "true" ]]; then
  if grep -qE '(spring-boot-starter|spring-webmvc|micronaut|quarkus)' build.gradle build.gradle.kts pom.xml 2>/dev/null; then
    HAS_BACKEND_JAVA=true
  fi
fi
HAS_BACKEND_GO="$LANG_GO"
HAS_BACKEND_RUBY="$LANG_RUBY"

# 3-bis. backend 마커 (서버리스 / Edge — v0.5.0-C 신설)
#
# 모던 fullstack 환경은 별도 backend 패키지 없이 다음 형태로 서버 코드를 보유한다:
#   - SST Lambda 함수 정의 (sst.aws.Function / Nextjs / Cron 등)
#   - Next.js app/api routes 또는 pages/api 라우트
#   - 'use server' directive 가 붙은 Server Action 파일
#   - Supabase Edge Functions (supabase/functions/)
#   - AWS Lambda 핸들러 (exports.handler / def lambda_handler 등)
#
# 위 마커가 1개라도 매치되면 backend 코드가 있는 것으로 본다 (HAS_BACKEND_SERVERLESS=true).
HAS_BACKEND_SERVERLESS=false
SERVERLESS_SIGNAL_SST=""
SERVERLESS_SIGNAL_NEXTAPI=""
SERVERLESS_SIGNAL_USESERVER=""
SERVERLESS_SIGNAL_SUPAEDGE=""
SERVERLESS_SIGNAL_LAMBDA=""

# 1) SST 리소스 정의 (Function / Api / ApiGatewayV2 / Cron / Queue / Worker /
#    Bus / Topic / Nextjs / Remix / Astro / SvelteKit / SolidStart 등)
if [[ "$HAS_SST_CONFIG" == "true" && -n "$SST_CONFIG_FILE" && -f "$SST_CONFIG_FILE" ]]; then
  if grep -qE 'new sst\.aws\.(Function|Api|ApiGatewayV2|Cron|Queue|Worker|Bus|Topic|Nextjs|Remix|Astro|SvelteKit|SolidStart)' \
      "$SST_CONFIG_FILE" 2>/dev/null; then
    HAS_BACKEND_SERVERLESS=true
    # 매치된 첫 라인 번호 (대표 위치)
    sst_line="$(grep -nE 'new sst\.aws\.(Function|Api|ApiGatewayV2|Cron|Queue|Worker|Bus|Topic|Nextjs|Remix|Astro|SvelteKit|SolidStart)' \
      "$SST_CONFIG_FILE" 2>/dev/null | head -1 | cut -d: -f1)"
    SERVERLESS_SIGNAL_SST="${SST_CONFIG_FILE}${sst_line:+:$sst_line}"
  fi
fi

# 2) Next.js app/api 또는 pages/api 라우트 디렉터리
# 2-a) 모노레포 — apps/<workspace>/{app,pages}/api 또는 src/{app,pages}/api
NEXTAPI_DIR=""
if [[ -d apps ]]; then
  NEXTAPI_DIR="$(find apps -maxdepth 5 -type d \
    \( -path "*/app/api" -o -path "*/pages/api" -o -path "*/src/app/api" -o -path "*/src/pages/api" \) \
    -not -path "*/node_modules/*" 2>/dev/null | head -1)"
fi
# 2-b) 단일 레포
if [[ -z "$NEXTAPI_DIR" ]]; then
  NEXTAPI_DIR="$(find . -maxdepth 4 -type d \
    \( -path "./app/api" -o -path "./pages/api" -o -path "./src/app/api" -o -path "./src/pages/api" \) \
    -not -path "*/node_modules/*" 2>/dev/null | head -1)"
  # 정규화: 선행 './' 제거
  NEXTAPI_DIR="${NEXTAPI_DIR#./}"
fi
if [[ -n "$NEXTAPI_DIR" ]]; then
  HAS_BACKEND_SERVERLESS=true
  SERVERLESS_SIGNAL_NEXTAPI="$NEXTAPI_DIR"
fi

# 3) Server Actions — 'use server' directive (파일 첫 줄)
# apps/ 와 src/ 우선, node_modules 제외, 깊이 6 이내.
USESERVER_FILE=""
for base in apps src; do
  [[ -d "$base" ]] || continue
  # find ... -prune 로 node_modules / .next / dist / build 빼고
  candidates="$(find "$base" -maxdepth 6 \
    \( -type d \( -name node_modules -o -name .next -o -name dist -o -name build -o -name .turbo \) -prune \) \
    -o -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -print 2>/dev/null \
    | head -200)"
  [[ -z "$candidates" ]] && continue
  # 첫 줄에 'use server' / "use server" 가 있는 파일 1개 검색
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    if head -1 "$f" 2>/dev/null | grep -qE "^['\"]use server['\"]"; then
      USESERVER_FILE="$f"
      break
    fi
  done <<< "$candidates"
  [[ -n "$USESERVER_FILE" ]] && break
done
if [[ -n "$USESERVER_FILE" ]]; then
  HAS_BACKEND_SERVERLESS=true
  # 경로 단축: 선행 './' 제거
  SERVERLESS_SIGNAL_USESERVER="${USESERVER_FILE#./}"
fi

# 4) Supabase Edge Functions
if [[ -d supabase/functions ]]; then
  HAS_BACKEND_SERVERLESS=true
  SERVERLESS_SIGNAL_SUPAEDGE="supabase/functions/"
fi

# 5) AWS Lambda 핸들러 패턴 (exports.handler / module.exports.handler / def lambda_handler)
# 깊이 5 이내, node_modules / .git / .next / dist / build / cdk.out 제외.
LAMBDA_FILE=""
lambda_candidates="$(find . -maxdepth 5 \
  \( -type d \( -name node_modules -o -name .git -o -name .next -o -name dist -o -name build -o -name cdk.out -o -name .turbo -o -name venv -o -name __pycache__ \) -prune \) \
  -o -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) -print 2>/dev/null \
  | head -100)"
if [[ -n "$lambda_candidates" ]]; then
  # xargs 가 빈 입력에 hang 하지 않도록 stdin 통해 전달
  LAMBDA_FILE="$(printf '%s\n' "$lambda_candidates" \
    | xargs grep -lE 'exports\.handler[[:space:]]*=|module\.exports\.handler[[:space:]]*=|def[[:space:]]+lambda_handler[[:space:]]*\(' 2>/dev/null \
    | head -1)"
fi
if [[ -n "$LAMBDA_FILE" ]]; then
  HAS_BACKEND_SERVERLESS=true
  SERVERLESS_SIGNAL_LAMBDA="${LAMBDA_FILE#./}"
fi

HAS_BACKEND=false
if [[ "$HAS_BACKEND_NODE" == "true" || "$HAS_BACKEND_PY" == "true" \
   || "$HAS_BACKEND_JAVA" == "true" || "$HAS_BACKEND_GO" == "true" \
   || "$HAS_BACKEND_RUBY" == "true" \
   || "$HAS_BACKEND_SERVERLESS" == "true" ]]; then
  HAS_BACKEND=true
fi

# 4. infra 마커
HAS_CDK_JSON="$(has_file cdk.json)"
HAS_PULUMI_YAML="$(has_file Pulumi.yaml)"
HAS_SERVERLESS_YML="$(has_file serverless.yml)"
# HAS_SST_CONFIG 는 위 IaC 섹션에서 이미 계산됨
INFRA_FILE_COUNT=$(( IAC_TERRAFORM_COUNT + IAC_CFN_COUNT + IAC_K8S_COUNT ))

HAS_INFRA=false
if [[ "$HAS_SST_CONFIG" == "true" || "$HAS_CDK_JSON" == "true" \
   || "$HAS_PULUMI_YAML" == "true" || "$HAS_SERVERLESS_YML" == "true" \
   || $INFRA_FILE_COUNT -gt 0 ]]; then
  HAS_INFRA=true
fi

# 5. mobile 마커
HAS_MOBILE=false
if [[ "$LANG_NODE" == "true" ]]; then
  if _grep_pkg '"(react-native|expo|@react-native-community/[^"]+|nativescript)"[[:space:]]*:'; then
    HAS_MOBILE=true
  fi
fi
# Flutter
if [[ -f pubspec.yaml ]]; then
  HAS_MOBILE=true
fi
# 네이티브 iOS / Android
if find ios android -maxdepth 2 \( -name 'Info.plist' -o -name 'build.gradle' \) 2>/dev/null \
     | head -1 | grep -q .; then
  HAS_MOBILE=true
fi

# 6. 최종 분류
REPO_ROLE="unknown"
CONFIDENCE="low"
NOTE=""

if [[ "$HAS_MOBILE" == "true" ]]; then
  REPO_ROLE="mobile"
  CONFIDENCE="high"
elif [[ "$HAS_FRONTEND" == "true" && "$HAS_BACKEND" == "true" ]]; then
  REPO_ROLE="fullstack"
  CONFIDENCE="high"
  NOTE="monorepo or fullstack repo — frontend + backend code 공존"
elif [[ "$HAS_FRONTEND" == "true" ]]; then
  REPO_ROLE="frontend"
  CONFIDENCE="high"
elif [[ "$HAS_BACKEND" == "true" ]]; then
  REPO_ROLE="backend"
  CONFIDENCE="high"
elif [[ "$HAS_INFRA" == "true" ]] && [[ "$LANG_NODE" == "false" && "$HAS_BACKEND_NODE" == "false" ]]; then
  REPO_ROLE="infra"
  CONFIDENCE="high"
elif [[ "$HAS_INFRA" == "true" ]]; then
  # IaC 위주 + 미약한 코드 마커 — fullstack 으로 분류하되 부분 평가 권장
  REPO_ROLE="fullstack"
  CONFIDENCE="medium"
  NOTE="IaC 위주 + 미약한 코드 — fullstack 으로 분류하되 부분 평가 권장"
fi

# --- detection_signals[] 빌드 ---
# 마커가 어디서 결정됐는지 한 줄 요약 (관측 가능한 사실만)
DETECTION_SIGNALS=()

# frontend signal
if [[ "$HAS_FRONTEND" == "true" ]]; then
  fe_src=""
  if [[ -f package.json ]] && grep -qE '"(next|react|vue|nuxt|svelte|solid|astro)"[[:space:]]*:' package.json 2>/dev/null; then
    fe_src="package.json"
  elif [[ -n "$WORKSPACE_PKG_JSONS" ]]; then
    fe_src="$(printf '%s\n' "$WORKSPACE_PKG_JSONS" \
      | xargs grep -lE '"(next|react|vue|nuxt|svelte|solid|astro)"[[:space:]]*:' 2>/dev/null \
      | head -1)"
  fi
  # 어떤 framework 가 매치됐는지 (next 우선)
  fe_fw="frontend"
  if [[ -n "$fe_src" ]]; then
    for fw in next react vue nuxt svelte solid astro; do
      if grep -qE "\"$fw\"[[:space:]]*:" "$fe_src" 2>/dev/null; then
        fe_fw="$fw"; break
      fi
    done
    DETECTION_SIGNALS+=("$fe_fw($fe_src)")
  else
    DETECTION_SIGNALS+=("$fe_fw(detected)")
  fi
else
  DETECTION_SIGNALS+=("frontend(no)")
fi

# backend signal (Node)
if [[ "$HAS_BACKEND_NODE" == "true" ]]; then
  be_src=""
  if [[ -f package.json ]] && grep -qE '"(@nestjs/core|express|fastify|koa|@hono/[^"]+|hapi)"[[:space:]]*:' package.json 2>/dev/null; then
    be_src="package.json"
  elif [[ -n "$WORKSPACE_PKG_JSONS" ]]; then
    be_src="$(printf '%s\n' "$WORKSPACE_PKG_JSONS" \
      | xargs grep -lE '"(@nestjs/core|express|fastify|koa|@hono/[^"]+|hapi)"[[:space:]]*:' 2>/dev/null \
      | head -1)"
  fi
  be_fw="backend"
  if [[ -n "$be_src" ]]; then
    if   grep -q '"@nestjs/core"' "$be_src" 2>/dev/null; then be_fw="nestjs"
    elif grep -q '"express"'      "$be_src" 2>/dev/null; then be_fw="express"
    elif grep -q '"fastify"'      "$be_src" 2>/dev/null; then be_fw="fastify"
    elif grep -q '"koa"'          "$be_src" 2>/dev/null; then be_fw="koa"
    elif grep -qE '"@hono/[^"]+"' "$be_src" 2>/dev/null; then be_fw="hono"
    elif grep -q '"hapi"'         "$be_src" 2>/dev/null; then be_fw="hapi"
    fi
    DETECTION_SIGNALS+=("$be_fw($be_src)")
  else
    DETECTION_SIGNALS+=("$be_fw(detected)")
  fi
elif [[ "$HAS_BACKEND_PY" == "true" ]]; then
  DETECTION_SIGNALS+=("python-backend(requirements.txt|pyproject.toml)")
elif [[ "$HAS_BACKEND_JAVA" == "true" ]]; then
  DETECTION_SIGNALS+=("java-backend(build.gradle|pom.xml)")
elif [[ "$HAS_BACKEND_GO" == "true" ]]; then
  DETECTION_SIGNALS+=("go(go.mod)")
elif [[ "$HAS_BACKEND_RUBY" == "true" ]]; then
  DETECTION_SIGNALS+=("ruby(Gemfile)")
elif [[ "$HAS_BACKEND_SERVERLESS" == "true" ]]; then
  # 별도 marker 미매치 → 서버리스 시그널이 backend 분류의 유일한 근거
  DETECTION_SIGNALS+=("backend-serverless(detected)")
else
  DETECTION_SIGNALS+=("backend(no)")
fi

# v0.5.0-C — 서버리스 backend 시그널 (info 라벨). 어디서 매치됐는지 별도 라인으로 노출.
if [[ -n "$SERVERLESS_SIGNAL_SST" ]]; then
  DETECTION_SIGNALS+=("serverless-sst-function($SERVERLESS_SIGNAL_SST)")
fi
if [[ -n "$SERVERLESS_SIGNAL_NEXTAPI" ]]; then
  DETECTION_SIGNALS+=("serverless-nextjs-api($SERVERLESS_SIGNAL_NEXTAPI)")
fi
if [[ -n "$SERVERLESS_SIGNAL_USESERVER" ]]; then
  DETECTION_SIGNALS+=("serverless-server-action($SERVERLESS_SIGNAL_USESERVER)")
fi
if [[ -n "$SERVERLESS_SIGNAL_SUPAEDGE" ]]; then
  DETECTION_SIGNALS+=("serverless-supabase-edge($SERVERLESS_SIGNAL_SUPAEDGE)")
fi
if [[ -n "$SERVERLESS_SIGNAL_LAMBDA" ]]; then
  DETECTION_SIGNALS+=("serverless-lambda-handler($SERVERLESS_SIGNAL_LAMBDA)")
fi

# supabase signal (정보용 — backend 분류엔 영향 없음. detection_signals 에만 노출)
if [[ "$SUPABASE_PRESENT" == "true" ]]; then
  DETECTION_SIGNALS+=("supabase(db)")
fi

# infra signal
if [[ "$HAS_SST_CONFIG" == "true" ]]; then
  DETECTION_SIGNALS+=("sst($SST_CONFIG_FILE)")
elif [[ "$HAS_CDK_JSON" == "true" ]]; then
  DETECTION_SIGNALS+=("cdk(cdk.json)")
elif [[ "$HAS_PULUMI_YAML" == "true" ]]; then
  DETECTION_SIGNALS+=("pulumi(Pulumi.yaml)")
elif [[ "$HAS_SERVERLESS_YML" == "true" ]]; then
  DETECTION_SIGNALS+=("serverless(serverless.yml)")
elif [[ $IAC_TERRAFORM_COUNT -gt 0 ]]; then
  DETECTION_SIGNALS+=("terraform(${IAC_TERRAFORM_COUNT} *.tf)")
elif [[ $IAC_CFN_COUNT -gt 0 ]]; then
  DETECTION_SIGNALS+=("cloudformation(${IAC_CFN_COUNT} files)")
elif [[ $IAC_K8S_COUNT -gt 0 ]]; then
  DETECTION_SIGNALS+=("kubernetes(${IAC_K8S_COUNT} manifests)")
else
  DETECTION_SIGNALS+=("infra(no)")
fi

# mobile signal (있을 때만 기록)
if [[ "$HAS_MOBILE" == "true" ]]; then
  if [[ -f pubspec.yaml ]]; then
    DETECTION_SIGNALS+=("flutter(pubspec.yaml)")
  elif find ios android -maxdepth 2 \( -name 'Info.plist' -o -name 'build.gradle' \) 2>/dev/null \
        | head -1 | grep -q .; then
    DETECTION_SIGNALS+=("native-mobile(ios|android)")
  else
    DETECTION_SIGNALS+=("react-native|expo(package.json)")
  fi
fi

# --- DETECTION_SIGNALS 배열 → JSON 배열 직렬화 ---
DETECTION_SIGNALS_JSON='['
_first_sig=true
for sig in "${DETECTION_SIGNALS[@]}"; do
  if [[ "$_first_sig" == "true" ]]; then _first_sig=false; else DETECTION_SIGNALS_JSON+=','; fi
  DETECTION_SIGNALS_JSON+="\"$(json_escape "$sig")\""
done
DETECTION_SIGNALS_JSON+=']'

# repo_role 전체 JSON
REPO_ROLE_JSON="$(cat <<EOF
{
    "primary":     "$(json_escape "$REPO_ROLE")",
    "detection_signals": $DETECTION_SIGNALS_JSON,
    "confidence":  "$(json_escape "$CONFIDENCE")",
    "candidates": {
      "frontend":  $HAS_FRONTEND,
      "backend":   $HAS_BACKEND,
      "infra":     $HAS_INFRA,
      "mobile":    $HAS_MOBILE
    },
    "note": $(aws_str_or_null "$NOTE")
  }
EOF
)"

# ============================================================
# JSON 출력 (기존 키 + 신규 3개 섹션 + repo_role)
# ============================================================
cat <<EOF
{
  "scan_version": "0.3",
  "scanned_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "root": "$(json_escape "$ROOT")",
  "project_name": "$(json_escape "$(basename "$ROOT")")",
  "languages": {
    "node": $LANG_NODE,
    "python": $LANG_PYTHON,
    "java": $LANG_JAVA,
    "go": $LANG_GO,
    "ruby": $LANG_RUBY,
    "rust": $LANG_RUST,
    "dotnet": $LANG_DOTNET
  },
  "frameworks": {
    "nestjs": $FW_NESTJS,
    "express": $FW_EXPRESS,
    "next": $FW_NEXT,
    "django": $FW_DJANGO,
    "flask": $FW_FLASK,
    "fastapi": $FW_FASTAPI,
    "spring": $FW_SPRING,
    "rails": $FW_RAILS
  },
  "iac": {
    "terraform_files": $IAC_TERRAFORM_COUNT,
    "cloudformation_files": $IAC_CFN_COUNT,
    "kubernetes_manifests": $IAC_K8S_COUNT,
    "helm_charts": $IAC_HELM_COUNT,
    "pulumi": $IAC_PULUMI,
    "pulumi_stack_count": $IAC_PULUMI_STACK_COUNT,
    "cdk": $IAC_CDK,
    "cdk_stack_count": $IAC_CDK_STACK_COUNT,
    "sst": {
      "present": $SST_PRESENT,
      "config_file": $(aws_str_or_null "$SST_CONFIG_FILE"),
      "dep_present": $HAS_SST_DEP
    }
  },
  "ci": {
    "github_actions": $CI_GH_ACTIONS,
    "github_actions_workflow_count": $CI_GH_ACTIONS_COUNT,
    "gitlab_ci": $CI_GITLAB,
    "jenkins": $CI_JENKINS,
    "circleci": $CI_CIRCLE
  },
  "container": {
    "dockerfile": $HAS_DOCKERFILE,
    "compose": $HAS_DOCKER_COMPOSE
  },
  "db": {
    "prisma": $DB_PRISMA,
    "migrations_dir": $DB_MIGRATIONS_DIR,
    "supabase": {
      "present": $SUPABASE_PRESENT,
      "config": $HAS_SUPABASE_CONFIG,
      "migration_count": $SUPABASE_MIGRATION_COUNT
    }
  },
  "secrets_hygiene": {
    "has_env_file": $HAS_ENV_FILE,
    "env_in_gitignore": $HAS_GITIGNORE_ENV
  },
  "stats": {
    "file_count": $FILE_COUNT_TOTAL,
    "loc_total": $LOC_TOTAL,
    "loc_breakdown": {
      "ts": $LOC_TS,
      "js": $LOC_JS,
      "py": $LOC_PY,
      "go": $LOC_GO,
      "java": $LOC_JAVA,
      "rb": $LOC_RB
    }
  },
  "deps_file": "$(json_escape "$DEPS_FILE")",
  "tools_inventory": $TOOLS_INVENTORY_JSON,
  "cloud_creds": $CLOUD_CREDS_JSON,
  "coverage_estimate": $COVERAGE_JSON,
  "stacks_detected": $STACKS_DETECTED_JSON,
  "repo_role": $REPO_ROLE_JSON
}
EOF
