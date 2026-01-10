# Repository Guidelines for Agents

## Purpose
This repo is a Nix flake that packages ComfyUI plus curated custom nodes.
Use this file as the single source of truth for build, lint, test, and style
expectations when working in this repository.

## Project Structure & Module Organization
- `nix/`: flake helpers, package definitions, module, checks, and version pins.
- `src/custom_nodes/`: bundled custom nodes (Python and frontend assets).
- `src/patches/`: patches applied to upstream components.
- `docs/`: additional documentation (setup guides, etc.).
- `scripts/`: maintenance scripts (template inputs, Cachix, model downloads).
- `data/`: local runtime data for container examples and demos.

## Development Environment
- Use `nix develop` to enter the dev shell when running linting or formatting.
- The dev shell provides `ruff`, `pyright`, `nixfmt`, and `shellcheck`.
- Python runtime target is 3.12 (see `pyproject.toml`).

## Build, Lint, Format, and Test Commands
### Core Nix commands
- `nix build`: build the default package without running it.
- `nix run`: run ComfyUI (add `-- --open`, `--port=XXXX`, `--listen 0.0.0.0`).
- `nix run .#cuda`: CUDA build on Linux/NVIDIA only.
- `nix flake check`: run all checks (build, ruff, pyright, nixfmt, shellcheck).
- `nix fmt`: format Nix files with `nixfmt-rfc-style`.
- `nix run .#update`: check for ComfyUI version updates.
- `nix run .#buildDocker`: build CPU Docker image.
- `nix run .#buildDockerCuda`: build CUDA Docker image.

### Python linting and formatting
- `ruff check src/`: run linting on all Python sources.
- `ruff check src/path/to/file.py`: lint a single Python file.
- `ruff format src/`: format Python sources.
- `ruff format src/path/to/file.py`: format a single Python file.

### Python type checking
- `pyright src/`: run type checks for the source tree.
- `pyright src/path/to/file.py`: run type checks on a single Python file.

### Shell scripting
- `shellcheck scripts/*.sh`: lint shell scripts.
- `shellcheck scripts/path/to/script.sh`: lint a single script.

### Tests
- There are no unit-test suites in this repo today.
- The primary quality gate is `nix flake check`.
- If tests are added in the future, prefer `pytest path/to/test.py::test_name`
  for a single test and `pytest path/to/test.py` for a single file.

## Coding Style & Conventions
### Python formatting
- Python is formatted with `ruff format`.
- Use 4-space indentation and a 100-character line length.
- Use double quotes for strings unless escaping makes it noisy.
- Prefer trailing commas in multi-line collections.

### Imports
- Order imports as standard library, third-party, then local.
- Ruff enforces import ordering (isort).
- Avoid unused imports except in `__init__.py` where they are allowed.
- Star imports are allowed only in `src/custom_nodes/**` modules.

### Naming
- `snake_case` for functions, modules, variables.
- `PascalCase` for classes.
- `UPPER_SNAKE_CASE` for constants.
- Avoid single-letter variable names unless the context is obvious.

### Types
- Python version is 3.12 (`pyright` configured accordingly).
- Type checking mode is `basic`; be pragmatic with annotations.
- Add type hints to new public functions and key data structures.
- Prefer `typing` (e.g., `Iterable`, `Mapping`, `Sequence`) over concrete
  container types in APIs.
- Use `typing.cast` only when necessary and document intent.
- Use `from __future__ import annotations` when it improves readability.

### Docstrings
- Google-style docstrings are preferred.
- Document public functions and classes when behavior is non-obvious.
- Keep docstrings concise and action-oriented.

### Error handling
- Raise specific exceptions with actionable messages.
- Preserve context by chaining (`raise ... from err`) when wrapping errors.
- Avoid bare `except:`; catch explicit exception types.
- It is acceptable to use `print` for status updates (ComfyUI convention).

### Filesystem usage
- `os.path` is acceptable (the repo does not mandate `pathlib`).
- Prefer `pathlib.Path` only when it improves clarity or APIs require it.
- Avoid writing outside the repo unless required by a script.

### Performance and readability
- Keep functions small and focused.
- Avoid deeply nested conditionals; early returns are encouraged.
- Prefer comprehensions when they remain readable.
- Do not micro-optimize unless it is on a hot path.

## Repo-Specific Ruff and Pyright Notes
- Ruff targets Python 3.12 with 100-character lines.
- Ruff ignores `T20` (print statements) and `G004` (f-strings in logging).
- Ruff allows unused imports in `__init__.py` and star imports in
  `src/custom_nodes/**`.
- Ruff complexity guard: `max-complexity = 15` (McCabe).
- Pyright uses `basic` type checking with lenient missing import handling.
- Pyright is configured to warn (not fail) on missing imports.
- Pyright uses `typings/` as the stub path when available.

## Nix Style
- Format Nix files with `nix fmt`.
- Keep attrsets aligned and avoid reformatting unrelated sections.
- Prefer existing patterns in `nix/` for adding new derivations.

## Shell Style
- Shell scripts should pass `shellcheck`.
- Prefer `set -euo pipefail` for new scripts when appropriate.
- Avoid bashisms if the script might be invoked by `sh`.
- Keep scripts small and focused; prefer helpers in `scripts/`.

## Cursor and Copilot Rules
- No `.cursorrules` or `.cursor/rules/` found in this repo.
- No `.github/copilot-instructions.md` found in this repo.

## Commit & Pull Request Guidelines
- Commit style follows a conventional prefix, e.g. `docs: ...`, `ci: ...`,
  `refactor: ...`.
- Keep commit messages short and specific to the change.
- PRs should include a concise description, linked issues if applicable, and
  the checks run (e.g. `nix flake check`, `nix build`).

## Agent-Specific Instructions
- After any file edits, run `git add` so the flake can see changes correctly.
- Do not create commits unless explicitly requested.
