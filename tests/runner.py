#!/usr/bin/env python3
"""
Automated evaluation runner for evroc-skills.

Two modes:
  validate  — schema + cross-reference validation (no LLM, CI-safe)
  eval      — full LLM-based routing + instruction checks (needs API key)

Usage:
  python3 tests/runner.py validate
  python3 tests/runner.py eval
  python3 tests/runner.py eval --skill evroc-compute
  python3 tests/runner.py eval --backend openai --base-url https://models.think.evroc.com/v1
"""

import argparse
import json
import os
import re
import sys
import yaml
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

# ---------------------------------------------------------------------------
# Data models
# ---------------------------------------------------------------------------

@dataclass
class TestCase:
    file: str
    skill: str
    description: str
    id: str
    type: str  # trigger | negative-trigger | instruction
    query: str
    should_trigger: Optional[bool] = None
    correct_skill: Optional[str] = None
    rationale: Optional[str] = None
    expected_behavior: list[str] = field(default_factory=list)

@dataclass
class SkillInfo:
    name: str
    dir: str
    description: str
    version: str
    category: str

@dataclass
class ValidationResult:
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

# ---------------------------------------------------------------------------
# Skill loading
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "skills"
TESTS_DIR = REPO_ROOT / "tests"

def load_skills() -> dict[str, SkillInfo]:
    """Load all skills from skills/ directory."""
    skills = {}
    if not SKILLS_DIR.exists():
        return skills
    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue
        try:
            content = skill_md.read_text()
            # Extract frontmatter
            fm_match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
            if not fm_match:
                continue
            fm = yaml.safe_load(fm_match.group(1))
            name = fm.get("name", skill_dir.name)
            skills[name] = SkillInfo(
                name=name,
                dir=str(skill_dir),
                description=fm.get("description", ""),
                version=str(fm.get("metadata", {}).get("version", "unknown")),
                category=fm.get("metadata", {}).get("category", "unknown"),
            )
        except Exception as e:
            print(f"WARNING: Could not parse {skill_md}: {e}", file=sys.stderr)
    return skills

def load_test_cases() -> list[TestCase]:
    """Load all test cases from tests/*.json."""
    cases = []
    if not TESTS_DIR.exists():
        return cases
    for test_file in sorted(TESTS_DIR.glob("*.json")):
        try:
            data = json.loads(test_file.read_text())
            skill = data.get("skill", test_file.stem)
            description = data.get("description", "")
            for case in data.get("cases", []):
                cases.append(TestCase(
                    file=test_file.name,
                    skill=skill,
                    description=description,
                    id=case.get("id", ""),
                    type=case.get("type", ""),
                    query=case.get("query", ""),
                    should_trigger=case.get("should_trigger"),
                    correct_skill=case.get("correct_skill"),
                    rationale=case.get("rationale"),
                    expected_behavior=case.get("expected_behavior", []),
                ))
        except Exception as e:
            print(f"ERROR: Could not parse {test_file}: {e}", file=sys.stderr)
    return cases

# ---------------------------------------------------------------------------
# Validation mode (no LLM needed — CI-safe)
# ---------------------------------------------------------------------------

VALID_TYPES = {"trigger", "negative-trigger", "instruction"}

