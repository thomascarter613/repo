---
kind: active_buffer
schema_version: 1
session:
  id: "__SESSION_ID__"
  started_at_utc: "__STARTED_AT_UTC__"
  operator_goal: "__INITIAL_OBJECTIVE__"
focus:
  current_problem: >-
    Need a reliable save-game mechanism for cross-session continuity in disconnected web chats.
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
    target: "__FIRST_ACTION_TARGET__"
    success_signal: The compiler exits zero and .ai/LATEST_CONTEXT.md is regenerated.
  - order: 2
    title: Confirm the workflow can commit generated updates.
    type: verify
    target: "__SECOND_ACTION_TARGET__"
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
  rationale_summary: >-
    The highest-value next move is to prove the initialization and compilation loop end-to-end.
  files_likely_next:
    - .ai/memory/02_roadmap.md
    - .ai/memory/04_active_buffer.md
    - .ai/LATEST_CONTEXT.md
---

# Live Handoff State

This file is the shortest path back into the work.
Update it whenever the session focus changes, a blocker appears, or the next move becomes clearer.
