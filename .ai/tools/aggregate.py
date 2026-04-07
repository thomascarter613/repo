from ai_memory_bank.compiler import compile_context
from ai_memory_bank.config import ensure_directories, load_settings


def main() -> None:
    settings = load_settings()
    ensure_directories(settings)
    compile_context(settings)


if __name__ == "__main__":
    main()
