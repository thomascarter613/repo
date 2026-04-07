set shell := ["bash", "-cu"]

default:
    @just --list

deps:
    python3 -m ensurepip --upgrade
    python3 -m pip install --upgrade --force-reinstall pip
    python3 -m pip install --upgrade pyyaml jsonschema

init *args:
    python3 .ai/scripts/init_memory_bank.py {{args}}

validate:
    python3 .ai/scripts/validate_memory_bank.py

compile session_id="local":
    SESSION_ID="{{session_id}}" python3 .ai/scripts/aggregate.py

checkpoint session_id="local":
    python3 .ai/scripts/checkpoint_memory.py --session-id "{{session_id}}"

sync session_id="local":
    python3 .ai/scripts/checkpoint_memory.py --session-id "{{session_id}}"
