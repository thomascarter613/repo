from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re

from ai_memory_bank.compiler import compile_context, validate_yaml_front_matter
from ai_memory_bank.config import Settings
from ai_memory_bank.git_ops import commit as git_commit
from ai_memory_bank.git_ops import stage_paths


FILE_HEADER_PATTERN = re.compile(r"^=== FILE: (?P<path>.+?) ===\s*$", re.MULTILINE)
INTERNAL_MONOLOGUE_HEADER = "=== INTERNAL_MONOLOGUE ==="


@dataclass(frozen=True)
class ParsedPacket:
    files: dict[str, str]
    internal_monologue: str | None


@dataclass(frozen=True)
class ApplyResult:
    written_files: tuple[Path, ...]
    monologue_file: Path | None
    compiled_context_file: Path | None
    snapshot_file: Path | None


def parse_packet_text(packet_text: str) -> ParsedPacket:
    matches = list(FILE_HEADER_PATTERN.finditer(packet_text))
    files: dict[str, str] = {}

    for index, match in enumerate(matches):
        start = match.end()
        end = matches[index + 1].start() if index + 1 < len(matches) else len(packet_text)
        body = packet_text[start:end]
        path = match.group("path").strip()
        files[path] = body.strip() + "\n"

    internal_monologue = None
    if INTERNAL_MONOLOGUE_HEADER in packet_text:
        internal_monologue = packet_text.split(INTERNAL_MONOLOGUE_HEADER, 1)[1].strip() + "\n"

    return ParsedPacket(files=files, internal_monologue=internal_monologue)


def _ensure_allowed(target: Path, settings: Settings) -> None:
    allowed = any(target.is_relative_to(root) for root in settings.memory.write_roots)
    if not allowed:
        allowed_roots = ", ".join(str(root) for root in settings.memory.write_roots)
        raise ValueError(f"Refusing to write outside allowed roots. Allowed roots: {allowed_roots}")


def apply_packet_text(
    packet_text: str,
    settings: Settings,
    dry_run: bool = False,
    compile_after: bool = True,
    stage_after: bool | None = None,
    commit_message: str | None = None,
) -> ApplyResult:
    parsed = parse_packet_text(packet_text)
    written_paths: list[Path] = []

    if not parsed.files and not parsed.internal_monologue:
        raise ValueError("No file sections or internal monologue section were found in the packet.")

    for relative_path, content in parsed.files.items():
        target = (settings.paths.repo_root / relative_path).resolve()
        _ensure_allowed(target, settings)
        if target.suffix == ".md":
            validate_yaml_front_matter(content, target)
        if not dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")
        written_paths.append(target)

    monologue_file: Path | None = None
    if parsed.internal_monologue:
        monologue_file = settings.paths.handoff_monologue_file
        if not dry_run:
            monologue_file.parent.mkdir(parents=True, exist_ok=True)
            monologue_file.write_text(parsed.internal_monologue, encoding="utf-8")

    compiled_context_file: Path | None = None
    snapshot_file: Path | None = None
    if compile_after and not dry_run:
        compile_result = compile_context(settings)
        compiled_context_file = compile_result.latest_context_file
        snapshot_file = compile_result.snapshot_file
        written_paths.append(compile_result.latest_context_file)
        if compile_result.snapshot_file is not None:
            written_paths.append(compile_result.snapshot_file)

    if monologue_file is not None:
        written_paths.append(monologue_file)

    if not dry_run and (stage_after if stage_after is not None else settings.git.stage_on_apply):
        stage_paths(settings.paths.repo_root, written_paths)

    if not dry_run and commit_message:
        git_commit(settings.paths.repo_root, commit_message)

    deduped = tuple(dict.fromkeys(path.resolve() for path in written_paths))
    return ApplyResult(
        written_files=deduped,
        monologue_file=monologue_file,
        compiled_context_file=compiled_context_file,
        snapshot_file=snapshot_file,
    )
