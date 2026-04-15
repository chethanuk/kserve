.PHONY: dev_install install_dependencies test type_check fmt lint

dev_install:
	uv sync --group test

install_dependencies:
	uv sync --group test

test: type_check
	pytest -W ignore

type_check:
	mypy --ignore-missing-imports catboostserver

fmt:
	python -m ruff format .

lint:
	python -m ruff check .
