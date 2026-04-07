#!/usr/bin/env python3
"""Compile hybrid YAML/Markdown memory files into a single context artifact.

Key behaviors:
- Recursively reads .ai/memory/*.md
- Validates YAML front matter syntax and a minimal file contract
- Prunes completed roadmap tasks into archive.log
- Strips HTML comments and redundant whitespace for token efficiency
- Emits .ai/LATEST_CONTEXT.md with metadata and normalized sections
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "PyYAML is required. Install it with: python -m pip install pyyaml"
    ) from exc

FRONT_MATTER_RE = re.compile(r"\A---\s*\n(.*?)\n---\s*\n?", re.DOTALL)
HTML_COMMENT_RE = re.compile(r"<!--.*?-->", re.DOTALL)
BLANK_RUN_RE = re.compile(r"\n{3,}")
TRAILING_SPACE_RE = re.compile(r"[ \t]+$", re.MULTILINE)
COMPLETED_STATUSES = {"completed", "done"}
REQUIRED_FILES = {
    "01_global_context.md",
    "02_roadmap.md",
    "03_logic_map.md",
    "04_active_buffer.md",
}
SCHEMA_REQUIREMENTS: dict[str, dict[str, Any]] = {
    "01_global_context.md": {
        "required": [
            "kind",
            "schema_version",
            "project",
            "mission",
            "rules",
            "canonical_locations",
            "session_contract",
        ],
        "kind": "global_context",
    },
    "02_roadmap.md": {
        "required": [
            "kind",
            "schema_version",
            "current_phase",
            "active_objective",
            "tasks",
        ],
        "kind": "roadmap",
    },
    "03_logic_map.md": {
        "required": [
            "kind",
            "schema_version",
            "system_model",
            "components",
            "flows",
            "invariants",
        ],
        "kind": "logic_map",
    },
    "04_active_buffer.md": {
        "required": [
            "kind",
            "schema_version",
            "session",
            "focus",
            "working_set",
            "next_actions",
            "risks",
        ],
        "kind": "active_buffer",
    },
}


class MemoryValidationError(RuntimeError):
    """Raised when a memory file is malformed."""


@dataclass
class ParsedMemoryFile:
    path: Path
    relative_path: str
    front_matter: dict[str, Any]
    body: str


@dataclass
class PruneResult:
    archived_count: int
    active_task_count: int


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def repo_relative(path: Path) -> str:
    return os.path.relpath(path, start=Path.cwd()).replace("\\", "/")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compile long-term memory state.")
    parser.add_argument(
        "--memory-root",
        default=".ai/memory",
        help="Directory containing hybrid YAML/Markdown state files.",
    )
    parser.add_argument(
        "--output",
        default=".ai/LATEST_CONTEXT.md",
        help="Compiled output file.",
    )
    parser.add_argument(
        "--archive-file",
        default=".ai/memory/archive.log",
        help="Archive file used for completed roadmap items.",
    )
    parser.add_argument(
        "--session-id",
        default=os.getenv("SESSION_ID", ""),
        help="Stable identifier for the current chat or workflow session.",
    )
    return parser.parse_args()


def strip_markdown_noise(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = HTML_COMMENT_RE.sub("", text)
    text = TRAILING_SPACE_RE.sub("", text)
    text = BLANK_RUN_RE.sub("\n\n", text)
    return text.strip() + "\n"


def split_front_matter(raw_text: str, file_path: Path) -> tuple[dict[str, Any], str]:
    match = FRONT_MATTER_RE.match(raw_text)
    if not match:
        raise MemoryValidationError(
            f"{file_path}: missing YAML front matter delimited by leading --- blocks"
        )

    front_matter_text = match.group(1)
    body = raw_text[match.end() :]

    try:
        loaded = yaml.safe_load(front_matter_text) or {}
    except yaml.YAMLError as exc:
        raise MemoryValidationError(f"{file_path}: invalid YAML front matter\n{exc}") from exc

    if not isinstance(loaded, dict):
        raise MemoryValidationError(f"{file_path}: front matter must deserialize to a YAML mapping")

    return loaded, body


def validate_schema(file_name: str, front_matter: dict[str, Any], file_path: Path) -> None:
    requirements = SCHEMA_REQUIREMENTS.get(file_name)
    if not requirements:
        return

    required_keys = requirements["required"]
    missing = [key for key in required_keys if key not in front_matter]
    if missing:
        raise MemoryValidationError(f"{file_path}: missing required front matter keys: {', '.join(missing)}")

    expected_kind = requirements["kind"]
    actual_kind = front_matter.get("kind")
    if actual_kind != expected_kind:
        raise MemoryValidationError(
            f"{file_path}: kind must be '{expected_kind}', found '{actual_kind}'"
        )

    if file_name == "02_roadmap.md":
        tasks = front_matter.get("tasks")
        if not isinstance(tasks, list):
            raise MemoryValidationError(f"{file_path}: tasks must be a YAML list")
        for index, task in enumerate(tasks, start=1):
            if not isinstance(task, dict):
                raise MemoryValidationError(f"{file_path}: tasks[{index}] must be a YAML mapping")
            for key in ["id", "title", "status", "priority"]:
                if key not in task:
                    raise MemoryValidationError(
                        f"{file_path}: tasks[{index}] missing required key '{key}'"
                    )

    if file_name == "04_active_buffer.md":
        next_actions = front_matter.get("next_actions")
        if not isinstance(next_actions, list) or not next_actions:
            raise MemoryValidationError(
                f"{file_path}: next_actions must be a non-empty YAML list"
            )


def parse_memory_file(path: Path) -> ParsedMemoryFile:
    raw_text = path.read_text(encoding="utf-8")
    front_matter, body = split_front_matter(raw_text, path)
    validate_schema(path.name, front_matter, path)
    clean_body = strip_markdown_noise(body)
    return ParsedMemoryFile(
        path=path,
        relative_path=repo_relative(path),
        front_matter=front_matter,
        body=clean_body,
    )


def ensure_required_files(memory_root: Path) -> None:
    present = {path.name for path in memory_root.glob("*.md")}
    missing = sorted(REQUIRED_FILES - present)
    if missing:
        raise MemoryValidationError(
            "Missing required memory files: " + ", ".join(missing)
        )


def append_archive_entries(archive_file: Path, entries: list[dict[str, Any]], session_id: str) -> None:
    archive_file.parent.mkdir(parents=True, exist_ok=True)
    if not archive_file.exists():
        archive_file.write_text(
            "# Roadmap Archive Log\n\n"
            "Completed tasks are appended here by `.ai/scripts/aggregate.py`.\n\n",
            encoding="utf-8",
        )

    timestamp = utc_now_iso()
    chunks: list[str] = []
    for entry in entries:
        entry_payload = dict(entry)
        entry_payload["archived_at_utc"] = timestamp
        entry_payload["archived_by_session"] = session_id or "local"
        yaml_block = yaml.safe_dump(entry_payload, sort_keys=False, allow_unicode=True).strip()
        chunks.append(f"## {entry.get('id', 'unknown-task')}\n\n```yaml\n{yaml_block}\n```\n")

    with archive_file.open("a", encoding="utf-8") as handle:
        handle.write("\n" + "\n".join(chunks) + "\n")


def prune_completed_tasks(roadmap_path: Path, archive_file: Path, session_id: str) -> PruneResult:
    raw_text = roadmap_path.read_text(encoding="utf-8")
    front_matter, body = split_front_matter(raw_text, roadmap_path)
    validate_schema(roadmap_path.name, front_matter, roadmap_path)

    tasks: list[dict[str, Any]] = front_matter.get("tasks", [])
    active: list[dict[str, Any]] = []
    completed: list[dict[str, Any]] = []

    for task in tasks:
        status = str(task.get("status", "")).strip().lower()
        if status in COMPLETED_STATUSES:
            completed.append(task)
        else:
            active.append(task)

    archived_count = len(completed)
    if archived_count:
        append_archive_entries(archive_file, completed, session_id)
        front_matter["tasks"] = active
        front_matter["last_pruned_utc"] = utc_now_iso()
        serialized = yaml.safe_dump(front_matter, sort_keys=False, allow_unicode=True).strip()
        updated_text = f"---\n{serialized}\n---\n\n{strip_markdown_noise(body)}"
        roadmap_path.write_text(updated_text, encoding="utf-8")

    return PruneResult(archived_count=archived_count, active_task_count=len(active))


def normalize_front_matter(front_matter: dict[str, Any]) -> str:
    return yaml.safe_dump(front_matter, sort_keys=False, allow_unicode=True).strip()


def build_compiled_document(
    files: list[ParsedMemoryFile],
    output_path: Path,
    session_id: str,
    archived_count: int,
    active_task_count: int,
) -> str:
    generated_at = utc_now_iso()
    source_files = [item.relative_path for item in files]
    fingerprint = hashlib.sha256("\n".join(source_files).encode("utf-8")).hexdigest()[:12]

    header = {
        "generated_at_utc": generated_at,
        "session_id": session_id or "local",
        "compiled_file": repo_relative(output_path),
        "source_root": ".ai/memory",
        "source_files": source_files,
        "source_fingerprint": fingerprint,
        "archived_completed_tasks_in_this_run": archived_count,
        "active_roadmap_tasks": active_task_count,
    }

    sections = [
        "# LATEST_CONTEXT",
        "",
        "```yaml",
        yaml.safe_dump(header, sort_keys=False, allow_unicode=True).strip(),
        "```",
        "",
        "> This file is generated. Edit source state in `.ai/memory/`, not here.",
        "",
    ]

    for item in files:
        sections.extend(
            [
                f"## {item.relative_path}",
                "",
                "```yaml",
                normalize_front_matter(item.front_matter),
                "```",
                "",
                item.body.rstrip(),
                "",
            ]
        )

    compiled = "\n".join(sections).rstrip() + "\n"
    return compiled


def main() -> int:
    args = parse_args()
    memory_root = Path(args.memory_root).resolve()
    output_path = Path(args.output).resolve()
    archive_file = Path(args.archive_file).resolve()
    session_id = args.session_id.strip()

    if not memory_root.exists():
        raise SystemExit(f"Memory root not found: {memory_root}")

    ensure_required_files(memory_root)
    roadmap_path = memory_root / "02_roadmap.md"
    prune_result = prune_completed_tasks(roadmap_path, archive_file, session_id)

    files: list[ParsedMemoryFile] = []
    for path in sorted(memory_root.rglob("*.md")):
        if path.name.startswith("."):
            continue
        files.append(parse_memory_file(path))

    compiled = build_compiled_document(
        files=files,
        output_path=output_path,
        session_id=session_id,
        archived_count=prune_result.archived_count,
        active_task_count=prune_result.active_task_count,
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(compiled, encoding="utf-8")

    print(f"Compiled {len(files)} files into {repo_relative(output_path)}")
    print(f"Session ID: {session_id or 'local'}")
    print(f"Archived completed tasks this run: {prune_result.archived_count}")
    print(f"Active roadmap tasks: {prune_result.active_task_count}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except MemoryValidationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
