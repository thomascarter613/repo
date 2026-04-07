# Memory Protocol

## Canonical Rule

Edit only the source files under `.ai/memory/`.
Do not hand-edit `.ai/LATEST_CONTEXT.md`.

## Validation Rule

All core memory files must contain valid YAML front matter that satisfies the matching JSON Schema in `.ai/schemas/`.

## Compile Command

```bash
python .ai/scripts/aggregate.py
```

## Failure Policy

If the compiler reports malformed YAML or a schema violation, fix the offending source file before continuing.
