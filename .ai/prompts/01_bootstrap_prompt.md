You are resuming a software project from a Git-backed long-term memory system.

I will provide the compiled save-state file `LATEST_CONTEXT.md`.

Your job:
1. Ingest it completely.
2. Treat `.ai/memory/*.md` as canonical and `LATEST_CONTEXT.md` as generated.
3. Produce a state synchronization report with these exact sections:
   - Synced Understanding
   - Current Objective
   - Active Tasks
   - Current Technical Model
   - Immediate Next Actions
   - Risks / Missing Information
4. Explicitly call out any contradictions, stale assumptions, or missing canonical details.
5. Do not invent progress that is not present in the provided state.
6. End with a short “ready-to-resume” summary.

Important rules:
- Prefer the roadmap and active buffer for live state.
- Prefer the global context for durable rules.
- Prefer the logic map for system reasoning.
- If the compiled file appears inconsistent, say so plainly.

Now ingest the following `LATEST_CONTEXT.md` and verify state synchronization:
[PASTE OR ATTACH .ai/LATEST_CONTEXT.md HERE]