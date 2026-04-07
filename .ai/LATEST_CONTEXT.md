# LATEST_CONTEXT

```yaml
generated_at_utc: '2026-04-07T15:04:18Z'
session_id: '24088539482.1'
compiled_file: .ai/LATEST_CONTEXT.md
source_root: .ai/memory
source_files:
- .ai/memory/01_global_context.md
- .ai/memory/02_roadmap.md
- .ai/memory/03_logic_map.md
- .ai/memory/04_active_buffer.md
source_fingerprint: f6b8036ca705
validation:
  files_validated: 5
  schema_files_loaded: 4
  strict_schema_files_validated: 5
  validator: jsonschema.Draft202012Validator
archived_completed_tasks_in_this_run: 0
active_roadmap_tasks: 3
```

> This file is generated. Edit source state in `.ai/memory/`, not here.

## .ai/memory/01_global_context.md

```yaml
kind: global_context
schema_version: 1
project:
  name: Repository Memory Bank
  code_name: repository-memory-bank
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
  initializer: .ai/scripts/init_memory_bank.py
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
  task_id_regex: ^TASK-[0-9]{3,}$
  decision_id_regex: ^ADR-[0-9]{3,}$
  risk_id_regex: ^RISK-[0-9]{3,}$
  blocker_id_regex: ^BLK-[0-9]{3,}$
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
active_objective: Stand up and verify the Git-backed long-term memory bank.
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
last_review_utc: '2026-04-07T13:08:53Z'
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
  source_of_truth: .ai/memory/
  reducer: .ai/scripts/aggregate.py
  compiled_artifact: .ai/LATEST_CONTEXT.md
components:
- name: memory_source
  location: .ai/memory/
  responsibility: human-editable durable state
  outputs:
  - canonical long-term memory state
- name: templates
  location: .ai/templates/
  responsibility: reusable blueprints for initializing canonical state
  outputs:
  - seed content for the initializer
- name: initializer
  location: .ai/scripts/init_memory_bank.py
  responsibility: generate canonical seed state from templates
  inputs:
  - project metadata
  - initial objective
  outputs:
  - .ai/memory/*.md
- name: compiler
  location: .ai/scripts/aggregate.py
  responsibility: validation, pruning, normalization, context compilation
  inputs:
  - .ai/memory/*.md
  - .ai/schemas/*.json
  outputs:
  - .ai/LATEST_CONTEXT.md
- name: sync_workflow
  location: .github/workflows/sync.yml
  responsibility: automatic regeneration and commit-back
flows:
- trigger: user initializes or updates .ai/memory/*.md
  path:
  - validate YAML front matter
  - validate JSON Schema contracts
  - prune completed roadmap tasks
  - normalize content
  - compile .ai/LATEST_CONTEXT.md
  - commit generated updates
  outcome: latest compiled state stays aligned with canonical memory
- trigger: new chat starts
  path:
  - paste or attach .ai/LATEST_CONTEXT.md
  - run bootstrap prompt
  - verify state synchronization
  outcome: assistant resumes from durable repo state instead of prior chat history
interfaces:
- name: canonical_memory_files
  type: file
  contract: Each core memory file must have valid YAML front matter and match its
    schema.
- name: context_compiler
  type: script
  contract: Fails closed on malformed YAML or schema violations and regenerates compiled
    context.
- name: sync_workflow
  type: workflow
  contract: Rebuilds compiled context on state changes and commits only when generated
    files differ.
failure_modes:
- condition: malformed YAML or schema-invalid handoff
  behavior: compiler exits non-zero and does not emit a misleading compiled context
  mitigation: fix canonical source file until validation passes
- condition: active roadmap grows without pruning
  behavior: compiled context becomes noisier and more token-expensive
  mitigation: mark finished tasks completed and let the compiler archive them
invariants:
- .ai/LATEST_CONTEXT.md is generated and never canonical.
- .ai/memory/ is the source of truth for long-term state.
- Templates are blueprints, not live project state.
- Validation failures must stop compilation.
```

# Technical Mental Model

## State Machine View

1. `.ai/templates/*.template.md` = blueprint layer
2. `.ai/scripts/init_memory_bank.py` = seed-state generator
3. `.ai/memory/*.md` = mutable canonical state registers
4. `.ai/scripts/aggregate.py` = reducer + validator + compactor
5. `.ai/LATEST_CONTEXT.md` = serialized load state
6. Git history = audit trail of memory evolution

## Failure Policy

Fail closed on malformed YAML and schema violations. A broken handoff should never silently poison future sessions.

## .ai/memory/04_active_buffer.md

```yaml
kind: active_buffer
schema_version: 1
session:
  id: bootstrap
  started_at_utc: '2026-04-07T13:08:53Z'
  operator_goal: Stand up and verify the Git-backed long-term memory bank.
focus:
  current_problem: Need a reliable save-game mechanism for cross-session continuity
    in disconnected web chats.
  current_slice: long-term memory bank bootstrap
working_set:
  files_in_play:
  - .ai/memory/01_global_context.md
  - .ai/memory/02_roadmap.md
  - .ai/memory/03_logic_map.md
  - .ai/memory/04_active_buffer.md
  - .ai/scripts/init_memory_bank.py
  - .ai/scripts/aggregate.py
  - .github/workflows/sync.yml
  recent_decisions:
  - The repository stores durable state; compiled context is generated.
  - Prompt files live in .ai/prompts/, not in .ai/memory/.
  assumptions:
  - The repository will use GitHub Actions for automatic sync.
next_actions:
- order: 1
  title: Verify canonical seed files and regenerate compiled context.
  type: verify
  target: .ai/scripts/aggregate.py
  success_signal: The compiler exits zero and .ai/LATEST_CONTEXT.md is regenerated.
- order: 2
  title: Confirm the workflow can commit generated updates.
  type: verify
  target: .github/workflows/sync.yml
  success_signal: The sync workflow can push changes after memory edits.
risks:
- id: RISK-001
  title: Malformed YAML can poison future bootstraps if not rejected
  severity: high
  mitigation: Fail closed with schema validation before compilation
  status: open
- id: RISK-002
  title: Active context can become too large over time
  severity: medium
  mitigation: Keep the active roadmap lean and archive completed work automatically
  status: open
blockers: []
resurrection_packet:
  resume_from: Verify the initialized canonical state and compiler output.
  intended_first_move: Run the compiler and inspect .ai/LATEST_CONTEXT.md for correctness.
  rationale_summary: The highest-value next move is to prove the initialization and
    compilation loop end-to-end.
  files_likely_next:
  - .ai/memory/02_roadmap.md
  - .ai/memory/04_active_buffer.md
  - .ai/LATEST_CONTEXT.md
```

# Live Handoff State

This file is the shortest path back into the work.
Update it whenever the session focus changes, a blocker appears, or the next move becomes clearer.
