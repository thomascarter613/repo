#!/usr/bin/env python3
"""Validate canonical memory files without mutating repository state."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from aggregate import MemoryValidationError, SchemaEngine, ensure_required_files, parse_memory_file


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate the repository memory bank.")
    parser.add_argument("--memory-root", default=".ai/memory", help="Directory containing canonical memory files.")
    parser.add_argument("--schema-root", default=".ai/schemas", help="Directory containing JSON Schema files.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    memory_root = Path(args.memory_root).resolve()
    schema_root = Path(args.schema_root).resolve()

    if not memory_root.exists():
        raise SystemExit(f"Memory root not found: {memory_root}")
    if not schema_root.exists():
        raise SystemExit(f"Schema root not found: {schema_root}")

    schema_engine = SchemaEngine(schema_root=schema_root)
    ensure_required_files(memory_root)

    files_validated = 0
    for path in sorted(memory_root.glob("*.md")):
        if path.name.startswith("."):
            continue
        parse_memory_file(path=path, schema_engine=schema_engine)
        files_validated += 1

    print("Memory bank validation passed.")
    print(f"Files validated: {files_validated}")
    print(f"Schema files loaded: {schema_engine.schema_count}")
    print(f"Strict schema validations executed: {schema_engine.strict_validation_count}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except MemoryValidationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
