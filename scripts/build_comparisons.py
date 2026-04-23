#!/usr/bin/env python3
"""
Generate the comparison markdown files in comparisons/ from per-agent YAML
data in data/agents/.

Source of truth is data/agents/*.yml — do not hand-edit files in the output
directory.

Usage:
    python3 scripts/build_comparisons.py
    python3 scripts/build_comparisons.py --out comparisons/
"""

from __future__ import annotations

import argparse
import datetime as _dt
from pathlib import Path
from typing import Any

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data" / "agents"
DEFAULT_OUT = REPO_ROOT / "comparisons"

CATEGORY_ORDER = ["general-purpose", "coding", "frameworks"]
CATEGORY_TITLE = {
    "general-purpose": "Category A — General-Purpose Agents",
    "coding": "Category B — Coding Agents",
    "frameworks": "Category C — Agent Frameworks/Libraries",
}

GENERATED_BANNER = (
    "<!--\n"
    "  AUTO-GENERATED — do not edit by hand.\n"
    "  Source of truth: data/agents/*.yml\n"
    "  Regenerate with: python3 scripts/build_comparisons.py\n"
    "-->\n"
)


# ----------------------------------------------------------------------------
# Loading
# ----------------------------------------------------------------------------

def load_agents() -> list[dict[str, Any]]:
    agents: list[dict[str, Any]] = []
    for path in sorted(DATA_DIR.glob("*.yml")):
        with path.open() as f:
            data = yaml.safe_load(f)
        data["_source"] = path.name
        agents.append(data)
    return agents


def by_category(agents: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    grouped: dict[str, list[dict[str, Any]]] = {c: [] for c in CATEGORY_ORDER}
    for a in agents:
        grouped.setdefault(a["category"], []).append(a)
    for cat in grouped:
        grouped[cat].sort(key=lambda a: a["name"].lower())
    return grouped


# ----------------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------------

def fmt_loc(n: int | None) -> str:
    if n is None:
        return "—"
    if n >= 1000:
        return f"{n/1000:.1f}k".replace(".0k", "k")
    return str(n)


def fmt_list(items: list[str] | None, sep: str = ", ") -> str:
    if not items:
        return "—"
    return sep.join(items)


def cell(value: Any) -> str:
    if value is None:
        return "—"
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, list):
        return fmt_list([str(v) for v in value])
    s = str(value).strip().replace("\n", " ")
    # Collapse whitespace to keep cells single-line.
    return " ".join(s.split())


def review_link(agent: dict[str, Any]) -> str:
    path = agent.get("review", "")
    name = agent["name"]
    if path:
        return f"[{name}](../{path})"
    return name


# ----------------------------------------------------------------------------
# Renderers
# ----------------------------------------------------------------------------

def render_tier1_identity_cards(agents: list[dict[str, Any]]) -> str:
    out: list[str] = []
    out.append("# Tier 1 — Agent Identity Cards")
    out.append("")
    out.append(GENERATED_BANNER)
    out.append(f"**Generated:** {_dt.date.today().isoformat()}")
    out.append("**Methodology:** See [../METHODOLOGY.md](../METHODOLOGY.md)")
    out.append("")

    grouped = by_category(agents)
    for cat in CATEGORY_ORDER:
        if not grouped.get(cat):
            continue
        out.append("---")
        out.append("")
        out.append(f"## {CATEGORY_TITLE[cat]}")
        out.append("")
        for a in grouped[cat]:
            ident = a.get("identity", {})
            deps = ident.get("dependencies", {}) or {}
            out.append(f"### {a['name']}")
            out.append("")
            out.append("| Field | Value |")
            out.append("|-------|-------|")
            out.append(f"| **Repo** | {cell(ident.get('repo'))} |")
            out.append(f"| **Commit reviewed** | {cell(ident.get('commit'))} |")
            out.append(f"| **Date of commit** | {cell(ident.get('commit_date'))} |")
            out.append(f"| **Language(s)** | {cell(ident.get('language'))} |")
            out.append(f"| **License** | {cell(ident.get('license'))} |")
            out.append(f"| **LOC** | {fmt_loc(ident.get('loc'))} |")
            out.append(f"| **Files** | {cell(ident.get('files'))} |")
            dep_str = cell(deps.get("direct"))
            if deps.get("notes"):
                dep_str = f"{dep_str} ({deps['notes']})"
            out.append(f"| **Dependencies** | {dep_str} |")
            out.append(f"| **Commits** | {cell(ident.get('commits'))} |")
            out.append(f"| **Contributors** | {cell(ident.get('contributors'))} |")
            out.append("")
            if ident.get("stated_purpose"):
                out.append(f"**Stated purpose:** {cell(ident['stated_purpose'])}")
                out.append("")
            if ident.get("notable_features"):
                feats = "; ".join(ident["notable_features"])
                out.append(f"**Notable features:** {feats}")
                out.append("")

    return "\n".join(out).rstrip() + "\n"


