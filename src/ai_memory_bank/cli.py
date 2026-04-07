from __future__ import annotations

from pathlib import Path
import platform
import sys

import typer
import yaml

from ai_memory_bank.compiler import compile_context, iter_memory_markdown_files, validate_yaml_front_matter
from ai_memory_bank.config import ensure_directories, find_repo_root, load_settings
from ai_memory_bank.git_ops import changed_files, current_branch, current_head, git_available
from ai_memory_bank.packets import apply_packet_text
from ai_memory_bank.prompts import (
    render_bootstrap_prompt,
    render_checkpoint_prompt,
    render_handoff_prompt,
    write_prompt,
)
from ai_memory_bank.templates import scaffold_files


app = typer.Typer(
    help="Git-backed long-term memory bank CLI for persistent AI development context.",
    no_args_is_help=True,
    add_completion=False,
    pretty_exceptions_enable=False,
)


def _load_settings(repo_root: Path | None = None):
    root = find_repo_root(repo_root)
    settings = load_settings(root)
    ensure_directories(settings)
    return settings


def _read_input(path: str) -> str:
    if path == "-":
        return sys.stdin.read()
    return Path(path).read_text(encoding="utf-8")


@app.command()
def init(
    overwrite: bool = typer.Option(False, help="Overwrite existing scaffold files."),
) -> None:
    settings = _load_settings()
    created = scaffold_files(settings, overwrite=overwrite)
    typer.secho(f"Initialized memory bank in {settings.paths.repo_root}", fg=typer.colors.GREEN)
    if created:
        for path in created:
            typer.echo(f"created  {path.relative_to(settings.paths.repo_root)}")
    else:
        typer.echo("No files created; scaffold already exists.")


@app.command()
def doctor() -> None:
    settings = _load_settings()
    repo_root = settings.paths.repo_root

    typer.echo(f"repo_root: {repo_root}")
    typer.echo(f"python: {platform.python_version()}")
    typer.echo(f"git_available: {git_available(repo_root)}")
    typer.echo(f"git_branch: {current_branch(repo_root) or 'unknown'}")
    typer.echo(f"git_head: {current_head(repo_root) or 'unknown'}")
    typer.echo(f"config_file: {settings.paths.config_file}")

    if settings.paths.config_file.exists():
        try:
            yaml.safe_load(settings.paths.config_file.read_text(encoding="utf-8"))
            typer.secho("config: OK", fg=typer.colors.GREEN)
        except Exception as exc:
            raise typer.Exit(str(exc))

    files = iter_memory_markdown_files(settings)
    if not files:
        typer.secho("No memory markdown files found.", fg=typer.colors.YELLOW)
        raise typer.Exit(code=1)

    typer.echo("memory files:")
    for file_path in files:
        try:
            validate_yaml_front_matter(file_path.read_text(encoding="utf-8"), file_path)
            typer.secho(f"  OK   {file_path.relative_to(repo_root)}", fg=typer.colors.GREEN)
        except Exception as exc:
            typer.secho(f"  FAIL {file_path.relative_to(repo_root)} :: {exc}", fg=typer.colors.RED)
            raise typer.Exit(code=1)


@app.command()
def compile(
    snapshot: bool = typer.Option(True, "--snapshot/--no-snapshot", help="Write a snapshot copy."),
) -> None:
    settings = _load_settings()
    result = compile_context(settings, snapshot=snapshot)
    typer.secho(f"Compiled context: {result.latest_context_file.relative_to(settings.paths.repo_root)}", fg=typer.colors.GREEN)
    if result.snapshot_file is not None:
        typer.echo(f"Snapshot: {result.snapshot_file.relative_to(settings.paths.repo_root)}")
    if result.archived_tasks:
        typer.echo("Archived completed tasks:")
        for task in result.archived_tasks:
            typer.echo(f"  {task}")


