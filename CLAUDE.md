# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## IMPORTANT WORKFLOW RULES

**ALWAYS run `git add` after making file changes!** The Nix flake requires this for proper operation.
**NEVER commit changes unless explicitly requested by the user.**

## Build/Run Commands

- **Run application**: `nix run` (default)
- **Run with browser**: `nix run -- --open` (automatically opens browser)
- **Run with CUDA**: `nix run .#cuda` (Linux/NVIDIA only, uses pre-built PyTorch CUDA wheels)
- **Run with custom port**: `nix run -- --port=8080`
- **Run with network access**: `nix run -- --listen 0.0.0.0`
- **Run with debug logging**: `nix run -- --debug` or `nix run -- --verbose`
- **Build with Nix**: `nix build`
- **Check for updates**: `nix run .#update` (shows latest ComfyUI version and update instructions)
- **Develop with Nix**: `nix develop` (provides ruff, pyright, nixfmt, shellcheck)

### Docker Commands

- **Build Docker image**: `nix run .#buildDocker` (creates `comfy-ui:latest`)
- **Build CUDA Docker**: `nix run .#buildDockerCuda` (creates `comfy-ui:cuda`)
- **Cross-build Linux images from macOS**: `nix run .#buildDockerLinux`, `nix run .#buildDockerLinuxCuda`, `nix run .#buildDockerLinuxArm64`
- **Pull pre-built**: `docker pull ghcr.io/utensils/comfyui-nix:latest` (or `:latest-cuda`)
- **Run container**: `docker run -p 8188:8188 -v $PWD/data:/data comfy-ui:latest`
- **Run CUDA container**: `docker run --gpus all -p 8188:8188 -v $PWD/data:/data comfy-ui:cuda`

## Linting and Code Quality

- **Run all checks**: `nix flake check` — this is the quality gate (there are no unit tests)
- **Individual checks run by `nix flake check`**:
  - `ruff-check`: Lint Python with ruff (`ruff check --no-cache src/`)
  - `pyright-check`: Type-check Python with pyright
  - `nixfmt`: Verify Nix formatting (nixfmt-rfc-style)
  - `shellcheck`: Lint shell scripts in `scripts/`
  - `package`: Full build of the default package
- **Manual linting in dev shell** (`nix develop`):
  - `ruff check src/` — lint Python (or `ruff check src/path/to/file.py` for a single file)
  - `ruff format src/` — format Python (or `ruff format src/path/to/file.py`)
  - `pyright src/` — type-check Python (or `pyright src/path/to/file.py`)
  - `shellcheck scripts/*.sh` — lint shell scripts (or `shellcheck scripts/path/to/script.sh`)
  - `nix fmt` — format Nix files

## Version Management

- Current ComfyUI version: v0.12.2 (pinned in `nix/versions.nix`)
- To update ComfyUI: modify `version`, `rev`, and `hash` in `nix/versions.nix`
- Vendored wheels (spandrel, frontend, docs, etc.) also pinned in `nix/versions.nix`
- Template input files: auto-generated in `nix/template-inputs.nix`
  - Update with: `./scripts/update-template-inputs.sh && git add nix/template-inputs.nix`
- Python version: 3.12
- PyTorch: macOS uses pre-built wheels (2.5.1, pinned to work around MPS bugs on macOS 26); CUDA uses pre-built wheels from pytorch.org (cu124); Linux CPU uses nixpkgs

## Project Architecture

### Directory Structure

