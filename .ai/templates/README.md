# Memory Templates

These files are blueprints used by `.ai/scripts/init_memory_bank.py` to create canonical seed state.

## Rules

- Templates are not live state.
- Do not edit templates to record project progress.
- Edit `.ai/memory/*.md` for live project state.
- Re-run the initializer with `--force` only when you intentionally want to reset canonical memory.

## Supported Tokens

- `__PROJECT_NAME__`
- `__CODE_NAME__`
- `__REPO_ROLE__`
- `__CURRENT_PHASE__`
- `__INITIAL_OBJECTIVE__`
- `__SESSION_ID__`
- `__STARTED_AT_UTC__`
- `__FIRST_ACTION_TARGET__`
- `__SECOND_ACTION_TARGET__`
