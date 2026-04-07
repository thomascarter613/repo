# AI Memory Bank CLI

Git-backed long-term memory bank tooling for persistent AI development context.

## Commands

- `ai-sync init`
- `ai-sync doctor`
- `ai-sync compile`
- `ai-sync start`
- `ai-sync checkpoint`
- `ai-sync handoff`
- `ai-sync apply <packet-file>`
- `ai-sync status`

## Install

```bash
python -m pip install -e ".[dev]"
pre-commit install --hook-type pre-commit --hook-type pre-push
pre-commit run --all-files
```

## What the automation layer does

- validates YAML and repo hygiene locally with `pre-commit`
- recompiles `LATEST_CONTEXT.md` before commit
- runs tests before push
- recompiles and commits memory snapshots automatically on pushes to `.ai/memory/**`

## Generated vs committed files

Committed:
- `.ai/memory/**`
- `.ai/compiled/LATEST_CONTEXT.md`
- `.ai/compiled/snapshots/**`
- `.ai/memory/archive.log`

Generated and ignored:
- `.ai/runtime/**`
- Python and test caches
