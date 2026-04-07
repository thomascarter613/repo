# Contributing

## Working Rules

- Use Bun only.
- Run `bun install` from repo root.
- Before commit, run:
  - `bun run lint`
  - `bun run typecheck`
  - `bun run test`

## Commit Shape

- Prefer atomic commits.
- Keep infra, formatting, and behavior changes separate when practical.
- Document meaningful architectural decisions in `docs/adr/`.

## Branch Naming

Recommended patterns:

- `feat/...`
- `fix/...`
- `chore/...`
- `docs/...`

## Pull Requests

PRs should explain:

- what changed
- why it changed
- any architectural consequence
- how it was verified
