{
  pkgs,
  versions,
  gpuSupport ? "none", # "none", "cuda", "rocm", "xpu"
}:
let
  lib = pkgs.lib;
  useCuda = gpuSupport == "cuda" && pkgs.stdenv.isLinux;
  useRocm = gpuSupport == "rocm" && pkgs.stdenv.isLinux;
  # Intel XPU wheels are Linux x86_64 only (no aarch64 upstream)
  useXpu = gpuSupport == "xpu" && pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isx86_64;
  useDarwinArm64 = pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.isAarch64;
  sentencepieceNoGperf = pkgs.sentencepiece.override { withGPerfTools = false; };

  # Pre-built PyTorch CUDA wheels from pytorch.org
  # These avoid compiling PyTorch from source (which requires 30-60GB RAM and hours of build time)
  # The wheels bundle CUDA 12.8 libraries, so no separate CUDA toolkit needed at runtime
  cudaWheels = versions.pytorchWheels.cu128;

  # Pre-built PyTorch ROCm wheels from pytorch.org
  # These avoid compiling PyTorch from source (which requires 30-60GB RAM and hours of build time)
  rocmWheels = versions.pytorchWheels.rocm71;

  # Pre-built PyTorch XPU wheels from pytorch.org (Intel oneAPI / SYCL)
  # Unlike CUDA/ROCm, the XPU torch wheel does NOT bundle its SYCL / MKL /
  # Intel compiler runtimes — they ship as ~20 separate PyPI wheels declared
  # in Requires-Dist. All pinned in versions.xpuRuntime and packaged below.
  # Host still provides Level Zero loader + Intel compute-runtime at runtime.
  xpuWheels = versions.pytorchWheels.xpu;

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
  darwinWheels = versions.pytorchWheels.darwinArm64;

  # Common build inputs for PyTorch wheels (manylinux compatibility)
  wheelBuildInputs = [
    pkgs.stdenv.cc.cc.lib
    pkgs.zlib
    pkgs.libGL
    pkgs.glib
  ];

  # CUDA libraries needed by PyTorch wheels (for auto-patchelf)
  cudaLibs = pkgs.lib.optionals useCuda (
    with pkgs.cudaPackages;
    [
      cuda_cudart # libcudart.so.12
      cuda_cupti # libcupti.so.12
      libcublas # libcublas.so.12, libcublasLt.so.12
      libcufft # libcufft.so.11
      libcurand # libcurand.so.10
      libcusolver # libcusolver.so.11
      libcusparse # libcusparse.so.12
      libcusparse_lt # libcusparseLt.so.0 (structured sparsity, new in cu128)
      libcufile # libcufile.so.0 (GPU Direct Storage, new in cu128)
      libnvshmem # libnvshmem_host.so.3 (multi-GPU shared memory, new in cu128)
      cudnn # libcudnn.so.9
      nccl # libnccl.so.2
      cuda_nvrtc # libnvrtc.so.12
    ]
  );

  # ROCm libraries needed by PyTorch wheels (for auto-patchelf)
  # The wheels bundle ROCm libraries internally; only compression libs are needed externally
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
# The wheels bundle CUDA libraries internally, providing full GPU support
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

    # Remove nvidia-* and triton dependencies from wheel metadata
    # These are provided by nixpkgs cudaPackages, not PyPI packages
    postInstall = ''
      for metadata in "$out/${final.python.sitePackages}"/torch-*.dist-info/METADATA; do
        if [[ -f "$metadata" ]]; then
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
    ];
    # Don't check for CUDA at import time (requires GPU)
    pythonImportsCheck = [ ];
    doCheck = false;

    # Passthru attributes expected by downstream packages (xformers, bitsandbytes, etc.)
    # The wheel bundles CUDA 12.8 and supports all GPU architectures
    passthru = {
      cudaSupport = true;
      rocmSupport = false;
      # All architectures supported by pre-built wheel (Pascal through Blackwell)
      cudaCapabilities = [
        "6.1"
        "7.0"
        "7.5"
        "8.0"
        "8.6"
        "8.9"
        "9.0"
        "10.0" # Blackwell (B100/B200 data center)
        "12.0" # Blackwell (RTX 50xx consumer)
      ];
      # Provide cudaPackages for packages that need it (use default version)
      cudaPackages = pkgs.cudaPackages;
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
    propagatedBuildInputs = with final; [
      filelock
      typing-extensions
      sympy
      networkx
      jinja2
      fsspec
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

    # Ignore torch libs (loaded via Python import)
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
    propagatedBuildInputs = with final; [
      torch
      numpy
      pillow
    ];
    pythonImportsCheck = [ ];
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
      version = versions.xpuRuntime.triton-xpu.version;
      format = "wheel";
      src = pkgs.fetchurl {
        url = versions.xpuRuntime.triton-xpu.url;
        hash = versions.xpuRuntime.triton-xpu.hash;
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
        ])
        ++ [ tritonXpu ];
      propagatedNativeBuildInputs = [ intelOneapiRuntime ];
      pythonImportsCheck = [ ];
      doCheck = false;
      dontCheckRuntimeDeps = true; # Intel wheel pip names use hyphens/underscores inconsistently

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
// lib.optionalAttrs (pkgs.stdenv.isDarwin && prev ? sentencepiece) {
  sentencepiece = prev.sentencepiece.overridePythonAttrs (old: {
    buildInputs = [ sentencepieceNoGperf.dev ];
    nativeBuildInputs = old.nativeBuildInputs or [ ];
  });
}
# Note: On Darwin, av uses ffmpeg 7.x and torchaudio uses ffmpeg 6.x.
# These versions are mutually incompatible for building. The resulting runtime
# warning about duplicate Objective-C classes is harmless in practice.

