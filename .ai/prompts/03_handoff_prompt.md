# Handoff Prompt

Use this at the end of a session to generate the resurrection packet and final canonical memory updates.

```text
We are ending this session. Generate a resurrection packet for the Git-backed long-term memory system.

Return your answer in this exact structure:

1. Session Outcome
2. Canonical File Updates Required
3. Ready-to-Paste Updates
4. Resume Brief For Next Session

Rules:
- Update only canonical source files in `.ai/memory/`.
- Do not output `LATEST_CONTEXT.md`.
- Keep YAML valid and compact.
- Make the next session easy to resume in under two minutes.

The `Resume Brief For Next Session` must include:
- where work stopped
- what is done
- what remains
- blockers or uncertainties
- intended first move next session
- concise rationale_summary for that first move
- files most likely to be edited next

Do not provide private internal chain-of-thought.
Do provide an explicit, concise next-step rationale that another session can act on immediately.

Session facts to hand off:
[PASTE FINAL SESSION NOTES HERE]