"""isms-p-audit Skill 무결성 자동 검증 — v0.7-pre

GRC repo (tests/test_plugin_structure.py) 패턴을 차용한 정적 검증.
BLOCKING 16항 중 정적 검증 가능한 항목을 자동화 — 13회 dogfood 의 일부를 회귀 방지.

실행:
    cd skill-design/isms-p-audit
    python3 -m pytest tests/ -v

요구사항:
    pip install jsonschema pytest
"""
import json
import re
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator


# 프로젝트 루트 (skill-design/isms-p-audit)
ROOT = Path(__file__).parent.parent
REFS = ROOT / "references"
SKILL_MD = ROOT / "SKILL.md"
README_MD = ROOT / "README.md"
STACKS_OFFICIAL = REFS / "stacks" / "official"


# ============================================================
# 섹션 A — JSON Schema 자체 무결성
# ============================================================


def test_manifest_schema_is_valid_draft2020_12():
    """manifest.schema.json 자체가 valid Draft 2020-12 schema."""
    schema = json.loads((REFS / "manifest.schema.json").read_text())
    Draft202012Validator.check_schema(schema)


def test_controls_schema_is_valid_draft2020_12():
    """controls.schema.json 자체가 valid Draft 2020-12 schema."""
    schema = json.loads((REFS / "controls.schema.json").read_text())
    Draft202012Validator.check_schema(schema)


def test_capability_schema_is_valid_draft2020_12():
    """capability.schema.json 자체가 valid Draft 2020-12 schema."""
    schema = json.loads((REFS / "capability.schema.json").read_text())
    Draft202012Validator.check_schema(schema)


def test_stack_profile_schema_is_valid_draft2020_12():
    """stack-profile.schema.json 자체가 valid Draft 2020-12 schema."""
    schema = json.loads((REFS / "stack-profile.schema.json").read_text())
    Draft202012Validator.check_schema(schema)


# ============================================================
# 섹션 B — 데이터 ↔ Schema 검증
# ============================================================


def test_controls_json_validates():
    """controls.json 이 controls.schema.json 통과."""
    schema = json.loads((REFS / "controls.schema.json").read_text())
    data = json.loads((REFS / "controls.json").read_text())
    errs = list(Draft202012Validator(schema).iter_errors(data))
    assert not errs, f"controls.json validation 위반:\n" + "\n".join(
        f"  {e.json_path}: {e.message[:200]}" for e in errs[:5]
    )


def test_capabilities_json_validates():
    """capabilities.json 이 capability.schema.json 통과."""
    schema = json.loads((REFS / "capability.schema.json").read_text())
    data = json.loads((REFS / "capabilities.json").read_text())
    errs = list(Draft202012Validator(schema).iter_errors(data))
    assert not errs, f"capabilities.json validation 위반:\n" + "\n".join(
        f"  {e.json_path}: {e.message[:200]}" for e in errs[:5]
    )


@pytest.mark.parametrize("stack_file", sorted(STACKS_OFFICIAL.glob("*.json")))
def test_stack_profile_validates(stack_file: Path):
    """각 stacks/official/*.json 이 stack-profile.schema.json 통과."""
    schema = json.loads((REFS / "stack-profile.schema.json").read_text())
    data = json.loads(stack_file.read_text())
    errs = list(Draft202012Validator(schema).iter_errors(data))
    assert not errs, f"{stack_file.name} validation 위반:\n" + "\n".join(
        f"  {e.json_path}: {e.message[:200]}" for e in errs[:5]
    )


# ============================================================
# 섹션 C — 참조 무결성 (cross-file)
# ============================================================


def test_controls_required_capabilities_exist_in_capabilities_json():
    """controls.json 의 required_capabilities[].id 가 capabilities.json 에 모두 존재."""
    controls = json.loads((REFS / "controls.json").read_text())
    capabilities = json.loads((REFS / "capabilities.json").read_text())
    cap_ids = {c["id"] for c in capabilities["capabilities"]}

    missing = []
    for control in controls["controls"]:
        for req in control.get("required_capabilities", []):
            if req["id"] not in cap_ids:
                missing.append(f"  control {control['id']} → {req['id']}")
    assert not missing, "controls.json 의 required capability ID 가 capabilities.json 에 부재:\n" + "\n".join(missing)


