{
  pkgs,
  versions,
  gpuSupport ? "none", # "none", "cuda", "rocm", "xpu"
  rocmChannel ? "rocm71", # when gpuSupport="rocm": which pytorchWheels entry ("rocm71" | "rocm72")
}:
let
  lib = pkgs.lib;
  useCuda = gpuSupport == "cuda" && pkgs.stdenv.hostPlatform.isLinux;
  useRocm = gpuSupport == "rocm" && pkgs.stdenv.hostPlatform.isLinux;
  # Intel XPU wheels are Linux x86_64 only (no aarch64 upstream)
  useXpu =
    gpuSupport == "xpu" && pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  useDarwinArm64 = isDarwin && pkgs.stdenv.hostPlatform.isAarch64;
  # Whether torch is one of the pre-built wheels below instead of nixpkgs' own build.
  # Packages depending on torch are then rebuilt against it, running their test suites here.
  wheelTorch = useCuda || useRocm || useXpu || useDarwinArm64;
  sentencepieceNoGperf = pkgs.sentencepiece.override { withGPerfTools = false; };
  cudaPackages = pkgs.cudaPackages_13;

  # Interpreter tag of the Python selected in python.nix, e.g. "cp313".
  pythonTag =
    "cp" + lib.replaceStrings [ "." ] [ "" ] (import ./python.nix { inherit pkgs; }).pythonVersion;

  # Interpreter-specific wheels are pinned in versions.nix as a URL template plus one hash per tag,
  # where "{py}" in the URL stands for the interpreter tag.
  # Resolve a pin to the plain { url, hash } pair for the selected Python.
  # Evaluation fails with a pointer to versions.nix when the hash for that tag is missing,
  # which is the only thing a Python bump has to add.
  resolveWheel =
    name: spec:
    spec
    // {
      url = lib.replaceStrings [ "{py}" ] [ pythonTag ] spec.url;
      hash =
        spec.hashes.${pythonTag}
          or (throw "nix/versions.nix: no ${pythonTag} hash pinned for ${name} ${spec.version}");
    };
  resolveWheels = lib.mapAttrs resolveWheel;

  # Pre-built PyTorch CUDA wheels from pytorch.org
  # These avoid compiling PyTorch from source (which requires 30-60GB RAM and hours of build time)
  # CUDA runtime libraries are supplied by nixpkgs, so no separate toolkit is needed at runtime
  cudaWheels = resolveWheels versions.pytorchWheels.cu130;

  # Pre-built PyTorch ROCm wheels from pytorch.org.
  # These avoid compiling PyTorch from source (which requires 30-60GB RAM and hours of build time).
  # `rocmChannel` selects the wheel set: "rocm71" or "rocm72" (the gfx1151 /
  # Strix Halo path). See versions.nix.
  rocmWheels = resolveWheels versions.pytorchWheels.${rocmChannel};

  # Pre-built PyTorch XPU wheels from pytorch.org (Intel oneAPI / SYCL)
  # Unlike CUDA/ROCm, the XPU torch wheel does NOT bundle its SYCL / MKL /
  # Intel compiler runtimes — they ship as ~20 separate PyPI wheels declared
  # in Requires-Dist. All pinned in versions.xpuRuntime and packaged below.
  # Host still provides Level Zero loader + Intel compute-runtime at runtime.
  xpuWheels = resolveWheels versions.pytorchWheels.xpu;
  tritonXpuWheel = resolveWheel "triton-xpu" versions.xpuRuntime.triton-xpu;

  # Ignore-list for deps neither the wheels nor nixpkgs provide.
  # Intel wheel-to-wheel SONAME refs are resolved via cross-wheel buildInputs
  # in the mkIntelRuntime helper below — NOT via this ignore list.
  xpuIgnoreMissingLibs = [
    # Host-provided (Level Zero loader + Intel compute-runtime, on NixOS via
    # hardware.graphics.extraPackages, on other distros via system packaging)
    "libze_loader.so.1"
    "libze_intel_gpu.so.1"
    "libOpenCL.so.1"
    "libigdrcl.so"
    "libigc.so.2"
    # impi-rt fabric plugins (RDMA / InfiniBand / PSM / EFA / UCX) — loaded
    # only when MPI distributed mode is requested. ComfyUI is single-node, so
    # these fabric adapters are never opened and can safely be absent.
    "librdmacm.so.1"
    "libibverbs.so.1"
    "libucp.so.0"
    "libucs.so.0"
    "libuct.so.0"
    "libnuma.so.1"
    "libpsm2.so.2"
    "libefa.so.1"
    "libfabric.so.1"
    "libnl-3.so.200"
    "libnl-route-3.so.200"
    "libze_loader.so" # versionless alias
  ];

  # Pre-built PyTorch wheels for macOS Apple Silicon
  # PyTorch 2.5.1 is used instead of 2.9.x due to MPS bugs on macOS 26 (Tahoe)
  # See: https://github.com/pytorch/pytorch/issues/167679
  darwinWheels = resolveWheels versions.pytorchWheels.darwinArm64;

  # Common build inputs for PyTorch wheels (manylinux compatibility)
  wheelBuildInputs = [
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    pkgs.libGL
    pkgs.glib
  ];

  # CUDA libraries needed by PyTorch wheels (for auto-patchelf).
  #
  # These replace the `nvidia-*` PyPI wheels the torch wheel asks for, which we
  # strip from its metadata. nixpkgs does not always carry the exact versions
  # PyTorch pinned, and because the SONAMEs match, auto-patchelf accepts the
  # substitution silently — any mismatch surfaces only at runtime. Current deltas
  # against `torch-2.10.0+cu130`:
  #
  #   cuDNN         wheel wants 9.15.1.9  nixpkgs has 9.13.0.50  (older — risky direction)
  #   NCCL          wheel wants 2.28.9    nixpkgs has 2.28.7     (older — risky direction)
  #   cuSPARSELt    wheel wants 0.8.0     nixpkgs has 0.8.1.1    (newer — safe direction)
  #
  # The cuDNN/NCCL deltas are latent, not active: every symbol libtorch_cuda.so
  # imports from them is still exported by the older builds. They clear once the
  # nixpkgs input is bumped, which is blocked on the vendored-wheel metadata work
  # in https://github.com/utensils/comfyui-nix/issues/81
  cudaLibs = pkgs.lib.optionals useCuda (
    with cudaPackages;
    [
      cuda_cudart # libcudart.so.13
      cuda_cupti # libcupti.so.13
      libcublas # libcublas.so.13, libcublasLt.so.13
      libcufft # libcufft.so.12
      libcurand # libcurand.so.10
      libcusolver # libcusolver.so.12
      libcusparse # libcusparse.so.12
      libcusparse_lt # libcusparseLt.so.0 (structured sparsity)
      libcufile # libcufile.so.0 (GPU Direct Storage)
      libnvshmem # libnvshmem_host.so.3 (multi-GPU shared memory)
      cudnn # libcudnn.so.9
      nccl # libnccl.so.2
      cuda_nvrtc # libnvrtc.so.13
    ]
  );

  # ROCm libraries needed by PyTorch wheels (for auto-patchelf)
  # The stable rocm71/rocm72 wheels bundle the ROCm runtime internally; only
  # compression libs are needed externally.
  rocmLibs = pkgs.lib.optionals useRocm (
    with pkgs;
    [
      xz # liblzma.so.5
      zstd # libzstd.so.1
      bzip2 # libbz2.so.1
    ]
  );
