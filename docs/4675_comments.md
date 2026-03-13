# PR #4675 Review Comments — Add CatBoost Model Serving Support

PR: https://github.com/kserve/kserve/pull/4675
Author: chethanuk | Created: 2025-09-06 | Last Updated: 2026-03-09 | Status: Open

---

## General Discussion Comments (8 total)

### 1. spolti — 2025-09-16
Aren't these two related https://github.com/kserve/kserve/pull/4603?

### 2. chethanuk — 2025-09-16
Yes both are trying to solve same thing

### 3. spolti — 2025-09-22
Hi @kittywaresz, can you please work together with @chethanuk seems both PRs are related?

### 4. kittywaresz — 2025-09-22
Asks whether a separate CatBoost runtime is needed or if adding support to MLServer would suffice.

### 5. chethanuk — 2025-09-23 (#issuecomment-3325693198)
We should have a *Separate CatBoost Runtime*. Rationale:
1. File Format Handling: CatBoost has unique .cbm preference logic
2. Multi-Model File Discovery: CatBoost's flexible file handling differs from strict single-file frameworks
3. Container Resource & Security: OpenMP threading needs specific CPU affinity
4. Protocol Support: MLServer only supports v2; CatBoost runtime supports v1 + v2
5. Threading Model: CatBoost uses OpenMP, not the generic MLServer threading model
6. Performance tuning: separate runtime allows CatBoost-specific loading strategies
7. Every major ML framework has dedicated runtime; CatBoost should too

### 6. kittywaresz — 2025-09-29
Agrees to close their PR, offers documentation help.

### 7. chethanuk — 2026-02-24
Requests merger review from team.

### 8. sivanantha321 — 2026-02-26
Please resolve conflicts and address review comments.

---

## Inline Review Comments (31 total)

### python/catboost.Dockerfile

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 31 | kittywaresz | 2025-10-27 | Suggested correcting incomplete COPY command: `COPY storage storage` |
| 36 | kittywaresz | 2025-10-27 | Use `uv sync --active --no-cache` for consistency with other Dockerfiles |
| 36 | sivanantha321 | 2026-02-26 | `agreed` |
| 38 | kittywaresz | 2025-10-27 | Use `uv sync --active --no-cache` for consistency |
| 43 | spolti | 2026-03-09 | "python 3.11 is already in use, so, can it be removed?" (TODO comment) |
| 71 | kittywaresz | 2025-10-27 | Add blank line after ENTRYPOINT for consistency |

### python/catboostserver/README.md

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 8 | kittywaresz | 2025-10-27 | Use `uv venv` and `uv run --active` — "more developer friendly" |

### python/catboostserver/catboostserver/__init__.py

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 1 | spolti | 2026-03-09 | Update to `# Copyright 2026 The KServe Authors.` |

### python/catboostserver/catboostserver/__main__.py

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 1 | spolti | 2026-03-09 | Update to `# Copyright 2026 The KServe Authors.` |
| 24 | sivanantha321 | 2026-02-26 | "where is this used?" — `DEFAULT_LOCAL_MODEL_DIR` is unused |

### python/catboostserver/catboostserver/model.py

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 1 | spolti | 2026-03-09 | Update to `# Copyright 2026 The KServe Authors.` |
| 26 | spolti | 2026-03-09 | ".bin is a generic extension, what would happen if unsupported bin is used?" |

### python/catboostserver/catboostserver/catboost_model_repository.py

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 1 | sivanantha321 | 2026-02-26 | Update copyright year to 2026 |
| 1 | spolti | 2026-03-09 | Update to `# Copyright 2026 The KServe Authors.` |
| 36 | spolti | 2026-03-09 | "can we log the exception here?" |

### python/catboostserver/catboostserver/test_catboost_model_repository.py

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 1 | spolti | 2026-03-09 | Update to `# Copyright 2026 The KServe Authors.` |

### python/catboostserver/catboostserver/test_model.py

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 1 | spolti | 2026-03-09 | Update to `# Copyright 2026 The KServe Authors.` |

### python/catboostserver/pyproject.toml

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 13 | sivanantha321 | 2026-02-26 | Bump version to 0.16.0 (we will use 0.17.0rc1 to match upstream) |
| 19 | sivanantha321 | 2026-02-26 | "is this needed for test?" — scikit-learn not directly imported in tests |
| 27 | sivanantha321 | 2026-02-26 | "we migrated to ruff now" — remove black, add ruff |

### python/catboostserver/Makefile

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 16 | spolti | 2026-03-09 | "the default linter is ruff, please upgrade" |

### python/kserve/test/test_v1beta1_cat_boost_spec.py

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 1 | spolti | 2026-03-09 | Update to `# Copyright 2026 The KServe Authors.` |

### test/e2e/predictor/test_catboost.py

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 1 | spolti | 2026-03-09 | "missing first line" — add copyright header |
| 46 | chethanuk | 2025-09-29 | "@spolti @yuzisun This needs to be manually uploaded" (GCS model) |

### docs/samples/v1beta1/catboost/catboost.yaml

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 8 | sivanantha321 | 2026-02-26 | "Is this model available in gcs?" |
| 8 | chethanuk | 2026-02-27 | "No we need to upload" (deferred per plan decision) |

### pkg/constants/catboost.go

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 1 | sivanantha321 | 2026-02-26 | "do we need separate file for this?" |
| 1 | chethanuk | 2026-02-27 | "I think yes - need to check why I designed like that" |
| 2 | spolti | 2026-03-09 | Update copyright to 2026 |
| 22 | spolti | 2026-03-09 | "Is this being used?" (constants are unused — decision: delete file) |

### pkg/apis/serving/v1beta1/predictor_catboost.go

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 2 | spolti | 2026-03-09 | Update copyright to 2026 |

### pkg/apis/serving/v1beta1/predictor_catboost_test.go

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 2 | spolti | 2026-03-09 | Update copyright to 2026 |

### .github/workflows/catboostserver-docker-publisher.yml

| Line | Author | Date | Comment |
|------|--------|------|---------|
| 14 | sivanantha321 | 2026-02-26 | Add path filters matching xgbserver-docker-publisher.yml |

---

## Resolution Summary

| Comment | Status | Decision |
|---------|--------|----------|
| Copyright 2021→2026 (11 files) | TODO | Update all |
| Dockerfile: uv sync pattern | TODO | Align with xgb.Dockerfile |
| Dockerfile: remove Python 3.11 TODO | TODO | Remove |
| Dockerfile: blank line after ENTRYPOINT | TODO | Add |
| README: uv venv/run | TODO | Update |
| model.py: drop .bin | TODO | Only .cbm |
| catboost_model_repository.py: log exceptions | TODO | Add logger.exception |
| __main__.py: remove DEFAULT_LOCAL_MODEL_DIR | TODO | Remove |
| pyproject.toml: version | TODO | 0.17.0rc1 |
| pyproject.toml: remove scikit-learn | TODO | Remove |
| pyproject.toml: ruff, remove black | TODO | Replace |
| Makefile: ruff | TODO | Replace flake8/black |
| CI workflow: path filters | TODO | Add |
| pkg/constants/catboost.go | TODO | Delete; add CatBoostServer to constants.go |
| GCS model upload | DEFERRED | Out of scope |