def test_controls_required_aspects_exist_in_capabilities_json():
    """controls.json 의 required_aspects[] 가 해당 capability 의 verification_aspects[] 에 존재."""
    controls = json.loads((REFS / "controls.json").read_text())
    capabilities = json.loads((REFS / "capabilities.json").read_text())
    cap_aspects = {
        c["id"]: {a["id"] for a in c["verification_aspects"]}
        for c in capabilities["capabilities"]
    }

    missing = []
    for control in controls["controls"]:
        for req in control.get("required_capabilities", []):
            cap_id = req["id"]
            if cap_id not in cap_aspects:
                continue  # 위 테스트에서 잡힘
            for asp in req.get("required_aspects", []):
                if asp not in cap_aspects[cap_id]:
                    missing.append(f"  control {control['id']} → {cap_id}.{asp}")
    assert not missing, "controls.json 의 required_aspect 가 capabilities.json 에 부재:\n" + "\n".join(missing)


def test_capability_families_match_existing_signals():
    """capabilities.json 의 satisfied_by_signal_families[] 가 controls.json + stacks/*.json 의 시그널 family 와 일치."""
    capabilities = json.loads((REFS / "capabilities.json").read_text())
    controls = json.loads((REFS / "controls.json").read_text())

    # 모든 시그널 family 수집
    families = set()
    for c in controls["controls"]:
        for s in c.get("signals", []):
            if "family" in s:
                families.add(s["family"])
    for stack_file in STACKS_OFFICIAL.glob("*.json"):
        stack = json.loads(stack_file.read_text())
        for s in stack.get("signals", []):
            if "family" in s:
                families.add(s["family"])

    # capabilities.json 의 모든 referenced family
    orphaned = []
    for cap in capabilities["capabilities"]:
        for asp in cap["verification_aspects"]:
            for fam in asp.get("satisfied_by_signal_families", []):
                if fam not in families:
                    orphaned.append(f"  {cap['id']}.{asp['id']} → {fam}")
    assert not orphaned, (
        "capabilities.json 에 정의된 signal family 가 어디에도 정의되지 않음 (orphaned):\n"
        + "\n".join(orphaned[:10])
        + (f"\n  ... (+{len(orphaned)-10} more)" if len(orphaned) > 10 else "")
    )


# ============================================================
# 섹션 D — Phase 3 cross-cloud 매핑 일관성
# ============================================================


def test_phase3_mapping_families_match_controls_json():
    """phase3_cloud_mapping.json 의 family 가 controls.json 의 cloud_api 시그널 family 와 일치."""
    mapping_path = REFS / "phase3_cloud_mapping.json"
    if not mapping_path.exists():
        pytest.skip("phase3_cloud_mapping.json 부재 — Phase 3 리서치 미실행")

    mapping = json.loads(mapping_path.read_text())
    controls = json.loads((REFS / "controls.json").read_text())

    # cloud_api 시그널의 family 수집
    cloud_families = set()
    for c in controls["controls"]:
        for s in c.get("signals", []):
            if s.get("type") == "cloud_api" and "family" in s:
                cloud_families.add(s["family"])

    mismatched = []
    for m in mapping.get("phase_3_1_mapping", []):
        if m["family"] not in cloud_families:
            mismatched.append(m["family"])
    assert not mismatched, (
        "phase3_cloud_mapping.json 의 family 가 controls.json 의 cloud_api 시그널에 부재:\n  "
        + ", ".join(mismatched[:5])
    )


# ============================================================
# 섹션 E — SKILL.md BLOCKING 키워드 정적 검증
# ============================================================


