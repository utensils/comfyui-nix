{
  pkgs,
  versions,
  cudaSupport ? false,
}:
let
  lib = pkgs.lib;
  useCuda = cudaSupport && pkgs.stdenv.isLinux;
  useDarwinArm64 = pkgs.stdenv.isDarwin && pkgs.stdenv.hostPlatform.isAarch64;
  sentencepieceNoGperf = pkgs.sentencepiece.override { withGPerfTools = false; };

  # Pre-built PyTorch CUDA wheels from pytorch.org
  # These avoid compiling PyTorch from source (which requires 30-60GB RAM and hours of build time)
  # The wheels bundle CUDA 12.4 libraries, so no separate CUDA toolkit needed at runtime
  cudaWheels = versions.pytorchWheels.cu124;

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
      cudnn # libcudnn.so.9
      nccl # libnccl.so.2
      cuda_nvrtc # libnvrtc.so.12
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
    # The wheel bundles CUDA 12.4 and supports all GPU architectures
    passthru = {
      cudaSupport = true;
      rocmSupport = false;
      # All architectures supported by pre-built wheel (Pascal through Hopper)
      cudaCapabilities = [
        "6.1"
        "7.0"
        "7.5"
        "8.0"
        "8.6"
        "8.9"
        "9.0"
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
    ] # Use final.torch - will be CUDA torch when cudaSupport=true
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

# Disable failing timm test (torch dynamo/inductor test needs setuptools at runtime)
// lib.optionalAttrs (prev ? timm) {
  timm = prev.timm.overridePythonAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [ "test_kron" ];
  });
}

# Relax xformers torch version requirement (0.0.30 wants torch>=2.7, we have 2.5.1)
// lib.optionalAttrs (prev ? xformers) {
  xformers = prev.xformers.overridePythonAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.pythonRelaxDepsHook ];
    pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "torch" ];
  });
}

# Disable failing ffmpeg test for imageio (test_process_termination expects exit code 2 but gets 6)
// lib.optionalAttrs (prev ? imageio) {
  imageio = prev.imageio.overridePythonAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [ "test_process_termination" ];
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
      final.torch # Uses final.torch - automatically CUDA when cudaSupport=true
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
      final.torch # Uses final.torch - automatically CUDA when cudaSupport=true
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
