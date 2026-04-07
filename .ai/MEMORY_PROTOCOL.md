# AI Memory Protocol

## What This Does

This repository stores long-term chat context as reviewable source files in `.ai/memory/`.
The compiler normalizes those files and emits `.ai/LATEST_CONTEXT.md`, which is the single bootstrap artifact for a new chat.

## Canonical Rule

- Canonical: `.ai/memory/*.md`
- Generated: `.ai/LATEST_CONTEXT.md`

## Local Use

```bash
python -m pip install pyyaml
python .ai/scripts/aggregate.py --session-id local-dev
```

## Editing Discipline

1. Update the source state files.
2. Run the compiler.
3. Commit both the source changes and the regenerated `.ai/LATEST_CONTEXT.md`.
4. Start the next chat from `LATEST_CONTEXT.md`.
