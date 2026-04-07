---
kind: logic_map
schema_version: 1
system_model:
  summary: >-
    The repository is the durable state machine. Source memory files are the mutable
    state registers. The compiler is the reducer. The compiled context is the loadable save game.
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
    contract: Each core memory file must have valid YAML front matter and match its schema.
  - name: context_compiler
    type: script
    contract: Fails closed on malformed YAML or schema violations and regenerates compiled context.
  - name: sync_workflow
    type: workflow
    contract: Rebuilds compiled context on state changes and commits only when generated files differ.
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
---

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
