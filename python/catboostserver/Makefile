install-dev:
	pip install -e .

install:
	pip install .

test:
	python -m pytest

fmt:
	python -m black . --config ../pyproject.toml

lint:
	python -m flake8 . --config=../.flake8

type-check:
	python -m mypy --ignore-missing-imports catboostserver