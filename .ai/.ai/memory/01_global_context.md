---
kind: global_context
schema_version: 1
project:
  name: Example Project
  code_name: save-game
  repository_role: canonical persistent context store
mission: >-
  Preserve durable engineering context across disconnected chat sessions while keeping
  the active state compact, reviewable, and git-auditable.
rules:
  - Edit source state in .ai/memory only; never hand-edit .ai/LATEST_CONTEXT.md.
  - Canonical decisions must be recorded before implementation begins.
  - Prefer additive updates over destructive rewrites.
  - The active buffer should describe the next practical move, not vague intentions.
  - Completed roadmap tasks should not remain in the active task window.
canonical_locations:
  memory_source: .ai/memory/
  compiled_context: .ai/LATEST_CONTEXT.md
  compiler: .ai/scripts/aggregate.py
  workflow: .github/workflows/sync.yml
session_contract:
  bootstrap_reads:
    - .ai/LATEST_CONTEXT.md
  checkpoint_updates:
    - .ai/memory/02_roadmap.md
    - .ai/memory/04_active_buffer.md
  handoff_updates:
    - .ai/memory/04_active_buffer.md
    - .ai/memory/03_logic_map.md
  required_output:
    - explicit next actions
    - blockers and open questions
    - files touched or intended
    - decisions made or deferred
naming:
  task_id_pattern: ^TASK-[0-9]{3,}$
  decision_id_pattern: ^ADR-[0-9]{3,}$
  branch_hint_pattern: feat/<topic> | fix/<topic> | docs/<topic>
---

# Project DNA

This file stores durable project identity, hard rules, and repository-level invariants.
Keep this file compact. Anything that changes often belongs in the roadmap or active buffer.