def render_tier1_overview(agents: list[dict[str, Any]]) -> str:
    out: list[str] = []
    out.append("# Tier 1 — Comparison Tables")
    out.append("")
    out.append(GENERATED_BANNER)
    out.append(f"**Generated:** {_dt.date.today().isoformat()}")
    out.append("**Source data:** [data/agents/](../data/agents/)")
    out.append("")
    out.append("---")
    out.append("")

    # Overview
    out.append("## Overview")
    out.append("")
    out.append("| Agent | Category | Language | License | Purpose |")
    out.append("|-------|----------|----------|---------|---------|")
    for a in agents:
        ident = a.get("identity", {})
        out.append(
            f"| {review_link(a)} | {category_short(a['category'])} | "
            f"{cell(ident.get('language'))} | {cell(ident.get('license'))} | "
            f"{cell(ident.get('stated_purpose'))} |"
        )
    out.append("")
    out.append("---")
    out.append("")

    # Scale & community
    out.append("## Scale & Community")
    out.append("")
    out.append("| Agent | LOC | Files | Direct Deps | Commits | Contributors |")
    out.append("|-------|-----|-------|-------------|---------|--------------|")
    for a in agents:
        ident = a.get("identity", {})
        deps = ident.get("dependencies", {}) or {}
        out.append(
            f"| {a['name']} | {fmt_loc(ident.get('loc'))} | "
            f"{cell(ident.get('files'))} | {cell(deps.get('direct'))} | "
            f"{cell(ident.get('commits'))} | {cell(ident.get('contributors'))} |"
        )
    out.append("")
    out.append("---")
    out.append("")

    # Design philosophy (editorial cross-cut)
    out.append("## Design Philosophy")
    out.append("")
    out.append("| Agent | Approach | Tradeoff |")
    out.append("|-------|----------|----------|")
    for a in agents:
        dp = a.get("design_philosophy") or {}
        if not dp:
            continue
        out.append(f"| {a['name']} | {cell(dp.get('approach'))} | {cell(dp.get('tradeoff'))} |")
    out.append("")
    out.append("---")
    out.append("")

    # Capabilities summary (cross-cut of tier2 data)
    out.append("## Capabilities Summary")
    out.append("")
    out.append("| Agent | Providers | MCP | Default Sandbox | Sub-agents | Vendor Lock-in |")
    out.append("|-------|-----------|-----|-----------------|------------|----------------|")
    for a in agents:
        cap = a.get("capabilities") or {}
        llm = cap.get("llm_integration") or {}
        tool = cap.get("tool_calling") or {}
        sec = cap.get("security") or {}
        orc = cap.get("orchestration") or {}
        op = a.get("opinions") or {}
        out.append(
            f"| {a['name']} | {cell(llm.get('providers'))} | "
            f"{cell(tool.get('mcp_support'))} | "
            f"{cell(sec.get('default_bash_sandbox'))} | "
            f"{cell(orc.get('sub_agents'))} | "
            f"{cell(op.get('vendor_lock_in'))} |"
        )
    out.append("")

    return "\n".join(out).rstrip() + "\n"


def render_tier2_capabilities(agents: list[dict[str, Any]]) -> str:
    out: list[str] = []
    out.append("# Tier 2 — Capability Comparison Tables")
    out.append("")
    out.append(GENERATED_BANNER)
    out.append(f"**Generated:** {_dt.date.today().isoformat()}")
    out.append("**Source data:** [data/agents/](../data/agents/)")
    out.append("")
    out.append("---")
    out.append("")

    sections: list[tuple[str, callable]] = [
        ("Architecture", _row_architecture),
        ("LLM Integration", _row_llm),
        ("Tool/Function Calling", _row_tools),
        ("Memory & State", _row_memory),
        ("Orchestration", _row_orchestration),
        ("I/O Interfaces", _row_io),
        ("Testing", _row_testing),
        ("Security", _row_security),
        ("Repo Trust Surfaces", _row_trust),
        ("Deployment", _row_deployment),
        ("Documentation", _row_docs),
    ]

    for title, row_fn in sections:
        out.append(f"## {title}")
        out.append("")
        header, rows = _collect_rows(agents, row_fn)
        if not rows:
            out.append("_No data yet._")
            out.append("")
            continue
        out.append(header)
        out.append("|" + "---|" * (header.count("|") - 1))
        out.extend(rows)
        out.append("")

    return "\n".join(out).rstrip() + "\n"


