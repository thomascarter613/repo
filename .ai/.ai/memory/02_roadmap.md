---
kind: roadmap
schema_version: 1
current_phase: foundation
active_objective: Build and operationalize the Git-backed long-term memory bank.
tasks:
- id: TASK-001
  title: Define the memory folder schema and file contracts.
  status: in_progress
  priority: P0
  depends_on: []
  acceptance:
  - All four core state files exist.
  - Each file has valid YAML front matter.
  files:
  - .ai/memory/01_global_context.md
  - .ai/memory/02_roadmap.md
  - .ai/memory/03_logic_map.md
  - .ai/memory/04_active_buffer.md
- id: TASK-002
  title: Implement the context compiler.
  status: in_progress
  priority: P0
  depends_on:
  - TASK-001
  acceptance:
  - Compiler validates front matter.
  - Compiler generates .ai/LATEST_CONTEXT.md.
  - Compiler strips HTML comments and redundant whitespace.
  files:
  - .ai/scripts/aggregate.py
- id: TASK-003
  title: Add automated sync workflow.
  status: planned
  priority: P0
  depends_on:
  - TASK-002
  acceptance:
  - GitHub Action runs on pushes affecting .ai/memory.
  - Generated context is auto-committed if changed.
  files:
  - .github/workflows/sync.yml
- id: TASK-004
  title: Record initial bootstrap prompts.
  status: planned
  priority: P1
  depends_on:
  - TASK-002
  acceptance:
  - Bootstrap prompt exists.
  - Checkpoint prompt exists.
  - Handoff prompt exists.
last_review_utc: '2026-04-07T00:00:00Z'
last_pruned_utc: '2026-04-07T08:41:32Z'
---

# Progress Ledger

Use the YAML task list as the canonical active queue.
Use the Markdown body for phase notes, release framing, and concise narrative context.
