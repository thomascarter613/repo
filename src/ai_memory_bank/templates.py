from __future__ import annotations

from pathlib import Path

from ai_memory_bank.config import Settings


GLOBAL_CONTEXT_TEMPLATE = """---
project_name: ""
mission: ""
constraints:
  - ""
coding_standards:
  - ""
ai_behavior_rules:
  - ""
---

# Global Context

Core identity, rules, invariants, and non-negotiable operating assumptions.
"""

ROADMAP_TEMPLATE = """---
current_phase: ""
milestones:
  - name: ""
    status: active
---

# Roadmap

## Active Tasks
- [ ] Define the next deliverable.
- [ ] Validate the output before commit.

## Completed (auto-pruned)
- [x] Initial memory bank scaffold created.
"""

LOGIC_MAP_TEMPLATE = """---
systems:
  - name: ""
    description: ""
dependencies:
  - ""
---

# Logic Map

Document architecture, dependencies, major flows, and technical mental models.
"""

ACTIVE_BUFFER_TEMPLATE = """---
session_focus: ""
current_task: ""
blockers:
  - ""
next_actions:
  - ""
---

# Active Buffer

## Notes
Working memory scratchpad for the current session.

## Decisions
- Capture decisions and rationale here.

## Immediate Next Steps
- Define the next concrete step.
"""

SETTINGS_TEMPLATE = """version: 1

paths:
  memory_dir: .ai/memory
  compiled_dir: .ai/compiled
  latest_context_file: .ai/compiled/LATEST_CONTEXT.md
  snapshot_dir: .ai/compiled/snapshots
  runtime_dir: .ai/runtime
  prompt_dir: .ai/runtime/prompts
  config_file: .ai/config/settings.yaml
  archive_file: .ai/memory/archive.log
  handoff_monologue_file: .ai/runtime/last_internal_monologue.md

memory:
  roadmap_file: .ai/memory/02_roadmap.md
  core_files:
    - .ai/memory/01_global_context.md
    - .ai/memory/02_roadmap.md
    - .ai/memory/03_logic_map.md
    - .ai/memory/04_active_buffer.md
  write_roots:
    - .ai/memory

compiler:
  prune_completed_tasks: true
  strip_markdown_comments: true
  collapse_blank_lines: true
  snapshot_on_compile: true

git:
  stage_on_apply: true
  commit_on_apply: false
"""


def scaffold_files(settings: Settings, overwrite: bool = False) -> list[Path]:
    created: list[Path] = []
    file_map = {
        settings.paths.config_file: SETTINGS_TEMPLATE,
        settings.memory.core_files[0]: GLOBAL_CONTEXT_TEMPLATE,
        settings.memory.core_files[1]: ROADMAP_TEMPLATE,
        settings.memory.core_files[2]: LOGIC_MAP_TEMPLATE,
        settings.memory.core_files[3]: ACTIVE_BUFFER_TEMPLATE,
        settings.paths.archive_file: "",
    }

    for path, content in file_map.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        if overwrite or not path.exists():
            path.write_text(content, encoding="utf-8")
            created.append(path)

    return created
