#!/usr/bin/env python3
"""Run a local checkpoint: validate, compile, and summarize pending AI memory changes."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create a local memory checkpoint.")
    parser.add_argument("--session-id", default=os.getenv("SESSION_ID", "local"), help="Session identifier passed to the compiler.")
    parser.add_argument("--python", default=sys.executable, help="Python interpreter to use for subprocesses.")
    return parser.parse_args()


def run_command(command: list[str], env: dict[str, str] | None = None) -> None:
    subprocess.run(command, check=True, env=env)


def git_changed_files(repo_root: Path) -> list[str]:
    try:
        output = subprocess.check_output(
            ["git", "status", "--short", "--", ".ai", ".github/workflows/sync.yml", "Makefile", "justfile"],
            cwd=repo_root,
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []

    changed: list[str] = []
    for line in output.splitlines():
        line = line.rstrip()
        if not line:
            continue
        changed.append(line)
    return changed


def main() -> int:
    args = parse_args()
    repo_root = Path.cwd()

    run_command([args.python, ".ai/scripts/validate_memory_bank.py"])

    env = os.environ.copy()
    env["SESSION_ID"] = args.session_id
    run_command([args.python, ".ai/scripts/aggregate.py"], env=env)

    changed = git_changed_files(repo_root)
    print("Checkpoint complete.")
    print(f"Session ID: {args.session_id}")

    if changed:
        print("Changed files:")
        for line in changed:
            print(f"  {line}")
        print('Suggested commit message: chore(ai-memory): checkpoint state')
    else:
        print("No tracked AI memory changes detected after checkpoint.")

    print("Bootstrap prompt: .ai/prompts/01_bootstrap_prompt.md")
    print("Checkpoint prompt: .ai/prompts/02_checkpoint_prompt.md")
    print("Handoff prompt: .ai/prompts/03_handoff_prompt.md")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
