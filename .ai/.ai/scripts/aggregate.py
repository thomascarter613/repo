#!/usr/bin/env python3
"""Compile hybrid YAML/Markdown memory files into a single context artifact.

Features:
- Recursively reads .ai/memory/*.md
- Validates YAML front matter against JSON Schema files in .ai/schemas/
- Strips HTML comments and redundant whitespace for token efficiency
- Prunes completed roadmap tasks into archive.log
- Emits .ai/LATEST_CONTEXT.md with a metadata header, session ID, and validation summary
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from dataclasses import dataclass
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError as exc:  # pragma: no cover
    raise SystemExit("PyYAML is required. Install it with: python -m pip install pyyaml") from exc

try:
    import jsonschema
    from jsonschema import Draft202012Validator, FormatChecker
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "jsonschema is required. Install it with: python -m pip install jsonschema"
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
SCHEMA_MAP = {
    "01_global_context.md": "01_global_context.schema.json",
    "02_roadmap.md": "02_roadmap.schema.json",
    "03_logic_map.md": "03_logic_map.schema.json",
    "04_active_buffer.md": "04_active_buffer.schema.json",
}
GENERIC_NOTE_SCHEMA = {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "required": ["kind", "schema_version"],
    "additionalProperties": True,
    "properties": {
        "kind": {"type": "string", "minLength": 1},
        "schema_version": {"type": "integer", "minimum": 1},
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
class ValidationSummary:
    files_validated: int
    schema_files_loaded: int
    strict_schema_files_validated: int


@dataclass
class PruneResult:
    archived_count: int
    active_task_count: int


class SchemaEngine:
    def __init__(self, schema_root: Path) -> None:
        self.schema_root = schema_root
        self.schema_cache: dict[str, dict[str, Any]] = {}
        self.strict_validation_count = 0

    def _load_schema(self, schema_name: str) -> dict[str, Any]:
        if schema_name in self.schema_cache:
            return self.schema_cache[schema_name]

        schema_path = self.schema_root / schema_name
        if not schema_path.exists():
            raise MemoryValidationError(f"Schema file not found: {schema_path}")

        try:
            schema = json.loads(schema_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise MemoryValidationError(f"Invalid JSON schema file {schema_path}: {exc}") from exc

        Draft202012Validator.check_schema(schema)
        self.schema_cache[schema_name] = schema
        return schema

    def validate(self, file_name: str, payload: dict[str, Any], file_path: Path) -> None:
        schema_name = SCHEMA_MAP.get(file_name)
        if schema_name:
            schema = self._load_schema(schema_name)
            self.strict_validation_count += 1
        else:
            schema = GENERIC_NOTE_SCHEMA

        validator = Draft202012Validator(schema, format_checker=FormatChecker())
        errors = sorted(validator.iter_errors(payload), key=lambda err: list(err.absolute_path))
        if errors:
            rendered = []
            for error in errors:
                path = "/".join(str(part) for part in error.absolute_path) or "<root>"
                rendered.append(f"- {path}: {error.message}")
            raise MemoryValidationError(
                f"{file_path}: schema validation failed\n" + "\n".join(rendered)
            )

        self._validate_semantics(file_name=file_name, payload=payload, file_path=file_path)

    def _validate_semantics(self, file_name: str, payload: dict[str, Any], file_path: Path) -> None:
        if file_name == "02_roadmap.md":
            tasks = payload.get("tasks", [])
            seen: set[str] = set()
            for index, task in enumerate(tasks, start=1):
                task_id = task["id"]
                if task_id in seen:
                    raise MemoryValidationError(
                        f"{file_path}: duplicate task id '{task_id}' at tasks[{index}]"
                    )
                seen.add(task_id)

        if file_name == "04_active_buffer.md":
            next_actions = payload.get("next_actions", [])
            orders = [action["order"] for action in next_actions]
            if orders != sorted(orders):
                raise MemoryValidationError(
                    f"{file_path}: next_actions.order must be sorted in ascending sequence"
                )
            if len(set(orders)) != len(orders):
                raise MemoryValidationError(
                    f"{file_path}: next_actions.order must contain unique integers"
                )

    @property
    def schema_count(self) -> int:
        return len(self.schema_cache)


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def repo_relative(path: Path) -> str:
    return os.path.relpath(path, start=Path.cwd()).replace("\\", "/")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compile long-term memory state.")
    parser.add_argument("--memory-root", default=".ai/memory", help="Directory containing source memory files.")
    parser.add_argument("--schema-root", default=".ai/schemas", help="Directory containing JSON Schema files.")
    parser.add_argument("--output", default=".ai/LATEST_CONTEXT.md", help="Compiled output file.")
    parser.add_argument("--archive-file", default=".ai/memory/archive.log", help="Archive log for completed roadmap tasks.")
    parser.add_argument(
        "--session-id",
        default=os.getenv("SESSION_ID", ""),
        help="Stable identifier for the current chat or workflow session.",
    )
    return parser.parse_args()




def normalize_yaml_scalars(value: Any) -> Any:
    if isinstance(value, datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=timezone.utc)
        return value.replace(microsecond=0).isoformat().replace("+00:00", "Z")
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, list):
        return [normalize_yaml_scalars(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize_yaml_scalars(item) for key, item in value.items()}
    return value

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

    return normalize_yaml_scalars(loaded), body


def parse_memory_file(path: Path, schema_engine: SchemaEngine) -> ParsedMemoryFile:
    raw_text = path.read_text(encoding="utf-8")
    front_matter, body = split_front_matter(raw_text, path)
    schema_engine.validate(path.name, front_matter, path)
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
        raise MemoryValidationError("Missing required memory files: " + ", ".join(missing))


def append_archive_entries(archive_file: Path, entries: list[dict[str, Any]], session_id: str) -> None:
    archive_file.parent.mkdir(parents=True, exist_ok=True)
    if not archive_file.exists():
        archive_file.write_text(
            "# Roadmap Archive Log\n\nCompleted tasks are appended here by `.ai/scripts/aggregate.py`.\n",
            encoding="utf-8",
        )

    timestamp = utc_now_iso()
    blocks: list[str] = []
    for entry in entries:
        payload = dict(entry)
        payload["archived_at_utc"] = timestamp
        payload["archived_by_session"] = session_id or "local"
        yaml_block = yaml.safe_dump(payload, sort_keys=False, allow_unicode=True).strip()
        blocks.append(f"\n## {entry.get('id', 'unknown-task')}\n\n```yaml\n{yaml_block}\n```\n")

    with archive_file.open("a", encoding="utf-8") as handle:
        handle.write("".join(blocks))


def prune_completed_tasks(
    roadmap_path: Path,
    archive_file: Path,
    session_id: str,
    schema_engine: SchemaEngine,
) -> PruneResult:
    raw_text = roadmap_path.read_text(encoding="utf-8")
    front_matter, body = split_front_matter(raw_text, roadmap_path)
    schema_engine.validate(roadmap_path.name, front_matter, roadmap_path)

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
        schema_engine.validate(roadmap_path.name, front_matter, roadmap_path)
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
    prune_result: PruneResult,
    validation_summary: ValidationSummary,
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
        "validation": {
            "files_validated": validation_summary.files_validated,
            "schema_files_loaded": validation_summary.schema_files_loaded,
            "strict_schema_files_validated": validation_summary.strict_schema_files_validated,
            "validator": "jsonschema.Draft202012Validator",
        },
        "archived_completed_tasks_in_this_run": prune_result.archived_count,
        "active_roadmap_tasks": prune_result.active_task_count,
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

    return "\n".join(sections).rstrip() + "\n"


def main() -> int:
    args = parse_args()
    memory_root = Path(args.memory_root).resolve()
    schema_root = Path(args.schema_root).resolve()
    output_path = Path(args.output).resolve()
    archive_file = Path(args.archive_file).resolve()
    session_id = args.session_id.strip()

    if not memory_root.exists():
        raise SystemExit(f"Memory root not found: {memory_root}")
    if not schema_root.exists():
        raise SystemExit(f"Schema root not found: {schema_root}")

    schema_engine = SchemaEngine(schema_root=schema_root)
    ensure_required_files(memory_root)

    roadmap_path = memory_root / "02_roadmap.md"
    prune_result = prune_completed_tasks(
        roadmap_path=roadmap_path,
        archive_file=archive_file,
        session_id=session_id,
        schema_engine=schema_engine,
    )

    files: list[ParsedMemoryFile] = []
    for path in sorted(memory_root.rglob("*.md")):
        if path.name.startswith("."):
            continue
        parsed = parse_memory_file(path=path, schema_engine=schema_engine)
        files.append(parsed)

    validation_summary = ValidationSummary(
        files_validated=len(files) + 1,  # roadmap validated once before prune and once in final pass
        schema_files_loaded=schema_engine.schema_count,
        strict_schema_files_validated=schema_engine.strict_validation_count,
    )

    compiled = build_compiled_document(
        files=files,
        output_path=output_path,
        session_id=session_id,
        prune_result=prune_result,
        validation_summary=validation_summary,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(compiled, encoding="utf-8")

    print(f"Compiled {len(files)} files into {repo_relative(output_path)}")
    print(f"Session ID: {session_id or 'local'}")
    print(f"Archived completed tasks this run: {prune_result.archived_count}")
    print(f"Active roadmap tasks: {prune_result.active_task_count}")
    print(f"Schema files loaded: {schema_engine.schema_count}")
    print(f"Strict schema validations executed: {schema_engine.strict_validation_count}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except MemoryValidationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