BLOCKING_REQUIRED_TOKENS = [
    # v0.5.1.2 — delta_vs
    "delta_vs",
    # v0.6.1 — signals_evaluation_path
    "signals_evaluation_path",
    # v0.6.1 — prowler service-level 묶음 호출
    "service-level 묶음",
    # v0.6.2 — manifest schema 준수
    "manifest 구조 schema",
    # v0.6.3 — unknown ↔ skipped 양쪽 박제
    "양쪽 박제",
    # v0.6.4 — skill_version 정확 시맨틱
    "정확 시맨틱",
    # v0.6.5 — scan.ended_at 기반 prior 선택
    "scan.ended_at",
    # v0.7-pre.1 — cross_mappings 보고서 노출 BLOCKING
    "cross_mappings 보고서 노출",
]


@pytest.mark.parametrize("token", BLOCKING_REQUIRED_TOKENS)
def test_skill_md_contains_blocking_keyword(token: str):
    """SKILL.md 가 핵심 BLOCKING 키워드 보유 — 진화 흔적 회귀 방지."""
    content = SKILL_MD.read_text()
    assert token in content, f"SKILL.md 에 '{token}' 키워드 부재 — BLOCKING 항목 누락 가능성"


def test_skill_md_blocking_checklist_count():
    """SKILL.md §5.3 BLOCKING 체크리스트가 19항 이상 (v0.7-pre.1 기준)."""
    content = SKILL_MD.read_text()
    # §5.3 BLOCKING 체크리스트 영역 추출
    match = re.search(
        r"#### 5\.3 BLOCKING.*?위 (\d+)개 중 1개라도 누락",
        content,
        re.DOTALL,
    )
    assert match, "§5.3 BLOCKING 체크리스트 헤더/풋터 찾지 못함"
    declared_count = int(match.group(1))

    # 실제 체크리스트 항목 카운트
    block_section = match.group(0)
    actual_count = block_section.count("\n- [ ] **")
    assert declared_count == actual_count, (
        f"§5.3 헤더는 {declared_count}항 명시, 실제 항목 {actual_count}개 — 불일치"
    )
    assert declared_count >= 19, f"§5.3 BLOCKING 항목 {declared_count} < 19 (v0.7-pre.1 기준)"


def test_report_template_self_checks_present():
    """report-template.md 부록 C 의 self-check 명령 개수가 v0.6.4 표준 만족."""
    content = (REFS / "report-template.md").read_text()
    # `# N.` 패턴 카운트 (v0.4.6 의 #1-#6 + v0.5+ 의 #7+ 모두 포함)
    self_checks = re.findall(r"^#\s+\d+\.", content, re.MULTILINE)
    assert len(self_checks) >= 16, (
        f"report-template.md 부록 C self-check {len(self_checks)} < 16 (v0.6.4 기준 #1~#16)"
    )


# ============================================================
# 섹션 F — 스택 프로필 개수 검증 (Phase 3.3)
# ============================================================


def test_stack_profile_count():
    """stacks/official/ 에 20개 이상 stack profile 존재 (v0.7-pre 기준 — Phase 3.3 후)."""
    profiles = list(STACKS_OFFICIAL.glob("*.json"))
    assert len(profiles) >= 20, f"Stack profile {len(profiles)} < 20 (v0.7-pre 기준)"


def test_phase3_new_stacks_exist():
    """Phase 3.3 신설 4개 GCP/Azure stack profile 존재."""
    expected = ["gcp-cloud-run", "gcp-cloud-sql", "azure-app-service", "azure-functions"]
    missing = [s for s in expected if not (STACKS_OFFICIAL / f"{s}.json").exists()]
    assert not missing, f"Phase 3.3 stack profile 부재: {missing}"


# ============================================================
# 섹션 G — 통제 카운트 정합성
# ============================================================


def test_controls_count_56():
    """controls.json 의 통제가 정확히 56개 (ISMS-P 자동 점검 대상)."""
    controls = json.loads((REFS / "controls.json").read_text())
    assert len(controls["controls"]) == 56, (
        f"통제 개수 {len(controls['controls'])} ≠ 56 (KISA ISMS-P 2023.11 자동 점검 대상)"
    )


def test_capabilities_count_23():
    """capabilities.json 의 capability 가 정확히 23개."""
    capabilities = json.loads((REFS / "capabilities.json").read_text())
    assert len(capabilities["capabilities"]) == 23, (
        f"Capability 개수 {len(capabilities['capabilities'])} ≠ 23"
    )


