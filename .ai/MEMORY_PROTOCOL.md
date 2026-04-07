# Memory Bank Protocol

## Purpose

This repository uses a Git-backed long-term memory bank so work can resume across disconnected chat sessions without relying on browser chat history.

## Canonical Rule

- Edit canonical state only in `.ai/memory/`.
- Do not hand-edit `.ai/LATEST_CONTEXT.md`.
- Use `.ai/prompts/` to operate the memory bank.
- Use `.ai/templates/` only as blueprints, not as live state.

## One-Time Bootstrap

Initialize canonical seed state:

```bash
make init INIT_ARGS='--project-name "Your Project Name"'
```

Or, if you prefer `just`:

```bash
just init --project-name "Your Project Name"
```

Then validate and compile:

```bash
make validate
make compile SESSION_ID=bootstrap
```

## Daily Flow

1. Start a new chat with `.ai/prompts/01_bootstrap_prompt.md`
2. Use `.ai/prompts/02_checkpoint_prompt.md` at milestones
3. Run `make checkpoint SESSION_ID=<session-id>` to validate and rebuild context locally
4. End with `.ai/prompts/03_handoff_prompt.md`
5. Commit the updated `.ai/memory/` files plus generated state
6. Let the workflow regenerate `.ai/LATEST_CONTEXT.md` on future pushes

## One-Command Operations

The dependency bootstrap is intentionally defensive: it repairs or bootstraps `pip` with `ensurepip` before installing packages, which helps recover broken virtual environments.

```bash
make deps
make init INIT_ARGS='--project-name "Your Project Name" --current-phase foundation'
make validate
make compile SESSION_ID=my-session
make checkpoint SESSION_ID=my-session
```

Optional `just` equivalents:

```bash
just deps
just init --project-name "Your Project Name"
just validate
just compile my-session
just checkpoint my-session
```

## Validation Contract

- YAML front matter must remain valid
- JSON Schema validation must pass
- Semantic validation must pass for task IDs, dependency references, action ordering, and unique IDs
- Completed roadmap tasks are archived automatically during compile
- A malformed handoff fails closed