- **src/custom_nodes/**: Bundled custom node extensions (model_downloader, etc.)
- **src/patches/**: Patches applied to dependencies
- **nix/**: Flake modules and helpers
  - **versions.nix**: All version pins (ComfyUI, vendored wheels, custom nodes, PyTorch wheels)
  - **packages.nix**: Package definitions and the inline launcher script (`writeShellApplication`)
  - **python-overrides.nix**: Python package overrides (platform-specific PyTorch, dependency fixes)
  - **template-inputs.nix**: Pre-fetched template input files (auto-generated, do not edit manually)
  - **apps.nix**: Flake app definitions (run, update, Docker build commands)
  - **docker.nix**: Docker image builders
  - **checks.nix**: CI check definitions (ruff, pyright, nixfmt, shellcheck)
  - **modules/comfyui.nix**: NixOS service module with declarative custom nodes
  - **lib/custom-nodes.nix**: Helper functions for custom node management
- **scripts/**: Maintenance scripts (update-template-inputs.sh, push-to-cachix.sh, download-pulid-models.sh)

### Key Components

**Launcher Script** (`nix/packages.nix` — defined inline via `writeShellApplication`):
The launcher does significant work beyond just starting ComfyUI:

- Creates data directory structure and subdirectories on first run
- Symlinks bundled custom nodes and template input files into the data directory
- Sets up a PEP 405 venv at `<data-dir>/.venv` for ComfyUI-Manager package installs
- Writes `sitecustomize.py` to control Nix vs venv package precedence
- Patches custom nodes that have hardcoded paths (fonts, read-only store workarounds)
- Removes Linux-only nodes on macOS (e.g., bitsandbytes_NF4)
- Creates default ComfyUI-Manager config at `<data-dir>/user/__manager/config.ini`
- Increases file descriptor limit to 10240 (macOS default is 256, too low for Manager)
- Redirects model/cache paths via environment variables to keep data directory organized
- Runs ComfyUI from the Nix store with `--base-directory` and `--front-end-root`

**Environment variables set by launcher** (important for debugging):

- `COMFYUI_BASE_DIR`, `COMFYUI_MODEL_PATH` — prevent custom nodes from writing to Nix store
- `TORCH_HOME`, `HF_HOME`, `FACEXLIB_MODELPATH` — redirect cache/model downloads into data dir
- `VIRTUAL_ENV`, `PIP_TARGET` — for Manager package installs into `.venv`
- `COMFY_VENV_PRECEDENCE` — set to `prefer-venv` to let venv packages override Nix packages (default: Nix takes precedence)
- `LD_LIBRARY_PATH` (Linux) / `DYLD_LIBRARY_PATH` (macOS) — set automatically for system libraries

**Model Downloader** (`src/custom_nodes/model_downloader/`):
Non-blocking async download system using aiohttp with WebSocket progress updates.

- API endpoints: `POST /api/download_model`, `GET /api/download_progress/{id}`, `GET /api/list_downloads`
- Supports HuggingFace auth headers for gated models

**Template Input Files**: Pre-fetched at Nix build time with pinned hashes, symlinked to user's input directory on startup. Update with `./scripts/update-template-inputs.sh`.

### Data Persistence Structure

All data stored in the configurable base directory:

- **Linux**: `~/.config/comfy-ui/` (XDG)
- **macOS**: `~/Library/Application Support/comfy-ui/`

```text
models/        - Model files (checkpoints, loras, vae, controlnet, embeddings, etc.)
output/        - Generated images and outputs
input/         - Input files for processing
user/          - User configuration, workflows, Manager config
custom_nodes/  - Custom node installations (bundled nodes auto-linked here)
temp/          - Temporary files
fonts/         - Bundled fonts for nodes requiring system fonts
.venv/         - PEP 405 venv for ComfyUI-Manager package installs
.cache/        - Redirected caches (torch hub, HuggingFace, facexlib)
```

### Platform-Specific Notes

- macOS: PyTorch pinned to 2.5.1 to work around MPS bugs on macOS 26 (Tahoe); browser opens via `/usr/bin/open`
- CUDA: Pre-built wheels from pytorch.org with CUDA 12.4 runtime bundled (no separate toolkit needed); supports Pascal through Hopper
- Linux CPU: Uses nixpkgs PyTorch; browser opens via `xdg-open`
- Cross-platform Docker builds work from any system via `nix run .#buildDockerLinux` etc.

## CI/CD and Automation

### GitHub Actions Workflows

**Docker Image Publishing** (`.github/workflows/build.yml`):

- Triggers: push to main, version tags (v*), pull requests
- CPU images: multi-arch (amd64 + arm64 via QEMU)
- CUDA images: x86_64 only
- Published to `ghcr.io/utensils/comfyui-nix` (`:latest`, `:latest-cuda`, `:X.Y.Z`)

**Claude Code Integration** (`.github/workflows/claude.yml`, `.github/workflows/claude-code-review.yml`):

- AI-assisted code review and issue responses via @claude mentions

### Required Secrets

- `CLAUDE_CODE_OAUTH_TOKEN`: Claude Code GitHub integration
- `CACHIX_AUTH_TOKEN`: Publishing to Cachix binary cache
- `GITHUB_TOKEN`: Automatically provided for registry access

## Code Style Guidelines

### Python

- Formatted with `ruff format`; 100-char line length, 4-space indentation, double quotes, trailing commas
- Imports: stdlib first, third-party second, local last (ruff enforces isort ordering); unused imports allowed in `__init__.py` only; star imports allowed only under `src/custom_nodes/**`
- Naming: `snake_case` for functions/variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants
- Use specific exceptions with `raise ... from err`; avoid bare `except:`; configure loggers at module level; `print` is acceptable (ComfyUI convention, ruff ignores `T20`)
- Type hints: `basic` pyright mode; add hints to public APIs; prefer `typing` generics (`Iterable`, `Mapping`, `Sequence`) over concrete types; use `from __future__ import annotations` when it improves readability
- Google-style docstrings for public functions/classes when behavior is non-obvious
- `os.path` is acceptable; `pathlib.Path` only when it improves clarity
- Prefer small functions, early returns, comprehensions when readable
- For custom nodes: follow ComfyUI conventions with `__init__.py` and `setup_js_api` for API routes; frontend JS in `js/` directory

### Ruff and Pyright Config Notes

- Ruff ignores `T20` (print statements) and `G004` (f-strings in logging); `max-complexity = 15` (McCabe)
- Pyright uses `basic` type checking; lenient on missing imports (warn, not fail); uses `typings/` as stub path

### Nix

- Format with `nix fmt` (nixfmt-rfc-style)
- Keep attrsets aligned; avoid reformatting unrelated sections
- Use `writeShellApplication` for shell scripts (provides shellcheck validation)
- Pin all external dependencies with hashes in `nix/versions.nix`

### Shell

- All scripts must pass `shellcheck`
- Prefer `set -euo pipefail` for new scripts
- Keep scripts small and focused; add new helpers in `scripts/`

### Commits

- Use conventional prefixes: `feat:`, `fix:`, `docs:`, `ci:`, `refactor:`, `chore:`, etc.
- Keep commit messages short and specific to the change

### NixOS Module: Declarative Custom Nodes

The NixOS module supports declarative custom node management via `services.comfyui.customNodes`:

```nix
services.comfyui = {
  enable = true;
  customNodes = {
    ComfyUI-Impact-Pack = pkgs.fetchFromGitHub {
      owner = "ltdrdata";
      repo = "ComfyUI-Impact-Pack";
      rev = "v1.0.0";
      hash = "sha256-...";
    };
  };
};
```

Nodes are symlinked at service start. Fully reproducible and version-pinned.

## Binary Cache (Cachix)

Speed up builds with the public Cachix cache:

```bash
cachix use comfyui
```

Automatically configured in the flake's `nixConfig`. CI publishes artifacts on main branch pushes.
