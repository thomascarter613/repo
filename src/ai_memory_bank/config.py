from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any
import copy

import yaml


DEFAULTS: dict[str, Any] = {
    "version": 1,
    "paths": {
        "memory_dir": ".ai/memory",
        "compiled_dir": ".ai/compiled",
        "latest_context_file": ".ai/compiled/LATEST_CONTEXT.md",
        "snapshot_dir": ".ai/compiled/snapshots",
        "runtime_dir": ".ai/runtime",
        "prompt_dir": ".ai/runtime/prompts",
        "config_file": ".ai/config/settings.yaml",
        "archive_file": ".ai/memory/archive.log",
        "handoff_monologue_file": ".ai/runtime/last_internal_monologue.md",
    },
    "memory": {
        "roadmap_file": ".ai/memory/02_roadmap.md",
        "core_files": [
            ".ai/memory/01_global_context.md",
            ".ai/memory/02_roadmap.md",
            ".ai/memory/03_logic_map.md",
            ".ai/memory/04_active_buffer.md",
        ],
        "write_roots": [".ai/memory"],
    },
    "compiler": {
        "prune_completed_tasks": True,
        "strip_markdown_comments": True,
        "collapse_blank_lines": True,
        "snapshot_on_compile": True,
    },
    "git": {
        "stage_on_apply": True,
        "commit_on_apply": False,
    },
}


@dataclass(frozen=True)
class Paths:
    repo_root: Path
    memory_dir: Path
    compiled_dir: Path
    latest_context_file: Path
    snapshot_dir: Path
    runtime_dir: Path
    prompt_dir: Path
    config_file: Path
    archive_file: Path
    handoff_monologue_file: Path


@dataclass(frozen=True)
class MemoryConfig:
    roadmap_file: Path
    core_files: tuple[Path, ...]
    write_roots: tuple[Path, ...]


@dataclass(frozen=True)
class CompilerConfig:
    prune_completed_tasks: bool
    strip_markdown_comments: bool
    collapse_blank_lines: bool
    snapshot_on_compile: bool


@dataclass(frozen=True)
class GitConfig:
    stage_on_apply: bool
    commit_on_apply: bool


@dataclass(frozen=True)
class Settings:
    version: int
    paths: Paths
    memory: MemoryConfig
    compiler: CompilerConfig
    git: GitConfig


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    merged = copy.deepcopy(base)
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = deep_merge(merged[key], value)
        else:
            merged[key] = value
    return merged


def find_repo_root(start: Path | None = None) -> Path:
    current = (start or Path.cwd()).resolve()
    for candidate in (current, *current.parents):
        if (candidate / ".git").exists() or (candidate / ".ai").exists():
            return candidate
    raise FileNotFoundError(
        "Could not locate repo root. Run this command inside a repository containing .git or .ai."
    )


def _resolve(repo_root: Path, value: str) -> Path:
    return (repo_root / value).resolve()


def load_settings(repo_root: Path | None = None) -> Settings:
    root = find_repo_root(repo_root)
    config_path = root / DEFAULTS["paths"]["config_file"]
    config_data: dict[str, Any] = {}
    if config_path.exists():
        raw = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
        if not isinstance(raw, dict):
            raise ValueError(f"Config file must contain a YAML mapping: {config_path}")
        config_data = raw

    merged = deep_merge(DEFAULTS, config_data)

    paths = Paths(
        repo_root=root,
        memory_dir=_resolve(root, merged["paths"]["memory_dir"]),
        compiled_dir=_resolve(root, merged["paths"]["compiled_dir"]),
        latest_context_file=_resolve(root, merged["paths"]["latest_context_file"]),
        snapshot_dir=_resolve(root, merged["paths"]["snapshot_dir"]),
        runtime_dir=_resolve(root, merged["paths"]["runtime_dir"]),
        prompt_dir=_resolve(root, merged["paths"]["prompt_dir"]),
        config_file=_resolve(root, merged["paths"]["config_file"]),
        archive_file=_resolve(root, merged["paths"]["archive_file"]),
        handoff_monologue_file=_resolve(root, merged["paths"]["handoff_monologue_file"]),
    )

    memory = MemoryConfig(
        roadmap_file=_resolve(root, merged["memory"]["roadmap_file"]),
        core_files=tuple(_resolve(root, item) for item in merged["memory"]["core_files"]),
        write_roots=tuple(_resolve(root, item) for item in merged["memory"]["write_roots"]),
    )

    compiler = CompilerConfig(
        prune_completed_tasks=bool(merged["compiler"]["prune_completed_tasks"]),
        strip_markdown_comments=bool(merged["compiler"]["strip_markdown_comments"]),
        collapse_blank_lines=bool(merged["compiler"]["collapse_blank_lines"]),
        snapshot_on_compile=bool(merged["compiler"]["snapshot_on_compile"]),
    )

    git = GitConfig(
        stage_on_apply=bool(merged["git"]["stage_on_apply"]),
        commit_on_apply=bool(merged["git"]["commit_on_apply"]),
    )

    return Settings(
        version=int(merged["version"]),
        paths=paths,
        memory=memory,
        compiler=compiler,
        git=git,
    )


def ensure_directories(settings: Settings) -> None:
    directories = (
        settings.paths.memory_dir,
        settings.paths.compiled_dir,
        settings.paths.snapshot_dir,
        settings.paths.runtime_dir,
        settings.paths.prompt_dir,
        settings.paths.config_file.parent,
    )
    for directory in directories:
        directory.mkdir(parents=True, exist_ok=True)
