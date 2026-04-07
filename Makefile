SHELL := /bin/bash
PYTHON ?= python3
SESSION_ID ?= local

.PHONY: help deps init validate compile checkpoint sync

help:
	@echo "Memory bank commands:"
	@echo "  make deps"
	@echo "  make init INIT_ARGS='--project-name \"Your Project\"'"
	@echo "  make validate"
	@echo "  make compile SESSION_ID=my-session"
	@echo "  make checkpoint SESSION_ID=my-session"
	@echo "  make sync SESSION_ID=my-session"

deps:
	$(PYTHON) -m ensurepip --upgrade
	$(PYTHON) -m pip install --upgrade --force-reinstall pip
	$(PYTHON) -m pip install --upgrade pyyaml jsonschema

init:
	$(PYTHON) .ai/scripts/init_memory_bank.py $(INIT_ARGS)

validate:
	$(PYTHON) .ai/scripts/validate_memory_bank.py

compile:
	SESSION_ID="$(SESSION_ID)" $(PYTHON) .ai/scripts/aggregate.py

checkpoint:
	$(PYTHON) .ai/scripts/checkpoint_memory.py --session-id "$(SESSION_ID)"

sync: checkpoint