def test_cloud_api_signal_count():
    """controls.json 의 cloud_api 시그널이 52개 이상 (v0.6 Phase 2 후)."""
    controls = json.loads((REFS / "controls.json").read_text())
    count = sum(
        1
        for c in controls["controls"]
        for s in c.get("signals", [])
        if s.get("type") == "cloud_api"
    )
    assert count >= 52, f"cloud_api 시그널 {count} < 52 (v0.6 Phase 2 기준)"


# ============================================================
# 섹션 H — README 메타 검증
# ============================================================
# 참고: README dogfood 표 / BLOCKING 갯수 표기는 v0.7.0 베타 공개 시
# README 정리 (간결화) 로 제거됨. 해당 메타는 CHANGELOG.md 에서 관리.


# ============================================================
# 섹션 I — Phase 5.2 Cross-framework mapping (v0.7-pre)
# ============================================================


def test_cross_framework_mapping_file_valid():
    """references/cross_framework_mapping.json 이 valid JSON + 56 매핑 보유."""
    mapping_path = REFS / "cross_framework_mapping.json"
    assert mapping_path.exists(), "cross_framework_mapping.json 부재 (Phase 5.2 미실행)"
    data = json.loads(mapping_path.read_text())
    assert "mappings" in data
    assert len(data["mappings"]) == 56, f"mappings {len(data['mappings'])} ≠ 56"
    assert data["summary"]["total_controls"] == 56


def test_all_controls_have_cross_mappings():
    """controls.json 의 모든 56 통제가 cross_mappings 필드 보유."""
    controls = json.loads((REFS / "controls.json").read_text())
    missing = [c["id"] for c in controls["controls"] if "cross_mappings" not in c]
    assert not missing, f"cross_mappings 누락 통제: {missing}"


def test_cross_mappings_consistent_with_master():
    """controls.json 의 cross_mappings 가 cross_framework_mapping.json 마스터와 일치."""
    controls = json.loads((REFS / "controls.json").read_text())
    master = json.loads((REFS / "cross_framework_mapping.json").read_text())
    master_by_id = {m["isms_p"]: m["cross"] for m in master["mappings"]}

    mismatch = []
    for c in controls["controls"]:
        if "cross_mappings" not in c:
            continue
        if c["id"] not in master_by_id:
            mismatch.append(f"  {c['id']}: 마스터에 부재")
            continue
        if c["cross_mappings"] != master_by_id[c["id"]]:
            mismatch.append(f"  {c['id']}: master vs controls.json 불일치")
    assert not mismatch, "cross_mappings 불일치:\n" + "\n".join(mismatch[:5])


def test_cross_mapping_framework_id_format():
    """ISO 27001 / NIST CSF / SOC 2 ID 가 올바른 형식인지 (regex)."""
    iso_pat = re.compile(r"^A\.\d+\.\d+$")  # A.5.16 / A.8.34
    csf_pat = re.compile(r"^(GV|ID|PR|DE|RS|RC)\.[A-Z]{2,3}-\d{2}$")  # GV.OC-01 / PR.AA-05
    soc_pat = re.compile(r"^(CC\d+\.\d+|A\d+\.\d+|P\d+\.\d+|C\d+\.\d+|PI\d+\.\d+)$")

    invalid = []
    controls = json.loads((REFS / "controls.json").read_text())
    for c in controls["controls"]:
        cm = c.get("cross_mappings", {})
        for fw_key, pat in [("iso_27001_2022", iso_pat), ("nist_csf_2_0", csf_pat), ("soc_2_tsc", soc_pat)]:
            for fw_id in cm.get(fw_key, {}).get("ids", []):
                if not pat.match(fw_id):
                    invalid.append(f"  {c['id']}.{fw_key}: '{fw_id}' (regex 불일치)")
    assert not invalid, "framework ID 형식 위반:\n" + "\n".join(invalid[:10])


# test_readme_blocking_count_consistency 제거 — v0.7.0 README 정리 시 BLOCKING 갯수
# 표기가 제거됨 (CHANGELOG 로 이전). SKILL.md §5.3 의 갯수는
# test_skill_md_blocking_checklist_count 가 검증.
