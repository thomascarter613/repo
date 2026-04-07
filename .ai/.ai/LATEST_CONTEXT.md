# LATEST_CONTEXT

```yaml
generated_at_utc: '2026-04-07T08:41:43Z'
session_id: local
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
  task_id_pattern: ^TASK-[0-9]{3,}$
  decision_id_pattern: ^ADR-[0-9]{3,}$
  branch_hint_pattern: feat/<topic> | fix/<topic> | docs/<topic>
```

# Project DNA

This file stores durable project identity, hard rules, and repository-level invariants.
Keep this file compact. Anything that changes often belongs in the roadmap or active buffer.

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
```

# Progress Ledger

Use the YAML task list as the canonical active queue.
Use the Markdown body for phase notes, release framing, and concise narrative context.

## .ai/memory/03_logic_map.md

```yaml
kind: logic_map
schema_version: 1
system_model:
  summary: The repository is the durable state machine. Source memory files are mutable
    state registers. The compiler is the reducer. The compiled context is the loadable
    save game.
  source_of_truth: .ai/memory/
  reducer: .ai/scripts/aggregate.py
  compiled_artifact: .ai/LATEST_CONTEXT.md
components:
- name: memory_source
  location: .ai/memory/
  responsibility: human-editable durable state
  outputs:
  - canonical memory files
- name: compiler
  location: .ai/scripts/aggregate.py
  responsibility: validation, pruning, normalization, context compilation
  inputs:
  - .ai/memory/*.md
  - .ai/schemas/*.json
  outputs:
  - .ai/LATEST_CONTEXT.md
  - .ai/memory/archive.log
- name: compiled_context
  location: .ai/LATEST_CONTEXT.md
  responsibility: single-file bootstrap artifact for new chats
- name: sync_workflow
  location: .github/workflows/sync.yml
  responsibility: automatic regeneration and commit-back
flows:
- trigger: user edits .ai/memory/*.md
  path:
  - validate front matter against JSON Schema
  - prune completed roadmap tasks
  - normalize content
  - compile .ai/LATEST_CONTEXT.md
  - commit generated updates
  outcome: repository save-state remains synchronized
- trigger: new chat starts
  path:
  - paste or attach .ai/LATEST_CONTEXT.md
  - run bootstrap prompt
  - verify state synchronization
  outcome: assistant resumes with current durable context
interfaces:
- name: canonical memory files
  type: file
  contract: Front matter must validate against the mapped schema file.
- name: context compiler
  type: script
  contract: Must fail closed on malformed YAML or schema violations.
- name: sync workflow
  type: workflow
  contract: Runs on memory changes, compiles state, and commits only generated outputs.
failure_modes:
- condition: malformed YAML front matter
  behavior: compilation aborts
  mitigation: fix the file and rerun the compiler
- condition: schema violation in nested fields
  behavior: compilation aborts with explicit path-oriented errors
  mitigation: correct the offending field to match the schema
invariants:
- LATEST_CONTEXT.md is generated and never canonical.
- Active work lives in roadmap and active_buffer.
- Completed work is archived and not kept in the active task window.
- Validation failures must stop compilation.
```

# Technical Mental Model

1. `.ai/memory/*.md` = mutable state registers.
2. `.ai/schemas/*.json` = machine-enforced contract.
3. `aggregate.py` = reducer + validator + compactor.
4. `.ai/LATEST_CONTEXT.md` = serialized load state.
5. Git history = audit log of memory evolution.

## .ai/memory/04_active_buffer.md

```yaml
kind: active_buffer
schema_version: 1
session:
  id: local-bootstrap
  started_at_utc: '2026-04-07T00:00:00Z'
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
  - .ai/schemas/01_global_context.schema.json
  - .ai/schemas/02_roadmap.schema.json
  - .ai/schemas/03_logic_map.schema.json
  - .ai/schemas/04_active_buffer.schema.json
  - .github/workflows/sync.yml
  recent_decisions:
  - Separate source memory from compiled artifact to avoid looped edits.
  - Use JSON Schema for strict nested validation.
  assumptions:
  - 'GitHub Actions will have contents: write permission enabled.'
next_actions:
- order: 1
  title: Run the compiler locally and confirm schema validation passes.
  type: verify
  target: .ai/scripts/aggregate.py
  success_signal: .ai/LATEST_CONTEXT.md is regenerated without validation errors.
- order: 2
  title: Push the scaffold and verify the GitHub Action auto-commits generated state.
  type: verify
  target: .github/workflows/sync.yml
  success_signal: Workflow run completes and pushes sync commit when needed.
- order: 3
  title: Begin using checkpoint and handoff prompts against the canonical memory files.
  type: document
  success_signal: New session updates are persisted cleanly through the schema engine.
risks:
- id: RISK-001
  title: Human edits may introduce invalid enum values or missing nested fields.
  severity: high
  mitigation: Fail closed through JSON Schema validation and fix the invalid front
    matter.
  status: open
- id: RISK-002
  title: Auto-commit loops could occur if generated artifacts trigger the workflow
    repeatedly.
  severity: medium
  mitigation: Keep generated artifacts outside the trigger paths and use bot-actor
    guard plus skip-ci.
  status: open
blockers: []
resurrection_packet:
  resume_from: Verify compiled output, prune behavior, and workflow automation end-to-end.
  intended_first_move: Run the compiler against the scaffold and inspect .ai/LATEST_CONTEXT.md.
  rationale_summary: End-to-end verification is the fastest way to prove that the
    schema contracts, pruning, and compiled save-state all work together before broader
    adoption.
  files_likely_next:
  - .ai/scripts/aggregate.py
  - .github/workflows/sync.yml
  - .ai/memory/02_roadmap.md
```

# Live Handoff State

This file is the fastest route back into the work.
Keep it current, lean, and practical.
