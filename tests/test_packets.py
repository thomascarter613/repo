from ai_memory_bank.config import ensure_directories, load_settings
from ai_memory_bank.packets import parse_packet_text


def test_parse_packet_text_extracts_files_and_monologue():
    packet = """=== FILE: .ai/memory/02_roadmap.md ===
---
current_phase: test
---

# Roadmap

=== FILE: .ai/memory/04_active_buffer.md ===
---
session_focus: test
---

# Active Buffer

=== INTERNAL_MONOLOGUE ===
Need to update the architecture doc next.
"""
    parsed = parse_packet_text(packet)
    assert ".ai/memory/02_roadmap.md" in parsed.files
    assert ".ai/memory/04_active_buffer.md" in parsed.files
    assert "Need to update the architecture doc next." in parsed.internal_monologue


def test_settings_load_from_repo(tmp_path, monkeypatch):
    (tmp_path / ".git").mkdir()
    monkeypatch.chdir(tmp_path)
    settings = load_settings()
    ensure_directories(settings)
    assert settings.paths.memory_dir.exists()
