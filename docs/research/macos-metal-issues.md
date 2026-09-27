# macOS / Metal issue audit

Audited on 2026-09-26 against `origin/main` at `fee7b66`, using an Apple Silicon
Mac running macOS 26.6.2. The locked package set supplies Accelerate 1.13.0,
Ultralytics 8.4.51, and the repository's Apple Silicon override supplies
PyTorch 2.5.1. No model downloads or full image generations were required.

## Findings

| Issue | Validity on current main | Change |
| --- | --- | --- |
| [#105](https://github.com/utensils/comfyui-nix/issues/105) | Valid: FSDP2 initialization raises `ImportError: FSDP2 requires PyTorch >= 2.6.0` with the pinned torch. | Exclude only `test_param_mapping_error_handling` on Apple Silicon. |
| [#99](https://github.com/utensils/comfyui-nix/issues/99) | Valid: the current Ultralytics test still downloads GitHub fixture archives. | Exclude only `test_data_utils` on all platforms, since any uncached sandbox build can encounter it. |
| [#56](https://github.com/utensils/comfyui-nix/issues/56) | The MPS claim does not reproduce. The XPU concern is separate and remains outside this macOS fix. | Preserve the current MPS initialization and fallback. |

The other open reports (#34, #61, #80) explicitly concern Linux GPU deployments.
No additional open issue specifically describes a macOS / Metal failure.

## Evidence and scope

Accelerate's [FSDP2 test](https://github.com/huggingface/accelerate/blob/v1.13.0/tests/fsdp/test_fsdp.py)
constructs `FullyShardedDataParallelPlugin(fsdp_version=2)`. Its
[`require_fsdp2` decorator](https://github.com/huggingface/accelerate/blob/v1.13.0/src/accelerate/test_utils/testing.py)
accepts torch >= 2.5.0, while the plugin actually requires >= 2.6.0.
Loading that exact Accelerate source with the installed Nix torch 2.5.1 reproduced
the reported ImportError. This does not indicate a broken inference API: FSDP2
is a distributed training feature unsupported by the intentionally older torch.
The fix retains the MPS stability pin and all other existing checks.

The current [Ultralytics test](https://github.com/ultralytics/ultralytics/blob/v8.4.51/tests/test_python.py)
iterates through dataset tasks and downloads archives from
`https://github.com/ultralytics/hub/raw/main/example_datasets/`.
Executing the actual test function with network access denied by macOS
`sandbox-exec` reproduced a ConnectionError downloading `coco8.zip`.
This is a targeted offline reproduction, not a claim that the entire original
Nix build reached the same test. Linux cache hits can conceal the problem.

In [ComfyUI v0.37.0 initialization](https://github.com/Comfy-Org/ComfyUI/blob/v0.37.0/comfy/model_management.py),
MPS detection sets `cpu_state = CPUState.MPS` before our patch. The patch only
modifies `CPUState.GPU`. Executing the actual upstream MPS initialization and
the repository's added fallback statements with real torch preserved
`CPUState.MPS`. A small float32 matrix multiplication on MPS also matched its
CPU result after synchronization. These checks establish device availability
and initialization behavior, not full workflow compatibility.

## Reproduction

The uncached macOS validation also uncovered a host-port collision in the
transitive Valkey test dependency. Nixpkgs' Redis test hook starts its server on
port 6379 and waits indefinitely for a Unix socket if startup fails. The host
already had a Redis service listening on that port; no fixture server was
running and the hook repeatedly reported a missing socket. The Darwin override
selects an available loopback port and passes the same port to Valkey's
`--valkey-url` pytest option. This preserves the host service and the test suite.

Build either dependency using the repository's actual Python overrides (the
`pythonRuntime.pkgs` attribute of a `withPackages` environment is the stock
package set, so it must not be used for this reproduction):

```sh
nix build --impure --no-link -L --expr '
  let
    f = builtins.getFlake (toString ./.);
    pkgs = import f.inputs.nixpkgs {
      system = "aarch64-darwin";
      config.allowUnfree = true;
    };
    python = pkgs.python312.override {
      packageOverrides = import ./nix/python-overrides.nix {
        inherit pkgs;
        versions = import ./nix/versions.nix;
      };
    };
  in python.pkgs.accelerate
'
```

Replace `accelerate` with `ultralytics` for the other dependency.
Run `nix flake check -L` for the repository quality gate.

Evaluation of the overrides on Apple Silicon, Linux CPU, CUDA, ROCm, and XPU
confirmed that only Apple Silicon gains the FSDP2 test exclusion. The existing
CUDA/ROCm/XPU inductor exclusion is preserved, and all five configurations gain
the network-dependent Ultralytics exclusion. Intel macOS cannot be evaluated
with the current locked nixpkgs, which has dropped `x86_64-darwin` support.