def validate(skills: dict[str, SkillInfo], cases: list[TestCase]) -> ValidationResult:
    result = ValidationResult()

    # Check skills exist
    if not skills:
        result.errors.append("No skills found in skills/ directory")
    for name, info in skills.items():
        if not info.description:
            result.errors.append(f"Skill '{name}' has empty description")
        # Check description truncation (57 char window)
        desc = info.description
        if len(desc) > 57 and not desc[:57].rstrip().endswith((".", ",", " ")):
            # Truncated mid-word — not ideal but not an error
            pass
        # Check for SKILL.md required sections
        skill_md = Path(info.dir) / "SKILL.md"
        content = skill_md.read_text()
        for section in ["## When to Use", "## Pitfalls"]:
            if section not in content:
                result.warnings.append(f"Skill '{name}' missing '{section}' section")

    # Check each test case
    skill_names = set(skills.keys())
    for case in cases:
        # Check skill referenced in test exists
        if case.skill not in skill_names:
            result.errors.append(
                f"[{case.file}] {case.id}: references skill '{case.skill}' "
                f"which does not exist in skills/"
            )

        # Check type is valid
        if case.type not in VALID_TYPES:
            result.errors.append(
                f"[{case.file}] {case.id}: invalid type '{case.type}', "
                f"must be one of {VALID_TYPES}"
            )

        # Check required fields per type
        if case.type in ("trigger", "negative-trigger"):
            if case.should_trigger is None:
                result.errors.append(
                    f"[{case.file}] {case.id}: type '{case.type}' requires 'should_trigger'"
                )
            if case.type == "negative-trigger" and not case.correct_skill:
                result.errors.append(
                    f"[{case.file}] {case.id}: negative-trigger requires 'correct_skill'"
                )
            if case.correct_skill and case.correct_skill not in skill_names:
                result.errors.append(
                    f"[{case.file}] {case.id}: correct_skill '{case.correct_skill}' "
                    f"does not exist in skills/"
                )

        if case.type == "instruction":
            if not case.expected_behavior:
                result.errors.append(
                    f"[{case.file}] {case.id}: instruction type requires 'expected_behavior'"
                )

        # Check query is non-empty
        if not case.query.strip():
            result.errors.append(f"[{case.file}] {case.id}: empty query")

    # Check for duplicate test IDs
    seen_ids = {}
    for case in cases:
        key = f"{case.skill}/{case.id}"
        if key in seen_ids:
            result.errors.append(f"Duplicate test ID: {key}")
        seen_ids[key] = True

    # Check eval coverage — every skill should have a test file
    test_skills = {c.skill for c in cases}
    for skill_name in skill_names:
        if skill_name not in test_skills:
            result.warnings.append(
                f"Skill '{skill_name}' has no test file in tests/"
            )

    return result

def run_validate() -> int:
    print("─" * 60)
    print("  evroc-skills validator")
    print("─" * 60)

    skills = load_skills()
    cases = load_test_cases()

    print(f"\n  Skills found: {len(skills)}")
    for name, info in sorted(skills.items()):
        print(f"    • {name} v{info.version} ({info.category})")

    print(f"\n  Test cases found: {len(cases)}")
    by_type = {}
    for c in cases:
        by_type[c.type] = by_type.get(c.type, 0) + 1
    for t, n in sorted(by_type.items()):
        print(f"    {t}: {n}")

    print(f"\n  Test files: {len(set(c.file for c in cases))}")

    result = validate(skills, cases)

    print("\n" + "─" * 60)
    if result.warnings:
        print(f"  ⚠  {len(result.warnings)} warning(s):")
        for w in result.warnings:
            print(f"    {w}")
        print()

    if result.errors:
        print(f"  ✗ {len(result.errors)} error(s):")
        for e in result.errors:
            print(f"    {e}")
        print("\n  FAILED")
        return 1
    else:
        print("  ✓ All validations passed")
        return 0

# ---------------------------------------------------------------------------
# Eval mode (LLM-based)
# ---------------------------------------------------------------------------

def _load_skill_content(skill_name: str) -> str:
    """Load full SKILL.md content for a skill."""
    skill_dir = SKILLS_DIR / skill_name
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return ""
    return skill_md.read_text()

def _build_routing_prompt(skills: dict[str, SkillInfo], query: str) -> str:
    """Build a prompt that asks the LLM which skill should handle the query."""
    skill_list = []
    for name, info in sorted(skills.items()):
        skill_list.append(f"  - {name}: {info.description}")

    return f"""You are a skill router for the evroc cloud platform. Given a user query,
select the single skill that should handle it, or "none" if no skill applies.

Available skills:
{chr(10).join(skill_list)}

User query: "{query}"

Respond with ONLY the skill name (one of: {', '.join(sorted(skills.keys()))}, none).
Do not include any explanation."""

def _build_instruction_prompt(skill_name: str, skill_content: str, query: str) -> str:
    """Build a prompt that asks the LLM to execute a query using a skill."""
    return f"""You are an AI assistant with access to the following skill:

{skill_content}

User request: "{query}"

Respond with the exact commands you would run to fulfill this request.
Include only the commands and brief reasoning between them. Do not
include any preamble or postamble."""

