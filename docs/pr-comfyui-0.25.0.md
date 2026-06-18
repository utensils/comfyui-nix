# Update ComfyUI to v0.25.0

## Summary
- Update ComfyUI to upstream `v0.25.0`.
- Refresh vendored ComfyUI frontend, workflow templates, embedded docs, manager, `comfy-kitchen`, and `comfy-aimdo` pins.
- Regenerate workflow template inputs from the upstream workflow template manifest.
- Update PyAV to `16.0.1` for upstream `av>=16.0.0` compatibility.
- Remove the obsolete unused LTXVideo rotary embedding compatibility patch.
- Fix the `nix run .#update` `awk` hint so it works under `set -u`.

## Verification
- `nix build .#packages.x86_64-linux.default --no-link`
- `nix flake check`
- `nix run .#update`
- Runtime startup on a disposable data dir with `--cpu`
- Queued `EmptyImage -> SaveImage` and verified a generated `64x64` PNG
- Model downloader runtime smoke test:
  - Served a local test file over HTTP
  - Queued `/model-downloader/download`
  - Confirmed `/model-downloader/progress/{id}` reached `completed`
  - Verified the downloaded file matched the source
  - Confirmed `/model-downloader/resolve-folder/{filename}` returned `checkpoints`
