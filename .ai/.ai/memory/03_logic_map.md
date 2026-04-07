---
kind: logic_map
schema_version: 1
system_model:
  summary: >-
    The repository is the durable state machine. Source memory files are mutable state
    registers. The compiler is the reducer. The compiled context is the loadable save game.
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
---

# Technical Mental Model

1. `.ai/memory/*.md` = mutable state registers.
2. `.ai/schemas/*.json` = machine-enforced contract.
3. `aggregate.py` = reducer + validator + compactor.
4. `.ai/LATEST_CONTEXT.md` = serialized load state.
5. Git history = audit log of memory evolution.
