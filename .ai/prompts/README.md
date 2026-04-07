# AI Prompt Set

This directory contains the operational prompts used to interact with the Git-backed memory bank.

## Files

- `01_bootstrap_prompt.md` — start a new chat and rehydrate context from `.ai/LATEST_CONTEXT.md`
- `02_checkpoint_prompt.md` — capture a milestone during a session as Git-ready canonical memory updates
- `03_handoff_prompt.md` — end a session with a resurrection packet and next-session resume state

## Usage Order

1. Start a new chat and use `01_bootstrap_prompt.md`
2. During work, use `02_checkpoint_prompt.md` whenever a meaningful milestone is reached
3. Before leaving the session, use `03_handoff_prompt.md`

## Canonical Rule

These prompt files are operational tooling, not project state.
Do not place them in `.ai/memory/`.
Do not treat them as canonical memory.

## Input Sources

- Bootstrap reads from `.ai/LATEST_CONTEXT.md`
- Checkpoint and handoff prompts should be fed concise notes from the current session
- Generated updates should target only `.ai/memory/*.md`

## Output Rules

- Keep YAML front matter valid
- Do not hand-edit `.ai/LATEST_CONTEXT.md`
- Let `.ai/scripts/aggregate.py` regenerate compiled context