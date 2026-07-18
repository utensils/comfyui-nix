# Update ComfyUI to v0.28.1

## Summary
- Update ComfyUI to upstream `v0.28.1`.
- Refresh vendored ComfyUI frontend, workflow templates, embedded docs, and `comfy-kitchen` pins.
- Vendor the two new workflow template subpackages introduced by `comfyui-workflow-templates` 0.11.x: `-json` and `-media-assets-01`.
- Vendor the new `comfy-angle` dependency (replaces `glfw` upstream): platform-specific wheels bundling native ANGLE `libEGL.so`/`libGLESv2.so` used by the new GLSL shader nodes (`comfy_extras/nodes_glsl.py`). On Linux the bundled libs are autoPatchelf'd against Nix-provided X11/xcb libs; no wheel exists for x86_64-darwin, so it is skipped there.
- Drop `glfw` from the Python runtime to stay in sync with upstream requirements.
- Regenerate workflow template inputs from the upstream manifest (618 files).

## Notes
- `PyOpenGL` requirement tightened upstream to `>=3.1.8`; nixpkgs pin provides 3.1.9, no change needed.
- `comfy-aimdo` stays at 0.4.10 (unchanged upstream).
- `nix/patches/comfyui-ltxvideo-compat.patch` and `nix/patches/comfyui-cpu-fallback.patch` still apply cleanly to v0.28.1.
- `nix/patches/comfyui-mps-fp8-dequant.patch` is not referenced by any module (orphaned before this PR) and no longer applies to the new `comfy/quant_ops.py`; left untouched here.

## Verification
- `nix build .#packages.x86_64-linux.default --no-link`
- `nix flake check`
- Runtime startup smoke test on a disposable data dir with `--cpu`
