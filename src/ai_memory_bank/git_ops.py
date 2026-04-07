from __future__ import annotations

from pathlib import Path
import subprocess


def _run_git(repo_root: Path, args: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=check,
    )


def git_available(repo_root: Path) -> bool:
    try:
        result = _run_git(repo_root, ["rev-parse", "--is-inside-work-tree"], check=False)
        return result.returncode == 0 and result.stdout.strip() == "true"
    except Exception:
        return False


def current_head(repo_root: Path) -> str | None:
    try:
        result = _run_git(repo_root, ["rev-parse", "--short", "HEAD"], check=False)
        return result.stdout.strip() or None if result.returncode == 0 else None
    except Exception:
        return None


def current_branch(repo_root: Path) -> str | None:
    try:
        result = _run_git(repo_root, ["branch", "--show-current"], check=False)
        return result.stdout.strip() or None if result.returncode == 0 else None
    except Exception:
        return None


def stage_paths(repo_root: Path, paths: list[Path]) -> bool:
    if not paths or not git_available(repo_root):
        return False
    relative = [str(path.resolve().relative_to(repo_root.resolve())) for path in paths]
    result = _run_git(repo_root, ["add", *relative], check=False)
    return result.returncode == 0


def commit(repo_root: Path, message: str) -> bool:
    if not git_available(repo_root):
        return False
    result = _run_git(repo_root, ["commit", "-m", message], check=False)
    return result.returncode == 0


def changed_files(repo_root: Path) -> list[str]:
    if not git_available(repo_root):
        return []
    result = _run_git(repo_root, ["status", "--short"], check=False)
    if result.returncode != 0:
        return []
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]
