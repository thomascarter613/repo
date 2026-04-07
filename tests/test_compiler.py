from ai_memory_bank.compiler import compile_context
from ai_memory_bank.config import ensure_directories, load_settings
from ai_memory_bank.templates import scaffold_files


def test_compile_context_writes_latest_context(tmp_path, monkeypatch):
    (tmp_path / ".git").mkdir()
    monkeypatch.chdir(tmp_path)

    settings = load_settings()
    ensure_directories(settings)
    scaffold_files(settings)

    result = compile_context(settings, snapshot=False)

    assert result.latest_context_file.exists()
    content = result.latest_context_file.read_text(encoding="utf-8")
    assert "session_id:" in content
    assert "# FILE: .ai/memory/01_global_context.md" in content