def _build_behavior_check_prompt(response: str, expected_behaviors: list[str]) -> str:
    """Build a prompt that asks the LLM to verify expected behaviors."""
    behaviors_text = "\n".join(f"  - {b}" for b in expected_behaviors)
    return f"""You are evaluating an AI assistant's response. Check whether the response
satisfies each of the following expected behaviors. For each behavior,
answer "PASS" or "FAIL" with a one-sentence reason.

Expected behaviors:
{behaviors_text}

Response to evaluate:
---
{response}
---

For each behavior, output a line in this exact format:
BEHAVIOR: <behavior text> | RESULT: PASS|FAIL | REASON: <one sentence>"""

def _call_llm(prompt: str, backend: str, base_url: str, model: str, api_key: Optional[str]) -> str:
    """Call an OpenAI-compatible LLM API."""
    import urllib.request, ssl

    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    url = f"{base_url}/chat/completions"
    body = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0,
        "max_tokens": 2000,
    }).encode()

    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    resp = urllib.request.urlopen(req, context=ctx)
    data = json.loads(resp.read().decode())
    return data["choices"][0]["message"]["content"].strip()

def run_eval(
    backend: str = "openai",
    base_url: str = "https://api.openai.com/v1",
    model: str = "gpt-4o-mini",
    api_key: Optional[str] = None,
    skill_filter: Optional[str] = None,
    types_filter: Optional[str] = None,
) -> int:
    print("─" * 60)
    print("  evroc-skills eval runner")
    print("─" * 60)

    skills = load_skills()
    cases = load_test_cases()

    if not skills:
        print("  ERROR: No skills found")
        return 1
    if not cases:
        print("  ERROR: No test cases found")
        return 1

    # Resolve API key
    if not api_key:
        api_key = os.environ.get("OPENAI_API_KEY") or os.environ.get("EVROC_THINK_API_KEY")
    if not api_key and backend != "dry-run":
        print("  ERROR: No API key. Set OPENAI_API_KEY or pass --api-key")
        return 1

    # Apply filters
    if skill_filter:
        cases = [c for c in cases if c.skill == skill_filter]
        if not cases:
            print(f"  ERROR: No test cases for skill '{skill_filter}'")
            return 1
    if types_filter:
        types = set(types_filter.split(","))
        cases = [c for c in cases if c.type in types]
        if not cases:
            print(f"  ERROR: No test cases matching types: {types_filter}")
            return 1

    print(f"\n  Backend: {backend}")
    print(f"  Model: {model}")
    print(f"  Base URL: {base_url}")
    print(f"  Skills: {len(skills)}")
    print(f"  Test cases: {len(cases)}")

    # Results tracking
    results = []
    passed = 0
    failed = 0

    for case in cases:
        print(f"\n{'─' * 40}")
        print(f"  [{case.type}] {case.skill}/{case.id}")
        print(f"  Query: {case.query[:80]}{'...' if len(case.query) > 80 else ''}")

        if case.type in ("trigger", "negative-trigger"):
            # Routing test — ask LLM which skill to trigger
            prompt = _build_routing_prompt(skills, case.query)
            if backend == "dry-run":
                predicted = "dry-run"
            else:
                predicted = _call_llm(prompt, backend, base_url, model, api_key)
                # Clean up response — take first line, strip punctuation
                predicted = predicted.strip().strip('.').strip().split('\n')[0].strip()

            expected_trigger = case.should_trigger
            expected_skill = case.skill if expected_trigger else (case.correct_skill or "none")

            if expected_trigger:
                # Should trigger THIS skill
                ok = predicted == case.skill
            else:
                # Should NOT trigger this skill — either triggers correct_skill or none
                ok = predicted == expected_skill or predicted == "none"

            status = "PASS" if ok else "FAIL"
            detail = f"expected={expected_skill}, got={predicted}"
            results.append((case, status, detail))
            print(f"  Result: {status} ({detail})")

        elif case.type == "instruction":
            # Instruction test — ask LLM to execute, then check behaviors
            skill_content = _load_skill_content(case.skill)
            prompt = _build_instruction_prompt(case.skill, skill_content, case.query)

            if backend == "dry-run":
                response = "dry-run mode — no LLM call"
                behavior_results = [("PASS", "dry-run") for _ in case.expected_behavior]
            else:
                response = _call_llm(prompt, backend, base_url, model, api_key)
                # Check each expected behavior
                check_prompt = _build_behavior_check_prompt(response, case.expected_behavior)
                check_response = _call_llm(check_prompt, backend, base_url, model, api_key)
                behavior_results = []
                for line in check_response.strip().split('\n'):
                    if 'BEHAVIOR:' in line and 'RESULT:' in line:
                        result_part = line.split('RESULT:')[1].split('|')[0].strip()
                        is_pass = "PASS" in result_part
                        reason = ""
                        if 'REASON:' in line:
                            reason = line.split('REASON:')[1].strip()
                        behavior_results.append(("PASS" if is_pass else "FAIL", reason))

            all_pass = all(r[0] == "PASS" for r in behavior_results)
            status = "PASS" if all_pass else "FAIL"
            detail = f"{sum(1 for r in behavior_results if r[0]=='PASS')}/{len(behavior_results)} behaviors passed"
            results.append((case, status, detail))
            print(f"  Result: {status} ({detail})")
            for i, (b, r) in enumerate(behavior_results):
                print(f"    {'✓' if b == 'PASS' else '✗'} {case.expected_behavior[i][:70]}")
                if r:
                    print(f"      {r[:100]}")

    # Summary
    print(f"\n{'═' * 60}")
    print(f"  SUMMARY")
    print(f"{'═' * 60}")
    print(f"  Total: {len(results)}")
    for r in results:
        if r[1] == "PASS":
            passed += 1
        else:
            failed += 1
    print(f"  Passed: {passed}")
    print(f"  Failed: {failed}")
    print(f"  Pass rate: {passed / len(results) * 100:.1f}%" if results else "  N/A")

    if failed:
        print(f"\n  Failed cases:")
        for case, status, detail in results:
            if status == "FAIL":
                print(f"    [{case.type}] {case.skill}/{case.id}: {detail}")

    return 1 if failed else 0

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="evroc-skills evaluation runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 tests/runner.py validate
  python3 tests/runner.py eval
  python3 tests/runner.py eval --skill evroc-compute
  python3 tests/runner.py eval --backend think --base-url https://models.think.evroc.com/v1 --model <model-id>
  python3 tests/runner.py eval --types trigger,negative-trigger
  python3 tests/runner.py eval --dry-run
        """,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # validate
    sub_validate = sub.add_parser("validate", help="Schema + cross-reference validation (no LLM)")

    # eval
    sub_eval = sub.add_parser("eval", help="Full LLM-based evaluation")
    sub_eval.add_argument("--backend", default="openai", choices=["openai", "think", "dry-run"],
                          help="LLM backend (default: openai)")
    sub_eval.add_argument("--base-url", default="https://api.openai.com/v1",
                          help="LLM API base URL")
    sub_eval.add_argument("--model", default="gpt-4o-mini",
                          help="Model ID")
    sub_eval.add_argument("--api-key", default=None,
                          help="API key (or set OPENAI_API_KEY / EVROC_THINK_API_KEY)")
    sub_eval.add_argument("--skill", default=None,
                          help="Run evals for a single skill only")
    sub_eval.add_argument("--types", default=None,
                          help="Comma-separated test types to run (trigger,negative-trigger,instruction)")
    sub_eval.add_argument("--dry-run", action="store_true",
                          help="Skip LLM calls, just show which tests would run")

    args = parser.parse_args()

    if args.command == "validate":
        return run_validate()
    elif args.command == "eval":
        backend = "dry-run" if args.dry_run else args.backend
        if args.backend == "think":
            args.base_url = "https://models.think.evroc.com/v1"
            if not args.api_key:
                args.api_key = os.environ.get("EVROC_THINK_API_KEY")
            if not args.model or args.model == "gpt-4o-mini":
                args.model = os.environ.get("EVROC_THINK_MODEL", "nvidia/Llama-3.3-70B-Instruct-FP8")
        return run_eval(
            backend=backend,
            base_url=args.base_url,
            model=args.model,
            api_key=args.api_key,
            skill_filter=args.skill,
            types_filter=args.types,
        )

if __name__ == "__main__":
    sys.exit(main())