in
final: prev:
# CUDA torch from pre-built wheels - avoids 30-60GB RAM compilation
# Unlike the ROCm wheels, these do NOT bundle their CUDA libraries: the wheel
# declares them as separate `nvidia-*` PyPI requirements, which we strip from the
# metadata below and satisfy from nixpkgs via `cudaLibs` instead.
lib.optionalAttrs useCuda {
  torch = final.buildPythonPackage {
    pname = "torch";
    version = cudaWheels.torch.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = cudaWheels.torch.url;
      hash = cudaWheels.torch.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.gnused
    ];
    buildInputs = wheelBuildInputs ++ cudaLibs;
    # libcuda.so.1 comes from the NVIDIA driver at runtime, not from cudaPackages
    autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];

    # The CUDA wheel names PyPI CUDA packages that are provided by nixpkgs
    # cudaPackages instead. The runtime dependency hook cannot recognize those
    # system providers, so validate the rewritten installed metadata below.
    dontCheckRuntimeDeps = true;
    postInstall = ''
      for metadata in "$out/${final.python.sitePackages}"/torch-*.dist-info/METADATA; do
        if [[ -f "$metadata" ]]; then
          sed -i '/^Requires-Dist: cuda-bindings/d' "$metadata"
          sed -i '/^Requires-Dist: nvidia-/d' "$metadata"
          sed -i '/^Requires-Dist: triton/d' "$metadata"
        fi
      done
    '';

    propagatedBuildInputs = with final; [
      filelock
      typing-extensions
      sympy
      networkx
      jinja2
      fsspec
      setuptools
    ];
    # Don't check for CUDA at import time (requires GPU)
    pythonImportsCheck = [ ];
    doCheck = false;

    # Passthru attributes expected by downstream packages (xformers, bitsandbytes, etc.)
    passthru = {
      cudaSupport = true;
      rocmSupport = false;
      # All architectures supported by the pre-built wheel
      cudaCapabilities = [
        "7.5"
        "8.0"
        "8.6"
        "8.9"
        "9.0"
        "10.0" # Blackwell (B100/B200 data center)
        "12.0" # Blackwell (RTX 50xx consumer)
      ];
      # Provide the matching CUDA package set for downstream packages
      inherit cudaPackages;
      rocmPackages = { };
    };

    meta = {
      description = "PyTorch with CUDA ${cudaWheels.torch.version} (pre-built wheel)";
      homepage = "https://pytorch.org";
      license = lib.licenses.bsd3;
      platforms = [ "x86_64-linux" ];
    };
  };

  torchvision = final.buildPythonPackage {
    pname = "torchvision";
    version = cudaWheels.torchvision.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = cudaWheels.torchvision.url;
      hash = cudaWheels.torchvision.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = wheelBuildInputs ++ cudaLibs ++ [ final.torch ];
    # Ignore torch libs (loaded via Python import)
    autoPatchelfIgnoreMissingDeps = [
      "libcuda.so.1"
      "libtorch.so"
      "libtorch_cpu.so"
      "libtorch_cuda.so"
      "libtorch_python.so"
      "libc10.so"
      "libc10_cuda.so"
    ];
    propagatedBuildInputs = with final; [
      torch
      numpy
      pillow
    ];
    pythonImportsCheck = [ ];
    doCheck = false;
    meta = {
      description = "TorchVision with CUDA (pre-built wheel)";
      homepage = "https://pytorch.org/vision";
      license = lib.licenses.bsd3;
      platforms = [ "x86_64-linux" ];
    };
  };

  torchaudio = final.buildPythonPackage {
    pname = "torchaudio";
    version = cudaWheels.torchaudio.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = cudaWheels.torchaudio.url;
      hash = cudaWheels.torchaudio.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = wheelBuildInputs ++ cudaLibs ++ [ final.torch ];
    # Ignore torch libs (loaded via Python) and FFmpeg/sox libs (optional, multiple versions bundled)
    autoPatchelfIgnoreMissingDeps = [
      "libcuda.so.1"
      # Torch libs (loaded via Python import)
      "libtorch.so"
      "libtorch_cpu.so"
      "libtorch_cuda.so"
      "libtorch_python.so"
      "libc10.so"
      "libc10_cuda.so"
      # Sox (optional audio backend)
      "libsox.so"
      # FFmpeg 4.x
      "libavutil.so.56"
      "libavcodec.so.58"
      "libavformat.so.58"
      "libavfilter.so.7"
      "libavdevice.so.58"
      # FFmpeg 5.x
      "libavutil.so.57"
      "libavcodec.so.59"
      "libavformat.so.59"
      "libavfilter.so.8"
      "libavdevice.so.59"
      # FFmpeg 6.x
      "libavutil.so.58"
      "libavcodec.so.60"
      "libavformat.so.60"
      "libavfilter.so.9"
      "libavdevice.so.60"
    ];
    propagatedBuildInputs = with final; [
      torch
    ];
    pythonImportsCheck = [ ];
    doCheck = false;
    meta = {
      description = "TorchAudio with CUDA (pre-built wheel)";
      homepage = "https://pytorch.org/audio";
      license = lib.licenses.bsd2;
      platforms = [ "x86_64-linux" ];
    };
  };
}
# macOS Apple Silicon - use PyTorch 2.5.1 wheels to avoid MPS bugs on macOS 26 (Tahoe)
# PyTorch 2.9.x in nixpkgs has known issues with MPS on macOS 26
// lib.optionalAttrs useDarwinArm64 {
  torch = final.buildPythonPackage {
    pname = "torch";
    version = darwinWheels.torch.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = darwinWheels.torch.url;
      hash = darwinWheels.torch.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    # The 2.5.1 wheel pins sympy==1.13.1, which nixpkgs no longer ships. The
    # combination has always been what this flake builds and runs, so relax the
    # bound rather than pin sympy back. Drop this when the wheel is bumped.
    pythonRelaxDeps = [ "sympy" ];
    # pythonRelaxDeps normally runs in postBuild, which this prebuilt wheel
    # skips via dontBuild. Remove this phase override when nixpkgs rewrites
    # wheel metadata before its runtime dependency check.
    preInstallPhases = [ "pythonRelaxDepsHook" ];
    nativeBuildInputs = [ pkgs.cctools ];
    # OpenCV's dependencies already load nixpkgs OpenMP. Loading the wheel's
    # second runtime afterwards crashes CPU matmul inside __kmp_suspend_64.
    # Use the same runtime regardless of Python module import order.
    postFixup = ''
      install_name_tool -change @rpath/libomp.dylib \
        ${pkgs.llvmPackages.openmp}/lib/libomp.dylib \
        "$out/${final.python.sitePackages}/torch/lib/libtorch_cpu.dylib"
      rm "$out/${final.python.sitePackages}/torch/lib/libomp.dylib"

      # Spawned DataLoader workers pass Python's resource-tracker pipe to the
      # manager. Keeping it open deadlocks interpreter shutdown while tensors
      # still hold manager sockets. The manager only needs stdin/out/err.
      manager="$out/${final.python.sitePackages}/torch/bin/torch_shm_manager"
      mv "$manager" "$manager.real"
      cat > manager-launcher.c <<EOF
      #include <stdio.h>
      #include <unistd.h>
      int main(int argc, char **argv) {
          int max_fd = getdtablesize();
          for (int fd = 3; fd < max_fd; ++fd) close(fd);
          execv("$manager.real", argv);
          perror("torch_shm_manager");
          return 127;
      }
      EOF
      $CC -O2 manager-launcher.c -o "$manager"
    '';
    propagatedBuildInputs = with final; [
      filelock
      typing-extensions
      sympy
      networkx
      jinja2
      fsspec
      setuptools
    ];
    pythonImportsCheck = [ "torch" ];
    doCheck = false;

    passthru = {
      cudaSupport = false;
      rocmSupport = false;
    };

    meta = {
      description = "PyTorch ${darwinWheels.torch.version} for macOS Apple Silicon (MPS)";
      homepage = "https://pytorch.org";
      license = lib.licenses.bsd3;
      platforms = [ "aarch64-darwin" ];
    };
  };

  torchvision = final.buildPythonPackage {
    pname = "torchvision";
    version = darwinWheels.torchvision.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = darwinWheels.torchvision.url;
      hash = darwinWheels.torchvision.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    propagatedBuildInputs = with final; [
      torch
      numpy
      pillow
    ];
    pythonImportsCheck = [ "torchvision" ];
    doCheck = false;
    meta = {
      description = "TorchVision ${darwinWheels.torchvision.version} for macOS Apple Silicon";
      homepage = "https://pytorch.org/vision";
      license = lib.licenses.bsd3;
      platforms = [ "aarch64-darwin" ];
    };
  };

  torchaudio = final.buildPythonPackage {
    pname = "torchaudio";
    version = darwinWheels.torchaudio.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = darwinWheels.torchaudio.url;
      hash = darwinWheels.torchaudio.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    propagatedBuildInputs = with final; [
      torch
    ];
    pythonImportsCheck = [ "torchaudio" ];
    doCheck = false;
    meta = {
      description = "TorchAudio ${darwinWheels.torchaudio.version} for macOS Apple Silicon";
      homepage = "https://pytorch.org/audio";
      license = lib.licenses.bsd2;
      platforms = [ "aarch64-darwin" ];
    };
  };
}
# ROCm torch from pre-built wheels - avoids 30-60GB RAM compilation
# The wheels bundle ROCm libraries internally, providing full GPU support
// lib.optionalAttrs useRocm {
  torch = final.buildPythonPackage {
    pname = "torch";
    version = rocmWheels.torch.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = rocmWheels.torch.url;
      hash = rocmWheels.torch.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.gnused
    ];
    buildInputs = wheelBuildInputs ++ rocmLibs;

    # The ROCm wheel names triton-rocm, which is provided by the bundled ROCm
    # runtime rather than a PyPI package. The runtime dependency hook cannot
    # recognize that provider, so validate the rewritten installed metadata in
    # the rocm-torch-runtime-deps check instead.
    dontCheckRuntimeDeps = true;
    # These are provided by nixpkgs rocmPackages, not PyPI packages
    postInstall = ''
      for metadata in "$out/${final.python.sitePackages}"/torch-*.dist-info/METADATA; do
        if [[ -f "$metadata" ]]; then
          sed -i '/^Requires-Dist: triton-rocm/d' "$metadata"
        fi
      done
    '';

    propagatedBuildInputs = with final; [
      filelock
      typing-extensions
      sympy
      networkx
      jinja2
      fsspec
      setuptools
    ];
    # Don't check for ROCm at import time (requires GPU)
    pythonImportsCheck = [ ];
    doCheck = false;

    # Passthru attributes expected by downstream packages (xformers, bitsandbytes, etc.)
    # The wheel bundles ROCm 7.1 and supports all GPU architectures
    passthru = {
      cudaSupport = false;
      rocmSupport = true;
      # Provide rocmPackages for packages that need it (use default version)
      cudaPackages = { };
      rocmPackages = pkgs.rocmPackages;
    };

    meta = {
      description = "PyTorch with ROCm ${rocmWheels.torch.version} (pre-built wheel)";
      homepage = "https://pytorch.org";
      license = lib.licenses.bsd3;
      platforms = [ "x86_64-linux" ];
    };
  };

  torchvision = final.buildPythonPackage {
    pname = "torchvision";
    version = rocmWheels.torchvision.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = rocmWheels.torchvision.url;
      hash = rocmWheels.torchvision.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = wheelBuildInputs ++ rocmLibs ++ [ final.torch ];

    # Torch libs live in a non-standard path (site-packages/torch/lib/) so
    # autoPatchelf can't find them. We ignore them during patching and add
    # the RPATH manually in postFixup so _C.so can find libc10.so at runtime.
    autoPatchelfIgnoreMissingDeps = [
      "libc10.so"
      "libc10_hip.so"
      "libamdhip64.so.7"
      "libtorch.so"
      "libtorch_cpu.so"
      "libtorch_hip.so"
      "libtorch_python.so"
      "libhipblas.so.3"
      "libhipfft.so.0"
      "libhipsolver.so.1"
      "libhipsparse.so.4"
      "libMIOpen.so.1"
      "librocrand.so.1"
    ];
    postFixup = ''
      local torchLib="${final.torch}/${final.torch.pythonModule.sitePackages}/torch/lib"
      for so in $out/${final.torch.pythonModule.sitePackages}/torchvision/*.so; do
        ${pkgs.patchelf}/bin/patchelf --add-rpath "$torchLib" "$so"
      done
    '';
    propagatedBuildInputs = with final; [
      torch
      numpy
      pillow
    ];
    pythonImportsCheck = [ "torchvision" ];
    doCheck = false;
    meta = {
      description = "TorchVision with ROCm (pre-built wheel)";
      homepage = "https://pytorch.org/vision";
      license = lib.licenses.bsd3;
      platforms = [ "x86_64-linux" ];
    };
  };

  torchaudio = final.buildPythonPackage {
    pname = "torchaudio";
    version = rocmWheels.torchaudio.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = rocmWheels.torchaudio.url;
      hash = rocmWheels.torchaudio.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = wheelBuildInputs ++ rocmLibs ++ [ final.torch ];
    # Ignore torch libs (loaded via Python) and FFmpeg/sox libs (optional, multiple versions bundled)
    autoPatchelfIgnoreMissingDeps = [
      # Torch libs (loaded via Python import)
      "libc10.so"
      "libc10_hip.so"
      "libamdhip64.so.7"
      "libtorch.so"
      "libtorch_cpu.so"
      "libtorch_hip.so"
      "libtorch_python.so"
      "libhipblas.so.3"
      "libhipfft.so.0"
      "libhipsolver.so.1"
      "libhipsparse.so.4"
      "libMIOpen.so.1"
      "librocrand.so.1"
      # Sox (optional audio backend)
      "libsox.so"
      # FFmpeg 4.x
      "libavutil.so.56"
      "libavcodec.so.58"
      "libavformat.so.58"
      "libavfilter.so.7"
      "libavdevice.so.58"
      # FFmpeg 5.x
      "libavutil.so.57"
      "libavcodec.so.59"
      "libavformat.so.59"
      "libavfilter.so.8"
      "libavdevice.so.59"
      # FFmpeg 6.x
      "libavutil.so.58"
      "libavcodec.so.60"
      "libavformat.so.60"
      "libavfilter.so.9"
      "libavdevice.so.60"
    ];
    propagatedBuildInputs = with final; [
      torch
    ];
    pythonImportsCheck = [ ];
    doCheck = false;
    meta = {
      description = "TorchAudio with ROCm (pre-built wheel)";
      homepage = "https://pytorch.org/audio";
      license = lib.licenses.bsd2;
      platforms = [ "x86_64-linux" ];
    };
  };
}
# Intel XPU torch + runtime wheels
# The XPU torch wheel only contains torch-proper binaries (~240 MB). Its Intel
# runtime dependencies (SYCL, MKL, oneCCL, Intel compiler RT, TBB, PTI, triton)
# ship as ~20 separate wheels pinned in versions.xpuRuntime. Each is built as
# its own Python package below via mkIntelRuntime, then all are propagated as
# torch's deps so auto-patchelf can resolve libtorch_xpu.so's sibling SONAMEs.
// lib.optionalAttrs useXpu (
  let
    # triton-xpu ships a real Python `triton/` top-level module (not just .so
    # files under .data/data/lib), so it needs its own buildPythonPackage for
    # Python to import it. Without this, torch.compile / Inductor falls back
    # to nixpkgs' non-XPU triton or fails at dynamo compile time.
    tritonXpu = final.buildPythonPackage {
      pname = "triton";
      version = tritonXpuWheel.version;
      format = "wheel";
      src = pkgs.fetchurl {
        inherit (tritonXpuWheel) url hash;
      };
      dontBuild = true;
      dontConfigure = true;
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      buildInputs = wheelBuildInputs;
      autoPatchelfIgnoreMissingDeps = xpuIgnoreMissingLibs;
      propagatedBuildInputs = with final; [ filelock ];
      pythonImportsCheck = [ ]; # needs XPU runtime; can't import in build sandbox
      doCheck = false;
      dontCheckRuntimeDeps = true;
      meta = {
        description = "Triton compiler with Intel XPU backend";
        homepage = "https://github.com/intel/intel-xpu-backend-for-triton";
        license = lib.licenses.mit;
        platforms = [ "x86_64-linux" ];
      };
    };

    # The other Intel runtime wheels contain no Python code — just .so files
    # under the wheel's `.data/data/lib/` convention. Rather than 21 individual
    # buildPythonPackage derivations (which cross-reference each other and
    # trigger infinite recursion through requiredPythonModules), fetch and
    # unpack each wheel into a single combined derivation. All cross-wheel
    # SONAMEs resolve against this unified lib/ dir, and it's one buildInput
    # for torch instead of 21. triton-xpu is excluded — see tritonXpu above.
    intelOneapiRuntime = pkgs.stdenv.mkDerivation {
      pname = "intel-oneapi-runtime";
      version = "2025.3";
      srcs = lib.mapAttrsToList (_: spec: pkgs.fetchurl { inherit (spec) url hash; }) (
        lib.filterAttrs (n: _: n != "triton-xpu") versions.xpuRuntime
      );
      dontConfigure = true;
      dontBuild = true;
      sourceRoot = ".";
      nativeBuildInputs = [
        pkgs.unzip
        pkgs.autoPatchelfHook
      ];
      buildInputs = wheelBuildInputs;
      autoPatchelfIgnoreMissingDeps = xpuIgnoreMissingLibs;
      unpackPhase = ''
        runHook preUnpack
        for whl in $srcs; do
          mkdir -p "wheel_$(basename "$whl" .whl)"
          unzip -q "$whl" -d "wheel_$(basename "$whl" .whl)"
        done
        runHook postUnpack
      '';
      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib $out/share/intel-oneapi
        # Collect .so files from each wheel's .data/data/lib into $out/lib.
        # Later wheels' files overwrite earlier only on exact filename match;
        # Intel wheels use distinct filenames so this is safe.
        for wheel_dir in wheel_*; do
          if [ -d "$wheel_dir" ]; then
            for data_lib in "$wheel_dir"/*.data/data/lib; do
              if [ -d "$data_lib" ]; then
                cp -rn "$data_lib"/. $out/lib/ 2>/dev/null || \
                  cp -r "$data_lib"/. $out/lib/
              fi
            done
            # Also copy any top-level lib dirs (some wheels use that layout)
            if [ -d "$wheel_dir/lib" ]; then
              cp -rn "$wheel_dir/lib"/. $out/lib/ 2>/dev/null || true
            fi
            # Preserve license / manifest files under share/ for compliance
            for meta in "$wheel_dir"/*.dist-info/METADATA; do
              if [ -f "$meta" ]; then
                pname=$(basename "$(dirname "$meta")" .dist-info)
                mkdir -p "$out/share/intel-oneapi/$pname"
                cp "$meta" "$out/share/intel-oneapi/$pname/"
              fi
            done
          fi
        done
        runHook postInstall
      '';
      # Runtime library stuff — no binaries, no Python, just .so files.
      dontStrip = true;
      meta = {
        description = "Combined Intel oneAPI runtime libraries (from PyPI wheels)";
        homepage = "https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit.html";
        license = lib.licenses.unfreeRedistributable;
        platforms = [ "x86_64-linux" ];
      };
    };
  in
  {
    # Expose triton as a named attr so python.withPackages can pick it up.
    triton = tritonXpu;

    torch = final.buildPythonPackage {
      pname = "torch";
      version = xpuWheels.torch.version;
      format = "wheel";
      src = pkgs.fetchurl {
        url = xpuWheels.torch.url;
        hash = xpuWheels.torch.hash;
      };
      dontBuild = true;
      dontConfigure = true;
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      # Combined Intel oneAPI runtime derivation provides all SYCL/MKL/oneCCL/
      # Intel compiler RT / TBB / PTI .so files. Listed in buildInputs so
      # auto-patchelf adds its lib/ to torch's RPATH and resolves sibling
      # SONAMEs (libsycl.so.8, libmkl_sycl_*.so.5, libccl.so.1, etc).
      buildInputs = wheelBuildInputs ++ [ intelOneapiRuntime ];
      autoPatchelfIgnoreMissingDeps = xpuIgnoreMissingLibs;
      # Intel oneAPI runtime is propagated so its lib/ is on LD_LIBRARY_PATH
      # at ComfyUI runtime (the launcher also sets this explicitly). triton
      # is propagated so torch.compile / Inductor can import the XPU backend.
      propagatedBuildInputs =
        (with final; [
          filelock
          typing-extensions
          sympy
          networkx
          jinja2
          fsspec
          setuptools
        ])
        ++ [ tritonXpu ];
      propagatedNativeBuildInputs = [ intelOneapiRuntime ];
      pythonImportsCheck = [ ];
      doCheck = false;
      dontCheckRuntimeDeps = true; # Intel wheel pip names use hyphens/underscores inconsistently

      # The XPU wheel names ~20 Intel runtime wheels that nixpkgs provides under
      # different pip-visible names, so anything that resolves torch's declared
      # requirements reports every one of them as missing. dontCheckRuntimeDeps
      # above only covers this derivation; downstream builds (xformers builds a
      # wheel with `pypa build --no-isolation`, which validates build deps) read
      # the installed METADATA and fail. Strip those entries, exactly as the
      # CUDA wheel does for its nvidia-* requirements. Nix still supplies the
      # libraries through propagatedBuildInputs.
      postInstall = ''
        for metadata in "$out/${final.python.sitePackages}"/torch-*.dist-info/METADATA; do
          if [[ -f "$metadata" ]]; then
            sed -i -E '/^Requires-Dist: (dpcpp-|impi-|intel-|mkl|oneccl|onemkl-|tbb|tcmlib|triton|umf)/d' "$metadata"
          fi
        done
      '';

      passthru = {
        cudaSupport = false;
        rocmSupport = false;
        xpuSupport = true;
        cudaPackages = { };
      };

      meta = {
        description = "PyTorch with Intel XPU ${xpuWheels.torch.version} (pre-built wheel, oneAPI/SYCL)";
        homepage = "https://pytorch.org";
        license = lib.licenses.bsd3;
        platforms = [ "x86_64-linux" ];
      };
    };

    torchvision = final.buildPythonPackage {
      pname = "torchvision";
      version = xpuWheels.torchvision.version;
      format = "wheel";
      src = pkgs.fetchurl {
        url = xpuWheels.torchvision.url;
        hash = xpuWheels.torchvision.hash;
      };
      dontBuild = true;
      dontConfigure = true;
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      buildInputs = wheelBuildInputs ++ [ final.torch ];
      # torch libs are loaded via Python import, not dlopen
      autoPatchelfIgnoreMissingDeps = [
        "libc10.so"
        "libc10_xpu.so"
        "libtorch.so"
        "libtorch_cpu.so"
        "libtorch_xpu.so"
        "libtorch_python.so"
      ];
      propagatedBuildInputs = with final; [
        torch
        numpy
        pillow
      ];
      pythonImportsCheck = [ ];
      doCheck = false;
      meta = {
        description = "TorchVision with Intel XPU (pre-built wheel)";
        homepage = "https://pytorch.org/vision";
        license = lib.licenses.bsd3;
        platforms = [ "x86_64-linux" ];
      };
    };

    torchaudio = final.buildPythonPackage {
      pname = "torchaudio";
      version = xpuWheels.torchaudio.version;
      format = "wheel";
      src = pkgs.fetchurl {
        url = xpuWheels.torchaudio.url;
        hash = xpuWheels.torchaudio.hash;
      };
      dontBuild = true;
      dontConfigure = true;
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      buildInputs = wheelBuildInputs ++ [ final.torch ];
      autoPatchelfIgnoreMissingDeps = [
        "libc10.so"
        "libc10_xpu.so"
        "libtorch.so"
        "libtorch_cpu.so"
        "libtorch_xpu.so"
        "libtorch_python.so"
        "libsox.so"
        # FFmpeg 4.x/5.x/6.x — same as ROCm torchaudio (wheel bundles multiple backends)
        "libavutil.so.56"
        "libavcodec.so.58"
        "libavformat.so.58"
        "libavfilter.so.7"
        "libavdevice.so.58"
        "libavutil.so.57"
        "libavcodec.so.59"
        "libavformat.so.59"
        "libavfilter.so.8"
        "libavdevice.so.59"
        "libavutil.so.58"
        "libavcodec.so.60"
        "libavformat.so.60"
        "libavfilter.so.9"
        "libavdevice.so.60"
      ];
      propagatedBuildInputs = with final; [
        torch
      ];
      pythonImportsCheck = [ ];
      doCheck = false;
      meta = {
        description = "TorchAudio with Intel XPU (pre-built wheel)";
        homepage = "https://pytorch.org/audio";
        license = lib.licenses.bsd2;
        platforms = [ "x86_64-linux" ];
      };
    };
  }
)
# Spandrel and other packages that need explicit torch handling
// lib.optionalAttrs (prev ? torch) {
  spandrel = final.buildPythonPackage rec {
    pname = "spandrel";
    version = versions.vendored.spandrel.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = versions.vendored.spandrel.url;
      hash = versions.vendored.spandrel.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    nativeBuildInputs = [
      final.setuptools
      final.wheel
      final.ninja
    ];
    propagatedBuildInputs = [
      final.torch
    ] # Use final.torch - will be CUDA/ROCm when gpuSupport="cuda|rocm"
    ++ lib.optionals (prev ? torchvision) [ final.torchvision ]
    ++ lib.optionals (prev ? safetensors) [ final.safetensors ]
    ++ lib.optionals (prev ? numpy) [ final.numpy ]
    ++ lib.optionals (prev ? einops) [ final.einops ]
    ++ lib.optionals (prev ? typing-extensions) [ final.typing-extensions ];
    pythonImportsCheck = [ ];
    doCheck = false;
  };
}
# Note: When useCuda=true, torch/torchvision/torchaudio are replaced with pre-built wheels
# above. Packages that depend on torch (kornia, accelerate, etc.) will automatically
# use our wheel-based torch via final.torch since we've overridden it in the overlay.
# Overrides that only Darwin needs, limited to the packages the pinned nixpkgs has.
#
# Most of them work around test suites.
# Darwin runs Python 3.12, whose package set is not in the binary cache, so everything is built from source there.
# Linux runs nixpkgs' default Python,
# where the same packages come from the binary cache or build and pass their tests unmodified.
// lib.optionalAttrs isDarwin (
  lib.filterAttrs (name: _: prev ? ${name}) {
    sentencepiece = prev.sentencepiece.overridePythonAttrs (old: {
      buildInputs = [ sentencepieceNoGperf.dev ];
      nativeBuildInputs = old.nativeBuildInputs or [ ];
    });

    # Disable tests for open-clip-torch (they hang waiting for model downloads)
    open-clip-torch = prev.open-clip-torch.overridePythonAttrs (_old: {
      doCheck = false;
    });

    # Fix torchmetrics build: nixpkgs torchmetrics doesn't declare setuptools as a build backend
    # dependency, so PEP517 build fails with "Cannot import 'setuptools.build_meta'".
    torchmetrics = prev.torchmetrics.overridePythonAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
        final.setuptools
        final.wheel
      ];
    });

    # inline-snapshot 0.34.2 fails three of its own documentation tests on the
    # pinned nixpkgs (they assert formatter output that has since changed) and is
    # not in the binary cache, so it gets built from source. It reaches us only as
    # a test helper in fastapi's checkInputs, where its own doc tests say nothing
    # about whether it works. Without this, fastapi and everything downstream of
    # it (openai, openapi-core, sqlframe) cannot build.
    inline-snapshot = prev.inline-snapshot.overridePythonAttrs (_old: {
      doCheck = false;
    });

    # backrefs' test_timeout asserts that a regex operation exceeds a wall-clock
    # timeout, which does not hold on every builder: it passes locally but fails
    # on CI runners with "DID NOT RAISE TimeoutError". backrefs is not in the
    # binary cache on the pinned nixpkgs, so it is built from source and the flake
    # test runs. It reaches us transitively through einops' check inputs, and the
    # failure cascades all the way up to pyright-check.
    backrefs = prev.backrefs.overridePythonAttrs (old: {
      disabledTests = (old.disabledTests or [ ]) ++ [ "test_timeout" ];
    });

    # These asynchronous kernel-disconnect tests are sensitive to load in the Nix
    # sandbox: orphan cleanup can miss its deadline, which also makes the companion
    # file-descriptor assertion report the sockets that are still being cleaned up.
    # jupyter-server reaches us through einops' check inputs, like backrefs above.
    jupyter-server = prev.jupyter-server.overridePythonAttrs (old: {
      disabledTests = (old.disabledTests or [ ]) ++ [
        "test_no_fd_leak_on_disconnect_with_orphaned_kernel_info_channel"
        "test_disconnect_resolves_orphaned_kernel_info_future"
      ];
    });

    # This dataset utility test downloads fixture archives from GitHub.
    ultralytics = prev.ultralytics.overridePythonAttrs (old: {
      disabledTests = (old.disabledTests or [ ]) ++ [ "test_data_utils" ];
    });

    # Isolate Valkey's Redis test server from existing services on Darwin hosts.
    valkey = prev.valkey.overridePythonAttrs (old: {
      # Darwin builds share the host's ports. The Redis test hook otherwise
      # retries forever when an existing service occupies its default port 6379.
      preCheck = (old.preCheck or "") + ''
        redisTestPort="$(${final.python.interpreter} - <<'PY'
        import socket
        with socket.socket() as server:
            server.bind(("127.0.0.1", 0))
            print(server.getsockname()[1])
        PY
        )"
        pytestFlagsArray+=("--valkey-url=valkey://127.0.0.1:$redisTestPort/0")
      '';
    });

    # mss runs screenshot tests through a virtual X server. They are not relevant
    # to ComfyUI's runtime dependency closure and can fail in a headless Nix build
    # sandbox. Remove this override once nixpkgs' mss checks are sandbox-independent.
    mss = prev.mss.overridePythonAttrs (_old: {
      doCheck = false;
    });

    # Disable filterpy tests on Darwin (test_hinfinity triggers BPT trap in pytest)
    filterpy = prev.filterpy.overridePythonAttrs (_old: {
      doCheck = false;
    });
  }
)
# Note: On Darwin, av uses ffmpeg 7.x and torchaudio uses ffmpeg 6.x.
# These versions are mutually incompatible for building. The resulting runtime
# warning about duplicate Objective-C classes is harmless in practice.

# Override av (PyAV) to use pre-built wheel for comfy_api_nodes compatibility
# Using wheels avoids FFmpeg version issues (wheels bundle their own FFmpeg)
# This fixes build failures when nixpkgs has FFmpeg 8.x (AVFMT_ALLOW_FLUSH removed)
#
# Keep this at 17.0.1 or newer.
# With the 17.0.0 wheel on Python 3.13,
# imageio's test_lagging_video_stream fails the build every time:
# a forked child that runs gc.collect() after a video was read never returns.
# 17.0.1 passes it.
#
# The bundled FFmpeg also keeps av independent of the caller's LD_LIBRARY_PATH.
# nixpkgs' av links the system FFmpeg, which loads libasound,
# and a libasound from a newer host glibc on LD_LIBRARY_PATH breaks `import av` at startup.
// lib.optionalAttrs (prev ? av) {
  av =
    let
      # Use platform-specific abi3 wheels from PyPI (av 17.0.1; cp311-abi3, so any Python >= 3.11)
      wheelSrc =
        if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then
          pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/02/28/167b291356c2cc315a2d62a95b0ceace72b5b0bf547de30b89313110f032/av-17.0.1-cp311-abi3-manylinux_2_28_x86_64.whl";
            hash = "sha256-xYxxv/2Tg5CMhWlaxh0xhMZorMsEpb0bJi4PuNCfYKU=";
          }
        else if pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then
          pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/a8/8b/8de3fd21c4b0b74d44337421abeab0e71462337fb6a28fff888e0c356cbd/av-17.0.1-cp311-abi3-manylinux_2_28_aarch64.whl";
            hash = "sha256-5u7oSvpI0OkyEEfNPk+s1EtAFJP2vcdT4uHR58nm0T4=";
          }
        else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isx86_64 then
          pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/4c/82/e7007dcef7bd2d2c377e2e85977701384f42d19fc808c2ccb3a99eaf58f2/av-17.0.1-cp311-abi3-macosx_11_0_x86_64.whl";
            hash = "sha256-mH9PRs6uTabGFNy9K4FJvp2/aAw7t6aEHFivnP9NkjA=";
          }
        else if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
          pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/6b/aa/858b09a08ea6f83f91be44b5a5adad13ae8d9ac8b80fda27e73c24bfb160/av-17.0.1-cp311-abi3-macosx_14_0_arm64.whl";
            hash = "sha256-2X9U5VsYp0kS9HnBl4qt0TQdONiS3ulbtcLy3M+nLzI=";
          }
        else
          # Fallback to source build for unsupported platforms
          null;
    in
    if wheelSrc != null then
      final.buildPythonPackage {
        pname = "av";
        version = "17.0.1";
        format = "wheel";
        src = wheelSrc;
        # Wheel contains bundled FFmpeg libraries
        dontBuild = true;
        dontConfigure = true;
        propagatedBuildInputs = [ final.numpy ];
        # Linux manylinux wheels need autoPatchelfHook to fix library paths
        nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
        buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
        ];
        pythonImportsCheck = [ "av" ];
        doCheck = false;
      }
    else
      # Fallback: try original package for unsupported platforms
      prev.av;
}

# Keep accelerate's tests compatible with our platform-specific torch wheels.
// lib.optionalAttrs (prev ? accelerate) {
  accelerate = prev.accelerate.overridePythonAttrs (old: {
    disabledTests =
      (old.disabledTests or [ ])
      # torch 2.10.0 inductor cannot run this test in the Nix sandbox.
      ++ lib.optionals (useCuda || useRocm || useXpu) [ "test_convert_to_fp32" ]
      # FSDP2 requires torch >= 2.6; Apple Silicon intentionally uses 2.5.1
      # for MPS stability. This test lacks a working version guard.
      ++ lib.optionals useDarwinArm64 [ "test_param_mapping_error_handling" ];
  });
}

# Disable failing timm test (torch dynamo/inductor cannot compile in the Nix sandbox)
# Only where torch comes from a wheel: against nixpkgs' own torch, timm comes from the binary cache.
// lib.optionalAttrs (wheelTorch && prev ? timm) {
  timm = prev.timm.overridePythonAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [ "test_kron" ];
    # test_optim needs setuptools at runtime (torch dynamo/inductor)
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      final.setuptools
      final.wheel
    ];
  });
}

# Relax xformers torch version requirement (relaxes torch version constraint)
# Limit build parallelism to prevent OOM during flash-attention CUDA kernel compilation
# (sm_90 CUTLASS kernels consume ~3GB RAM each)
// lib.optionalAttrs (prev ? xformers) {
  xformers = prev.xformers.overridePythonAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.pythonRelaxDepsHook ];
    pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "torch" ];
    preBuild = (old.preBuild or "") + ''
      export MAX_JOBS=2
    '';
  });
}

# Disable failing ffmpeg test for imageio (test_process_termination expects exit code 2 but gets 6)
// lib.optionalAttrs (prev ? imageio) {
  imageio = prev.imageio.overridePythonAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [ "test_process_termination" ];
  });
}

# torchsde's test suite costs ~3.5 minutes of every build of this flake, and it
# is statistical rather than functional: test_normality_conditional asserts a
# Kolmogorov-Smirnov p-value stays above 1e-5, so a borderline draw lands under
# it and fails the whole nixos-rebuild for an unrelated reason. Dropping the
# suite rather than just that test buys back the build time; pythonImportsCheck
# still runs, and ComfyUI only uses torchsde's samplers.
# See: https://github.com/utensils/comfyui-nix/issues/91
#
# Only where torch comes from a wheel: against nixpkgs' own torch,
# torchsde comes from the binary cache and its suite never runs here.
// lib.optionalAttrs (wheelTorch && prev ? torchsde) {
  torchsde = prev.torchsde.overridePythonAttrs (_old: {
    doCheck = false;
  });
}

# color-matcher - not in older nixpkgs, needed for KJNodes
// {
  "color-matcher" = final.buildPythonPackage rec {
    pname = "color-matcher";
    version = versions.vendored."color-matcher".version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = versions.vendored."color-matcher".url;
      hash = versions.vendored."color-matcher".hash;
    };
    propagatedBuildInputs = with final; [
      numpy
      pillow
      scipy
    ];
    doCheck = false;
    # Upstream wheel's Requires-Dist lists ddt/docutils/matplotlib (docs/tests)
    # and imageio (try/except-optional in io_handler.py) as mandatory runtime deps.
    # Only numpy + pillow are actually required at import time.
    dontCheckRuntimeDeps = true;
    pythonImportsCheck = [ "color_matcher" ];
  };
}

# facexlib - face processing library needed by PuLID
# Patched to support FACEXLIB_MODELPATH env var for read-only Nix store compatibility
// {
  facexlib = final.buildPythonPackage rec {
    pname = "facexlib";
    version = versions.vendored.facexlib.version;
    format = "wheel";
    src = pkgs.fetchurl {
      url = versions.vendored.facexlib.url;
      hash = versions.vendored.facexlib.hash;
    };
    dontBuild = true;
    dontConfigure = true;
    nativeBuildInputs = [ pkgs.gnused ];
    # facexlib's wheel names the PyPI opencv-python distribution, while nixpkgs
    # opencv4 provides the required cv2 module without matching distribution
    # metadata. Remove this when facexlib accepts a system OpenCV provider.
    pythonRemoveDeps = [ "opencv-python" ];
    # pythonRemoveDeps normally runs in postBuild, which this prebuilt wheel
    # skips. Remove this phase override when nixpkgs rewrites wheel metadata
    # before its runtime dependency check.
    preInstallPhases = [ "pythonRelaxDepsHook" ];
    propagatedBuildInputs = with final; [
      numpy
      opencv4
      pillow
      torch
      torchvision
      filterpy
      numba
      tqdm
    ];

    # Patch misc.py to respect FACEXLIB_MODELPATH environment variable
    # This allows redirecting model downloads away from the read-only Nix store
    postInstall = ''
      miscPy="$out/${final.python.sitePackages}/facexlib/utils/misc.py"
      if [[ -f "$miscPy" ]]; then
        sed -i 's|^ROOT_DIR = os.path.dirname.*|_DEFAULT_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))\nROOT_DIR = os.environ.get("FACEXLIB_MODELPATH", _DEFAULT_ROOT)|' "$miscPy"
      fi
    '';

    doCheck = false;
    pythonImportsCheck = [ "facexlib" ];
  };
}

# insightface - override to remove mxnet dependency for cross-platform support
# MXNet is only used for one CLI command (rec_add_mask_param.py) which we don't need.
# Face analysis uses ONNX Runtime which works on all platforms including macOS.
# This enables PuLID and other face-related nodes on macOS Apple Silicon.
// lib.optionalAttrs (prev ? insightface) {
  insightface = prev.insightface.overridePythonAttrs (old: {
    # Nix supplies the compiler; upstream's Homebrew probe requires an absent
    # `which` executable and can select a compiler outside the build sandbox.
    postPatch =
      (old.postPatch or "")
      + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        substituteInPlace setup.py \
          --replace-fail 'if platform.system() == "Darwin":' 'if False: # Compiler provided by Nix'
      '';

    # Remove mxnet from dependencies - it's only used for one legacy CLI command
    # and prevents the package from working on macOS (mxnet is Linux-only in nixpkgs)
    dependencies = builtins.filter (dep: dep.pname or "" != "mxnet") (old.dependencies or [ ]);

    # Skip the problematic CLI test that requires mxnet
    disabledTests = (old.disabledTests or [ ]) ++ [
      "test_cli" # Uses rec_add_mask_param which requires mxnet
    ];

    # Verify the package works without mxnet (face analysis uses onnxruntime)
    pythonImportsCheck = [
      "insightface"
      "insightface.app"
      "insightface.model_zoo"
    ];

    meta = (old.meta or { }) // {
      # Now works on all platforms since we removed mxnet dependency
      platforms = lib.platforms.unix;
    };
  });
}

# Segment Anything Model (SAM) - not in nixpkgs
// lib.optionalAttrs (prev ? torch) {
  segment-anything = final.buildPythonPackage {
    pname = "segment-anything";
    version = versions.vendored.segment-anything.version;
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "facebookresearch";
      repo = "segment-anything";
      rev = versions.vendored.segment-anything.rev;
      hash = versions.vendored.segment-anything.hash;
    };

    nativeBuildInputs = [
      final.setuptools
      final.wheel
    ];

    propagatedBuildInputs = [
      final.torch # Uses final.torch - automatically CUDA/ROCm when gpuSupport="cuda|rocm"
      final.torchvision
      final.numpy
      final.opencv4
      final.matplotlib
      final.pillow
    ];

    doCheck = false;
    pythonImportsCheck = [ "segment_anything" ];

    meta = {
      description = "Segment Anything Model (SAM) from Meta AI";
      homepage = "https://github.com/facebookresearch/segment-anything";
      license = lib.licenses.asl20;
    };
  };

  # Segment Anything Model 2 (SAM 2) - not in nixpkgs
  sam2 = final.buildPythonPackage {
    pname = "sam2";
    version = versions.vendored.sam2.version;
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "facebookresearch";
      repo = "sam2";
      rev = versions.vendored.sam2.rev;
      hash = versions.vendored.sam2.hash;
    };

    # Patch pyproject.toml to remove torch from build dependencies
    # (we provide torch via Nix, pip can't resolve our wheel's metadata)
    postPatch = ''
      sed -i '/"torch>=2.5.1"/d' pyproject.toml
    '';

    nativeBuildInputs = [
      final.setuptools
      final.wheel
      final.pythonRelaxDepsHook
    ];

    propagatedBuildInputs = [
      final.torch # Uses final.torch - automatically CUDA/ROCm when gpuSupport="cuda|rocm"
      final.torchvision
      final.numpy
      final.pillow
      final.tqdm
      final.hydra-core
      final.iopath
      final.sympy
    ];

    # Relax version checks
    pythonRelaxDeps = [
      "torchvision"
      "torch"
      "sympy"
    ];

    doCheck = false;
    pythonImportsCheck = [ "sam2" ];

    meta = {
      description = "Segment Anything Model 2 (SAM 2) from Meta AI";
      homepage = "https://github.com/facebookresearch/sam2";
      license = lib.licenses.asl20;
    };
  };
}