def render_tier3_opinions(agents: list[dict[str, Any]]) -> str:
    out: list[str] = []
    out.append("# Tier 3 — Opinion Comparison Tables")
    out.append("")
    out.append(GENERATED_BANNER)
    out.append(f"**Generated:** {_dt.date.today().isoformat()}")
    out.append("**Source data:** [data/agents/](../data/agents/)")
    out.append("")
    out.append(
        "**Note:** These are subjective assessments backed by evidence from the "
        "source code. See individual reviews for detailed justifications."
    )
    out.append("")
    out.append("---")
    out.append("")

    # Ratings at a glance
    out.append("## Ratings at a Glance")
    out.append("")
    out.append("| Agent | Code Quality | Maturity | Maintainability | Vendor Lock-in |")
    out.append("|-------|-------------|----------|-----------------|----------------|")
    for a in agents:
        op = a.get("opinions", {}) or {}
        ratings = op.get("ratings", {}) or {}
        out.append(
            f"| {review_link(a)} | "
            f"{cell(ratings.get('code_quality'))}/5 | "
            f"{cell(op.get('maturity'))} | "
            f"{cell(ratings.get('maintainability'))}/5 | "
            f"{cell(op.get('vendor_lock_in'))} |"
        )
    out.append("")

    # Innovation highlights
    out.append("## Innovation Highlights")
    out.append("")
    out.append("| Agent | Highlights |")
    out.append("|-------|------------|")
    for a in agents:
        hl = ((a.get("opinions") or {}).get("innovation") or {}).get("highlights") or []
        if not hl:
            continue
        out.append(f"| {a['name']} | {'; '.join(hl)} |")
    out.append("")

    # Red flags
    out.append("## Red Flags")
    out.append("")
    out.append("| Agent | Flags |")
    out.append("|-------|-------|")
    for a in agents:
        flags = (a.get("opinions") or {}).get("red_flags") or []
        if not flags:
            continue
        out.append(f"| {a['name']} | {'; '.join(flags)} |")
    out.append("")

    # Maturity spectrum — grouped
    out.append("## Maturity Spectrum")
    out.append("")
    out.append("| Agent | Maturity |")
    out.append("|-------|----------|")
    maturity_order = ["prototype", "alpha", "beta", "production", "maintenance", "dormant"]
    def mat_key(a):
        m = (a.get("opinions") or {}).get("maturity") or "zzz"
        return (maturity_order.index(m) if m in maturity_order else len(maturity_order), a["name"].lower())
    for a in sorted(agents, key=mat_key):
        m = (a.get("opinions") or {}).get("maturity")
        out.append(f"| {a['name']} | {cell(m)} |")
    out.append("")

    # Practical utility
    out.append("## Practical Utility — Who Should Use What?")
    out.append("")
    out.append("| Agent | Rating | Target User |")
    out.append("|-------|--------|-------------|")
    for a in agents:
        pu = ((a.get("opinions") or {}).get("practical_utility") or {})
        if not pu:
            continue
        out.append(f"| {a['name']} | {cell(pu.get('rating'))} | {cell(pu.get('target_user'))} |")
    out.append("")

    # Overall summaries
    out.append("## Overall Summaries")
    out.append("")
    for a in agents:
        summary = (a.get("opinions") or {}).get("summary")
        if not summary:
            continue
        out.append(f"### {a['name']}")
        out.append("")
        out.append(cell(summary))
        out.append("")

    return "\n".join(out).rstrip() + "\n"


# ----------------------------------------------------------------------------
# Row extractors for tier 2 dimension tables
# ----------------------------------------------------------------------------

def _collect_rows(agents, row_fn):
    """Call row_fn(agent); return (header_line, [row_lines]). First successful
    call defines the header."""
    header: str | None = None
    rows: list[str] = []
    for a in agents:
        result = row_fn(a)
        if result is None:
            continue
        this_header, row = result
        if header is None:
            header = this_header
        rows.append(row)
    return header or "| Agent | Summary |", rows


def _cap(a: dict) -> dict:
    return a.get("capabilities") or {}


def _row_architecture(a):
    c = _cap(a).get("architecture") or {}
    if not c:
        return None
    header = "| Agent | Pattern | Summary |"
    row = f"| {a['name']} | {cell(c.get('pattern'))} | {cell(c.get('summary'))} |"
    return header, row


def _row_llm(a):
    c = _cap(a).get("llm_integration") or {}
    if not c:
        return None
    header = "| Agent | Providers | Gateway | Auth |"
    row = (
        f"| {a['name']} | {cell(c.get('providers'))} | "
        f"{cell(c.get('gateway'))} | {cell(c.get('auth'))} |"
    )
    return header, row


