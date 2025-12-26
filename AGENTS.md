# Repository Guidelines

## Project Structure & Module Organization
This repo is a Nix flake that packages ComfyUI plus curated custom nodes.
- `nix/`: flake helpers, package definitions, module, checks, and version pins.
- `src/custom_nodes/`: bundled custom nodes (Python and frontend assets).
- `src/patches/`: patches applied to upstream components.
- `docs/`: additional documentation (setup guides, etc.).
- `scripts/`: maintenance scripts (template inputs, Cachix, model downloads).
- `data/`: local runtime data for container examples and demos.

## Build, Test, and Development Commands
- `nix run`: run ComfyUI (add `-- --open`, `--port=XXXX`, `--listen 0.0.0.0` as needed).
- `nix run .#cuda`: CUDA build on Linux/NVIDIA; use only when GPU support is required.
- `nix build`: build the default package without running it.
- `nix develop`: enter the dev shell with `ruff`, `pyright`, and `nixfmt`.
- `nix flake check`: run all checks (build, ruff, pyright, nixfmt, shellcheck).
- `nix fmt`: format Nix files with `nixfmt-rfc-style`.
- `nix run .#update`: check for ComfyUI version updates.
- `nix run .#buildDocker` / `nix run .#buildDockerCuda`: build CPU/CUDA images locally.

## Coding Style & Naming Conventions
- Python: 4-space indentation, 100-char lines, double quotes (`ruff format`).
- Imports: standard library, third-party, then local; `ruff` enforces ordering.
- Naming: `snake_case` for functions/vars, `PascalCase` for classes.
- Nix: format with `nix fmt` (nixfmt RFC style).
- Shell: scripts in `scripts/` should pass `shellcheck`.

## Testing Guidelines
There are no unit-test suites in the repo today. Quality gates are:
- `nix flake check` (ruff + pyright + nixfmt + shellcheck).
- Optional manual runs: `ruff check src/` and `pyright src/` inside `nix develop`.

## Commit & Pull Request Guidelines
- Commit style follows a conventional prefix, e.g. `docs: ...`, `ci: ...`, `refactor: ...`.
- Keep messages short and specific to the change.
- PRs should include a concise description, linked issues if applicable, and the checks run
  (e.g. `nix flake check` or relevant `nix run`/`nix build` commands).

## Agent-Specific Instructions
- After any file edits, run `git add` so the flake can see changes correctly.
- Do not create commits unless explicitly requested.
