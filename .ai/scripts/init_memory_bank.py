#!/usr/bin/env python3
"""Initialize canonical seed memory state from template files."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict

TEMPLATE_MAP = {
    "01_global_context.template.md": "01_global_context.md",
    "02_roadmap.template.md": "02_roadmap.md",
    "03_logic_map.template.md": "03_logic_map.md",
    "04_active_buffer.template.md": "04_active_buffer.md",
}


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def slugify(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-{2,}", "-", value).strip("-")
    return value or "project"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Initialize the repository memory bank.")
    parser.add_argument("--project-name", default="", help="Display name of the project. Defaults to the repo directory name.")
    parser.add_argument("--code-name", default="", help="Slug-like code name. Defaults to a slugified project name.")
    parser.add_argument("--repo-role", default="canonical persistent context store", help="Repository role description.")
    parser.add_argument(
        "--current-phase",
        default="foundation",
        choices=["foundation", "planning", "implementation", "stabilization", "maintenance", "archive"],
        help="Initial phase for the roadmap.",
    )
    parser.add_argument(
        "--initial-objective",
        default="Stand up and verify the Git-backed long-term memory bank.",
        help="Initial active objective for the roadmap and active buffer.",
    )
    parser.add_argument("--session-id", default="bootstrap", help="Initial session identifier.")
    parser.add_argument("--force", action="store_true", help="Overwrite existing canonical memory files.")
    parser.add_argument("--skip-compile", action="store_true", help="Write seed files but do not run the compiler.")
    return parser.parse_args()


def load_template(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def render_template(template_text: str, replacements: Dict[str, str]) -> str:
    rendered = template_text
    for token, value in replacements.items():
        rendered = rendered.replace(token, value)
    return rendered


def write_if_allowed(path: Path, content: str, force: bool) -> None:
    if path.exists() and not force:
        raise SystemExit(
            f"Refusing to overwrite existing file without --force: {path}"
        )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def main() -> int:
    args = parse_args()
    repo_root = Path.cwd()
    ai_root = repo_root / ".ai"
    templates_root = ai_root / "templates"
    memory_root = ai_root / "memory"

    if not templates_root.exists():
        raise SystemExit(f"Template root not found: {templates_root}")

    project_name = args.project_name.strip() or repo_root.name
    code_name = args.code_name.strip() or slugify(project_name)
    started_at = utc_now_iso()

    replacements = {
        "__PROJECT_NAME__": project_name,
        "__CODE_NAME__": code_name,
        "__REPO_ROLE__": args.repo_role.strip(),
        "__CURRENT_PHASE__": args.current_phase,
        "__INITIAL_OBJECTIVE__": args.initial_objective.strip(),
        "__SESSION_ID__": args.session_id.strip() or "bootstrap",
        "__STARTED_AT_UTC__": started_at,
        "__FIRST_ACTION_TARGET__": ".ai/scripts/aggregate.py",
        "__SECOND_ACTION_TARGET__": ".github/workflows/sync.yml",
    }

    for template_name, output_name in TEMPLATE_MAP.items():
        template_path = templates_root / template_name
        if not template_path.exists():
            raise SystemExit(f"Missing template file: {template_path}")
        output_path = memory_root / output_name
        content = render_template(load_template(template_path), replacements)
        write_if_allowed(output_path, content, args.force)

    archive_path = memory_root / "archive.log"
    if not archive_path.exists() or args.force:
        write_if_allowed(
            archive_path,
            "# Roadmap Archive Log\n\nCompleted tasks are appended here by `.ai/scripts/aggregate.py`.\n",
            args.force or not archive_path.exists(),
        )

    if not args.skip_compile:
        subprocess.run([sys.executable, ".ai/scripts/aggregate.py"], check=True)

    print("Initialized canonical memory state.")
    print(f"Project name: {project_name}")
    print(f"Code name: {code_name}")
    print(f"Memory root: {memory_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