def _row_tools(a):
    c = _cap(a).get("tool_calling") or {}
    if not c:
        return None
    header = "| Agent | Pattern | MCP | Built-in Tools |"
    mcp = cell(c.get("mcp_support"))
    if c.get("mcp_stance"):
        mcp = f"{mcp} ({c['mcp_stance']})"
    tools = c.get("builtin_tools") or []
    tools_str = fmt_list(tools[:6]) + (", ..." if len(tools) > 6 else "")
    row = f"| {a['name']} | {cell(c.get('pattern'))} | {mcp} | {tools_str} |"
    return header, row


def _row_memory(a):
    c = _cap(a).get("memory") or {}
    if not c:
        return None
    header = "| Agent | Session Persistence | Compaction | Branching | Vector Store | Notes |"
    row = (
        f"| {a['name']} | {cell(c.get('session_persistence'))} | "
        f"{cell(c.get('compaction'))} | {cell(c.get('branching'))} | "
        f"{cell(c.get('vector_store'))} | {cell(c.get('notes'))} |"
    )
    return header, row


def _row_orchestration(a):
    c = _cap(a).get("orchestration") or {}
    if not c:
        return None
    header = "| Agent | Pattern | Sub-agents | Plan mode | Notes |"
    row = (
        f"| {a['name']} | {cell(c.get('pattern'))} | "
        f"{cell(c.get('sub_agents'))} | {cell(c.get('plan_mode'))} | "
        f"{cell(c.get('notes'))} |"
    )
    return header, row


def _row_io(a):
    c = _cap(a).get("io")
    if not c:
        return None
    header = "| Agent | Interfaces |"
    row = f"| {a['name']} | {cell(c)} |"
    return header, row


def _row_testing(a):
    c = _cap(a).get("testing") or {}
    if not c:
        return None
    header = "| Agent | Framework | Files | Faux Provider | Coverage Signal |"
    row = (
        f"| {a['name']} | {cell(c.get('framework'))} | "
        f"{cell(c.get('file_count'))} | {cell(c.get('faux_provider'))} | "
        f"{cell(c.get('coverage_signal'))} |"
    )
    return header, row


def _row_security(a):
    c = _cap(a).get("security") or {}
    if not c:
        return None
    header = "| Agent | Default Bash Sandbox | Approval Gate | Credential Storage | Notes |"
    row = (
        f"| {a['name']} | {cell(c.get('default_bash_sandbox'))} | "
        f"{cell(c.get('approval_gate'))} | {cell(c.get('credential_storage'))} | "
        f"{cell(c.get('notes'))} |"
    )
    return header, row


def _row_trust(a):
    c = _cap(a).get("repo_trust_surfaces") or {}
    if not c:
        return None
    header = (
        "| Agent | Risk Level | Agent Config Dirs | Auto-loaded Instructions | "
        "Lifecycle Scripts | Install-time Exec |"
    )
    row = (
        f"| {a['name']} | {cell(c.get('risk_level'))} | "
        f"{cell(c.get('agent_config_dirs'))} | "
        f"{cell(c.get('auto_loaded_instructions'))} | "
        f"{cell(c.get('lifecycle_scripts'))} | "
        f"{cell(c.get('install_time_exec'))} |"
    )
    return header, row


def _row_deployment(a):
    c = _cap(a).get("deployment") or {}
    if not c:
        return None
    header = "| Agent | Install | Binary | Docker | Platforms |"
    row = (
        f"| {a['name']} | {cell(c.get('install'))} | "
        f"{cell(c.get('binary'))} | {cell(c.get('docker'))} | "
        f"{cell(c.get('platforms'))} |"
    )
    return header, row


def _row_docs(a):
    c = _cap(a).get("docs")
    if not c:
        return None
    header = "| Agent | Documentation |"
    row = f"| {a['name']} | {cell(c)} |"
    return header, row


# ----------------------------------------------------------------------------
# Misc
# ----------------------------------------------------------------------------

def category_short(c: str) -> str:
    return {"general-purpose": "General", "coding": "Coding", "frameworks": "Framework"}.get(c, c)


# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_OUT,
        help=f"Output directory (default: {DEFAULT_OUT.relative_to(REPO_ROOT)})",
    )
    args = parser.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)

    agents = load_agents()
    if not agents:
        print(f"No agents found in {DATA_DIR}")
        return 1
    print(f"Loaded {len(agents)} agent(s): {', '.join(a['name'] for a in agents)}")

    outputs = {
        "tier1-identity-cards.md": render_tier1_identity_cards(agents),
        "tier1-overview.md": render_tier1_overview(agents),
        "tier2-capabilities.md": render_tier2_capabilities(agents),
        "tier3-opinions.md": render_tier3_opinions(agents),
    }

    for filename, content in outputs.items():
        dest = args.out / filename
        dest.write_text(content)
        print(f"  wrote {dest.relative_to(REPO_ROOT)}  ({len(content.splitlines())} lines)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