# Override av (PyAV) to use pre-built wheel for comfy_api_nodes compatibility
# Using wheels avoids FFmpeg version issues (wheels bundle their own FFmpeg)
# This fixes build failures when nixpkgs has FFmpeg 8.x (AVFMT_ALLOW_FLUSH removed)
// lib.optionalAttrs (prev ? av) {
  av =
    let
      # Use platform-specific wheels from PyPI (av 14.2.0, Python 3.12)
      wheelSrc =
        if pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isx86_64 then
          pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/ed/e8/cf60f3fcde3d0eedee3e9ff66b674a9b85bffc907dccebbc56fb5ac4a954/av-14.2.0-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
            hash = "sha256-FMXwCwtg0SesDN5Gpbzptn6QW6kwM/3UiuVQwMBdUbg=";
          }
        else if pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isAarch64 then
          pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/d3/c3/a174388d393f1564ad4c1b8300eb4f3e972851a4d392c1eba66a6848749e/av-14.2.0-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
            hash = "sha256-iXvppmXDZd/PDBCiV/4iNSHtTTtHjmslj1X3zRP97dM=";
          }
        else if pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.isx86_64 then
          pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/89/36/787af232db9b3d5bbd5eb4d1d46c51b9669cba5b2273bb68a445cb281db8/av-14.2.0-cp312-cp312-macosx_12_0_x86_64.whl";
            hash = "sha256-amqunheq5PKpczWCXApwG3Y7cqr4lCjypwu9yDtkrSM=";
          }
        else if pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
          pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/5b/88/b56f5e5fa2486ee51413b043e08c7f5ed119c1e10b72725593da30adc28f/av-14.2.0-cp312-cp312-macosx_12_0_arm64.whl";
            hash = "sha256-o9o+lRFIKR1w9ss/s3v4FYCwGZLpFe8QMBCOQHb2LTg=";
          }
        else
          # Fallback to source build for unsupported platforms
          null;
    in
    if wheelSrc != null then
      final.buildPythonPackage {
        pname = "av";
        version = "14.2.0";
        format = "wheel";
        src = wheelSrc;
        # Wheel contains bundled FFmpeg libraries
        dontBuild = true;
        dontConfigure = true;
        propagatedBuildInputs = [ final.numpy ];
        # Linux manylinux wheels need autoPatchelfHook to fix library paths
        nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];
        buildInputs = lib.optionals pkgs.stdenv.isLinux [
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

# Disable tests for open-clip-torch (they hang waiting for model downloads)
// lib.optionalAttrs (prev ? open-clip-torch) {
  open-clip-torch = prev.open-clip-torch.overridePythonAttrs (old: {
    doCheck = false;
  });
}

# Disable tests for albumentations (very slow test suite, well-tested upstream)
// lib.optionalAttrs (prev ? albumentations) {
  albumentations = prev.albumentations.overridePythonAttrs (old: {
    doCheck = false;
  });
}

# Fix torchmetrics build: nixpkgs torchmetrics doesn't declare setuptools as a build backend
# dependency, so PEP517 build fails with "Cannot import 'setuptools.build_meta'".
// lib.optionalAttrs (prev ? torchmetrics) {
  torchmetrics = prev.torchmetrics.overridePythonAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      final.setuptools
      final.wheel
    ];
  });
}

# Disable accelerate test that fails with torch 2.10.0 inductor in Nix sandbox
// lib.optionalAttrs ((useCuda || useRocm || useXpu) && (prev ? accelerate)) {
  accelerate = prev.accelerate.overridePythonAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [ "test_convert_to_fp32" ];
  });
}

# Disable failing timm test (torch dynamo/inductor test needs setuptools at runtime)
// lib.optionalAttrs (prev ? timm) {
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
# (sm_90 CUTLASS kernels with CUDA 12.8 consume ~3GB RAM each)
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

# Disable filterpy tests on Darwin (test_hinfinity triggers BPT trap in pytest)
// lib.optionalAttrs (prev ? filterpy) {
  filterpy = prev.filterpy.overridePythonAttrs (old: {
    doCheck = if pkgs.stdenv.isDarwin then false else (old.doCheck or true);
  });
}

# Fix bitsandbytes build - needs ninja for wheel building phase
// lib.optionalAttrs (prev ? bitsandbytes) {
  bitsandbytes = prev.bitsandbytes.overridePythonAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.ninja ];
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
    propagatedBuildInputs = with final; [
      numpy
      opencv4
      pillow
      torch
      torchvision
      filterpy
      numba
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
