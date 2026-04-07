---
kind: roadmap
schema_version: 1
current_phase: "__CURRENT_PHASE__"
active_objective: "__INITIAL_OBJECTIVE__"
tasks:
  - id: TASK-001
    title: Initialize the memory bank and verify the compiler loop.
    status: in_progress
    priority: P0
    depends_on: []
    acceptance:
      - Canonical memory files exist.
      - The compiler generates .ai/LATEST_CONTEXT.md.
      - The repository can resume from compiled context.
    files:
      - .ai/memory/01_global_context.md
      - .ai/memory/02_roadmap.md
      - .ai/memory/03_logic_map.md
      - .ai/memory/04_active_buffer.md
      - .ai/scripts/aggregate.py
  - id: TASK-002
    title: Enable automated sync workflow for compiled context.
    status: planned
    priority: P0
    depends_on:
      - TASK-001
    acceptance:
      - GitHub Action runs when memory state changes.
      - Generated context is committed automatically when it changes.
    files:
      - .github/workflows/sync.yml
  - id: TASK-003
    title: Validate prompt-driven checkpoint and handoff flow.
    status: planned
    priority: P1
    depends_on:
      - TASK-001
    acceptance:
      - Bootstrap prompt restores state correctly.
      - Checkpoint prompt produces valid canonical updates.
      - Handoff prompt produces a usable resurrection packet.
    files:
      - .ai/prompts/01_bootstrap_prompt.md
      - .ai/prompts/02_checkpoint_prompt.md
      - .ai/prompts/03_handoff_prompt.md
last_review_utc: "__STARTED_AT_UTC__"
---

# Progress Ledger

Use the YAML task list as the canonical active queue.
Use the Markdown body for phase notes, release framing, and concise narrative context.

## Phase Notes

- Keep only active and near-active tasks in front matter.
- Let the compiler move completed work to the archive automatically.
