# LATEST_CONTEXT

```yaml
generated_at_utc: '2026-04-07T04:06:52Z'
session_id: final-test
compiled_file: .ai/LATEST_CONTEXT.md
source_root: .ai/memory
source_files:
- .ai/memory/01_global_context.md
- .ai/memory/02_roadmap.md
- .ai/memory/03_logic_map.md
- .ai/memory/04_active_buffer.md
source_fingerprint: f6b8036ca705
archived_completed_tasks_in_this_run: 0
active_roadmap_tasks: 4
```

> This file is generated. Edit source state in `.ai/memory/`, not here.

## .ai/memory/01_global_context.md

```yaml
kind: global_context
schema_version: 1
project:
  name: Example Project
  code_name: save-game
  repository_role: canonical persistent context store
mission: Preserve durable engineering context across disconnected chat sessions while
  keeping the active state compact, reviewable, and git-auditable.
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
  task_id_pattern: TASK-###
  decision_id_pattern: ADR-###
  branch_hint_pattern: feat/<topic> | fix/<topic> | docs/<topic>
```

# Project DNA

This file stores durable project identity, hard rules, and repository-level invariants.
Keep this file compact. Anything that changes often belongs in the roadmap or active buffer.

## Operator Notes

- Put enduring truths here.
- Put live work state elsewhere.
- Prefer short bullets over narrative paragraphs.

## .ai/memory/02_roadmap.md

```yaml
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
- id: TASK-003
  title: Add automated sync workflow.
  status: planned
  priority: P0
  depends_on:
  - TASK-002
  acceptance:
  - GitHub Action runs on pushes affecting .ai/memory.
  - Generated context is auto-committed if changed.
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
last_review_utc: 2026-04-07 00:00:00+00:00
last_pruned_utc: '2026-04-07T04:04:44Z'
```

# Progress Ledger

Use the YAML task list as the canonical active queue.
Use the Markdown body for phase notes, release framing, and concise narrative context.

## Phase Notes

- Keep only active and near-active tasks in front matter.
- Let the compiler move completed work to the archive automatically.

## .ai/memory/03_logic_map.md

```yaml
kind: logic_map
schema_version: 1
system_model:
  summary: The repository is the durable state machine. Source memory files are the
    mutable state registers. The compiler is the reducer. The compiled context is
    the loadable save game.
components:
- name: memory_source
  location: .ai/memory/
  responsibility: human-editable durable state
- name: compiler
  location: .ai/scripts/aggregate.py
  responsibility: validation, pruning, normalization, context compilation
- name: compiled_context
  location: .ai/LATEST_CONTEXT.md
  responsibility: single-file bootstrap artifact for new chats
- name: sync_workflow
  location: .github/workflows/sync.yml
  responsibility: automatic regeneration and commit-back
flows:
- trigger: user edits .ai/memory/*.md
  path:
  - validate front matter
  - prune completed roadmap tasks
  - normalize content
  - compile .ai/LATEST_CONTEXT.md
  - commit generated updates
- trigger: new chat starts
  path:
  - paste or attach .ai/LATEST_CONTEXT.md
  - run bootstrap prompt
  - verify state synchronization
invariants:
- LATEST_CONTEXT.md is generated, never canonical.
- Active work lives in roadmap and active_buffer.
- Completed work is archived and not kept in the active task window.
- Validation failures must stop compilation.
```

# Technical Mental Model

## State Machine View

1. `.ai/memory/*.md` = mutable state registers.
2. `aggregate.py` = reducer + validator + compactor.
3. `.ai/LATEST_CONTEXT.md` = serialized load state.
4. Git history = audit log of memory evolution.

## Failure Policy

Fail closed on malformed YAML. A broken handoff should never silently poison future sessions.

## .ai/memory/04_active_buffer.md

```yaml
kind: active_buffer
schema_version: 1
session:
  id: local-bootstrap
  started_at_utc: 2026-04-07 00:00:00+00:00
  operator_goal: Stand up the initial memory bank scaffold.
focus:
  current_problem: Need a reliable save-game mechanism for cross-session continuity
    in disconnected web chats.
  current_slice: repo-backed long-term memory bank
working_set:
  files_in_play:
  - .ai/memory/01_global_context.md
  - .ai/memory/02_roadmap.md
  - .ai/memory/03_logic_map.md
  - .ai/memory/04_active_buffer.md
  - .ai/scripts/aggregate.py
  - .github/workflows/sync.yml
next_actions:
- Finalize the compiler.
- Run the compiler locally and verify output.
- Enable the GitHub Action and confirm commit-back behavior.
risks:
- Malformed YAML in front matter can break future bootstraps.
- Overlong handoffs can bloat token budgets.
- Auto-commit loops must be prevented by path scoping and generated-file placement.
blockers: []
resurrection_packet:
  resume_from: Verify compiled output and archive behavior.
  intended_first_move: Run the compiler against the current scaffold and inspect .ai/LATEST_CONTEXT.md.
  rationale_summary: The next highest-value step is to validate the full loop end-to-end
    before expanding schema depth.
```

# Live Handoff State

This file is the shortest path back into the work.
Update it whenever the session focus changes, a blocker appears, or the next move becomes clearer.
