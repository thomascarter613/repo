from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import re
import uuid

import yaml

from ai_memory_bank.config import Settings
from ai_memory_bank.git_ops import current_branch, current_head


FRONT_MATTER_PATTERN = re.compile(r"\A---\s*\n(.*?)\n---\s*\n?", re.DOTALL)
MARKDOWN_COMMENT_PATTERN = re.compile(r"<!--.*?-->", re.DOTALL)
COMPLETED_TASK_PATTERN = re.compile(r"^\s*[-*]\s*\[x\]\s+.+$", re.IGNORECASE)


@dataclass(frozen=True)
class CompileResult:
    latest_context_file: Path
    snapshot_file: Path | None
    files_compiled: tuple[Path, ...]
    archived_tasks: tuple[str, ...]


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def extract_front_matter(content: str) -> tuple[str | None, str]:
    match = FRONT_MATTER_PATTERN.match(content)
    if not match:
        return None, content
    return match.group(1), content[match.end() :]


def validate_yaml_front_matter(content: str, file_path: Path) -> None:
    front_matter, _ = extract_front_matter(content)
    if front_matter is None:
        return
    data = yaml.safe_load(front_matter)
    if data is not None and not isinstance(data, dict):
        raise ValueError(f"Front matter must be a YAML mapping in {file_path}")


def normalize_markdown(content: str, strip_comments: bool = True, collapse_blank_lines: bool = True) -> str:
    value = content.replace("\r\n", "\n")
    if strip_comments:
        value = MARKDOWN_COMMENT_PATTERN.sub("", value)
    if collapse_blank_lines:
        value = re.sub(r"\n{3,}", "\n\n", value)
    return value.strip() + "\n"


def prune_completed_tasks(settings: Settings) -> list[str]:
    roadmap_path = settings.memory.roadmap_file
    if not roadmap_path.exists():
        return []

    original = roadmap_path.read_text(encoding="utf-8")
    front_matter, body = extract_front_matter(original)

    kept_lines: list[str] = []
    archived_lines: list[str] = []

    for line in body.splitlines():
        if COMPLETED_TASK_PATTERN.match(line):
            archived_lines.append(line.strip())
        else:
            kept_lines.append(line)

    if not archived_lines:
        return []

    timestamp = utc_now().replace(microsecond=0).isoformat()
    settings.paths.archive_file.parent.mkdir(parents=True, exist_ok=True)
    with settings.paths.archive_file.open("a", encoding="utf-8") as archive:
        for item in archived_lines:
            archive.write(f"[{timestamp}] {item}\n")

    rebuilt = []
    if front_matter is not None:
        rebuilt.append("---")
        rebuilt.append(front_matter.rstrip())
        rebuilt.append("---")
        rebuilt.append("")
    rebuilt.append("\n".join(kept_lines).strip())
    roadmap_path.write_text("\n".join(part for part in rebuilt if part != "") + "\n", encoding="utf-8")

    return archived_lines


def iter_memory_markdown_files(settings: Settings) -> list[Path]:
    files = [
        path
        for path in settings.paths.memory_dir.rglob("*.md")
        if path.is_file()
    ]
    return sorted(files, key=lambda path: str(path.relative_to(settings.paths.repo_root)))


def build_metadata_header(settings: Settings) -> str:
    branch = current_branch(settings.paths.repo_root) or "unknown"
    head = current_head(settings.paths.repo_root) or "unknown"
    timestamp = utc_now().replace(microsecond=0).isoformat()
    session_id = str(uuid.uuid4())
    return (
        "---\n"
        f"session_id: {session_id}\n"
        f"timestamp_utc: {timestamp}\n"
        "compiler_version: 2.0\n"
        f"git_branch: {branch}\n"
        f"git_head: {head}\n"
        "---\n"
    )


def compile_context(settings: Settings, snapshot: bool | None = None) -> CompileResult:
    if settings.compiler.prune_completed_tasks:
        archived_tasks = prune_completed_tasks(settings)
    else:
        archived_tasks = []

    compiled_sections: list[str] = []
    compiled_files: list[Path] = []

    for file_path in iter_memory_markdown_files(settings):
        content = file_path.read_text(encoding="utf-8")
        validate_yaml_front_matter(content, file_path)
        normalized = normalize_markdown(
            content,
            strip_comments=settings.compiler.strip_markdown_comments,
            collapse_blank_lines=settings.compiler.collapse_blank_lines,
        )
        relative = file_path.relative_to(settings.paths.repo_root)
        compiled_sections.append(f"# FILE: {relative.as_posix()}\n\n{normalized}")
        compiled_files.append(file_path)

    final_output = build_metadata_header(settings).rstrip() + "\n\n" + "\n\n".join(compiled_sections).strip() + "\n"
    settings.paths.latest_context_file.parent.mkdir(parents=True, exist_ok=True)
    settings.paths.latest_context_file.write_text(final_output, encoding="utf-8")

    use_snapshot = settings.compiler.snapshot_on_compile if snapshot is None else snapshot
    snapshot_path: Path | None = None
    if use_snapshot:
        settings.paths.snapshot_dir.mkdir(parents=True, exist_ok=True)
        stamp = utc_now().strftime("%Y%m%dT%H%M%SZ")
        snapshot_path = settings.paths.snapshot_dir / f"LATEST_CONTEXT_{stamp}.md"
        snapshot_path.write_text(final_output, encoding="utf-8")

    return CompileResult(
        latest_context_file=settings.paths.latest_context_file,
        snapshot_file=snapshot_path,
        files_compiled=tuple(compiled_files),
        archived_tasks=tuple(archived_tasks),
    )
