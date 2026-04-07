from __future__ import annotations

from pathlib import Path

from ai_memory_bank.config import Settings


def _bundle_files(paths: list[Path], repo_root: Path) -> str:
    blocks: list[str] = []
    for path in paths:
        if not path.exists():
            continue
        relative = path.relative_to(repo_root).as_posix()
        content = path.read_text(encoding="utf-8").rstrip()
        blocks.append(f"=== FILE: {relative} ===\n{content}")
    return "\n\n".join(blocks).strip()


def render_bootstrap_prompt(latest_context: str) -> str:
    return f"""You are resuming a persistent AI state.

1. Ingest the full contents of LATEST_CONTEXT.md below.
2. Validate internal consistency:
   - Roadmap vs Active Buffer
   - Logic Map vs Current Task
3. Summarize:
   - Current objective
   - System state
   - Immediate next action
4. Identify any drift or contradictions.

DO NOT hallucinate missing context.

=== BEGIN CONTEXT ===
{latest_context.rstrip()}
=== END CONTEXT ===
"""


def render_checkpoint_prompt(settings: Settings) -> str:
    bundle = _bundle_files(
        [
            settings.memory.core_files[1],
            settings.memory.core_files[3],
        ],
        settings.paths.repo_root,
    )
    return f"""We are creating a checkpoint.

1. Update:
   - 02_roadmap.md (mark completed tasks)
   - 04_active_buffer.md (current state)

2. Ensure:
   - YAML is valid
   - No duplication
   - Clear, minimal wording

3. Output ONLY Git-ready files in this exact format:

=== FILE: .ai/memory/02_roadmap.md ===
<content>

=== FILE: .ai/memory/04_active_buffer.md ===
<content>

No explanations.

=== CURRENT FILES ===
{bundle}
=== END CURRENT FILES ===
"""


def render_handoff_prompt(settings: Settings) -> str:
    bundle = _bundle_files(list(settings.memory.core_files), settings.paths.repo_root)
    return f"""We are ending this session. Generate a resurrection packet.

1. Update ALL relevant memory files.
2. Write a forward-looking internal monologue:
   - What you were about to do next
   - Risks
   - Assumptions
3. Optimize for next-session fast boot.

Output exactly this shape:

=== FILE: .ai/memory/04_active_buffer.md ===
<final state>

=== FILE: .ai/memory/02_roadmap.md ===
<updated roadmap>

=== INTERNAL_MONOLOGUE ===
<deep reasoning summary about next steps>

STRICT:
- No fluff
- No broken YAML
- Actionable continuity only

=== CURRENT FILES ===
{bundle}
=== END CURRENT FILES ===
"""


def write_prompt(settings: Settings, name: str, content: str) -> Path:
    settings.paths.prompt_dir.mkdir(parents=True, exist_ok=True)
    path = settings.paths.prompt_dir / name
    path.write_text(content, encoding="utf-8")
    return path