@app.command()
def start(
    fresh: bool = typer.Option(True, "--fresh/--no-fresh", help="Recompile context before generating the prompt."),
    print_prompt: bool = typer.Option(False, "--print", help="Print the prompt to stdout."),
) -> None:
    settings = _load_settings()
    if fresh or not settings.paths.latest_context_file.exists():
        compile_context(settings)
    latest = settings.paths.latest_context_file.read_text(encoding="utf-8")
    prompt = render_bootstrap_prompt(latest)
    prompt_path = write_prompt(settings, "BOOTSTRAP_PROMPT.md", prompt)
    typer.secho(f"Bootstrap prompt: {prompt_path.relative_to(settings.paths.repo_root)}", fg=typer.colors.GREEN)
    if print_prompt:
        typer.echo(prompt)


@app.command(name="checkpoint")
def checkpoint_command(
    print_prompt: bool = typer.Option(False, "--print", help="Print the prompt to stdout."),
) -> None:
    settings = _load_settings()
    prompt = render_checkpoint_prompt(settings)
    prompt_path = write_prompt(settings, "CHECKPOINT_PROMPT.md", prompt)
    typer.secho(f"Checkpoint prompt: {prompt_path.relative_to(settings.paths.repo_root)}", fg=typer.colors.GREEN)
    if print_prompt:
        typer.echo(prompt)


@app.command()
def handoff(
    print_prompt: bool = typer.Option(False, "--print", help="Print the prompt to stdout."),
) -> None:
    settings = _load_settings()
    prompt = render_handoff_prompt(settings)
    prompt_path = write_prompt(settings, "HANDOFF_PROMPT.md", prompt)
    typer.secho(f"Handoff prompt: {prompt_path.relative_to(settings.paths.repo_root)}", fg=typer.colors.GREEN)
    if print_prompt:
        typer.echo(prompt)


@app.command()
def apply(
    packet: str = typer.Argument(..., help="Path to the AI response packet file or '-' for stdin."),
    dry_run: bool = typer.Option(False, help="Validate and preview only; do not write files."),
    no_compile: bool = typer.Option(False, "--no-compile", help="Skip recompiling context after apply."),
    no_stage: bool = typer.Option(False, "--no-stage", help="Skip git add after apply."),
    commit_message: str | None = typer.Option(None, "--commit-message", help="Create a git commit after apply."),
) -> None:
    settings = _load_settings()
    packet_text = _read_input(packet)
    result = apply_packet_text(
        packet_text=packet_text,
        settings=settings,
        dry_run=dry_run,
        compile_after=not no_compile,
        stage_after=not no_stage,
        commit_message=commit_message,
    )

    if dry_run:
        typer.secho("Dry run succeeded.", fg=typer.colors.GREEN)
    else:
        typer.secho("Applied packet successfully.", fg=typer.colors.GREEN)

    typer.echo("written files:")
    for path in result.written_files:
        typer.echo(f"  {path.relative_to(settings.paths.repo_root)}")


@app.command()
def status() -> None:
    settings = _load_settings()
    typer.echo(f"repo_root: {settings.paths.repo_root}")
    typer.echo(f"latest_context: {settings.paths.latest_context_file}")
    typer.echo(f"prompt_dir: {settings.paths.prompt_dir}")
    typer.echo(f"git_branch: {current_branch(settings.paths.repo_root) or 'unknown'}")
    typer.echo(f"git_head: {current_head(settings.paths.repo_root) or 'unknown'}")

    if settings.paths.latest_context_file.exists():
        stat = settings.paths.latest_context_file.stat()
        typer.echo(f"latest_context_size: {stat.st_size} bytes")
    else:
        typer.secho("LATEST_CONTEXT.md does not exist yet.", fg=typer.colors.YELLOW)

    changes = changed_files(settings.paths.repo_root)
    if changes:
        typer.echo("git_changes:")
        for line in changes:
            typer.echo(f"  {line}")
    else:
        typer.secho("Working tree clean.", fg=typer.colors.GREEN)
