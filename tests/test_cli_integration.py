from __future__ import annotations

from pathlib import Path
import os
import subprocess
import sys


PROJECT_SRC = Path(__file__).resolve().parents[1] / "src"


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    env = dict(os.environ)
    env["PYTHONPATH"] = str(PROJECT_SRC)
    result = subprocess.run(
        cmd,
        cwd=cwd,
        text=True,
        capture_output=True,
        check=False,
        env=env,
    )
    assert result.returncode == 0, (
        f"command failed: {' '.join(cmd)}\n"
        f"stdout:\n{result.stdout}\n"
        f"stderr:\n{result.stderr}"
    )
    return result


def test_init_apply_compile_and_stage(tmp_path: Path) -> None:
    repo = tmp_path

    run(["git", "init"], cwd=repo)
    run(["git", "config", "user.name", "Test User"], cwd=repo)
    run(["git", "config", "user.email", "test@example.com"], cwd=repo)

    run([sys.executable, "-m", "ai_memory_bank", "init"], cwd=repo)
    run(["git", "add", "."], cwd=repo)
    run(["git", "commit", "-m", "initial scaffold"], cwd=repo)

    packet = """=== FILE: .ai/memory/02_roadmap.md ===
---
current_phase: implementation
milestones:
  - name: Harden validation
    status: active
---

# Roadmap

## Active Tasks
- [ ] Add CI validation

=== FILE: .ai/memory/04_active_buffer.md ===
---
session_focus: automation
current_task: wire validation
blockers:
  - ""
next_actions:
  - add sync workflow
---

# Active Buffer

## Notes
Working on automation.

=== INTERNAL_MONOLOGUE ===
Next I planned to wire the sync workflow and verify staging.
"""

    packet_path = repo / "packet.md"
    packet_path.write_text(packet, encoding="utf-8")

    run([sys.executable, "-m", "ai_memory_bank", "apply", str(packet_path)], cwd=repo)

    assert (repo / ".ai" / "compiled" / "LATEST_CONTEXT.md").exists()
    assert (repo / ".ai" / "runtime" / "last_internal_monologue.md").exists()

    status = run(["git", "status", "--short"], cwd=repo).stdout
    assert ".ai/memory/02_roadmap.md" in status
    assert ".ai/memory/04_active_buffer.md" in status
    assert ".ai/compiled/LATEST_CONTEXT.md" in status
    assert ".ai/runtime/last_internal_monologue.md" in status
