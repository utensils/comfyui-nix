{
  pkgs,
  versions,
  cudaSupport ? false,
}:
let
  lib = pkgs.lib;
  useCuda = cudaSupport && pkgs.stdenv.isLinux;
  sentencepieceNoGperf = pkgs.sentencepiece.override { withGPerfTools = false; };
in
final: prev:
# CUDA torch base override - this is the key fix!
# By overriding torch at the base level, ALL packages that reference self.torch
# will automatically get the CUDA version. This prevents torch version collisions.
lib.optionalAttrs (useCuda && prev ? torch) {
  torch = prev.torch.override { cudaSupport = true; };
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
    propagatedBuildInputs =
      [ final.torch ] # Use final.torch - will be CUDA torch when cudaSupport=true
      ++ lib.optionals (prev ? torchvision) [ final.torchvision ]
      ++ lib.optionals (prev ? safetensors) [ final.safetensors ]
      ++ lib.optionals (prev ? numpy) [ final.numpy ]
      ++ lib.optionals (prev ? einops) [ final.einops ]
      ++ lib.optionals (prev ? typing-extensions) [ final.typing-extensions ];
    pythonImportsCheck = [ ];
    doCheck = false;
  };
}
# CUDA-specific package overrides - use final.torch (our overridden CUDA torch)
// lib.optionalAttrs useCuda (
  lib.optionalAttrs (prev ? torchvision) {
    torchvision = prev.torchvision.override { torch = final.torch; };
  }
  // lib.optionalAttrs (prev ? torchaudio) {
    torchaudio = prev.torchaudio.override { torch = final.torch; };
  }
  // lib.optionalAttrs (prev ? torchsde) {
    torchsde = prev.torchsde.override { torch = final.torch; };
  }
  // lib.optionalAttrs (prev ? kornia) {
    kornia = prev.kornia.override { torch = final.torch; };
  }
  // lib.optionalAttrs (prev ? accelerate) {
    accelerate = prev.accelerate.override { torch = final.torch; };
  }
  // lib.optionalAttrs (prev ? timm) {
    timm = prev.timm.override { torch = final.torch; };
  }
  // lib.optionalAttrs (prev ? peft) {
    peft = prev.peft.override { torch = final.torch; };
  }
  // lib.optionalAttrs (prev ? torchdiffeq) {
    torchdiffeq = prev.torchdiffeq.override { torch = final.torch; };
  }
  // lib.optionalAttrs (prev ? open-clip-torch) {
    open-clip-torch = prev.open-clip-torch.override { torch = final.torch; };
  }
)
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
    propagatedBuildInputs = with final; [
      numpy
      opencv4
      pillow
      torch
      torchvision
      filterpy
      numba
    ];
    doCheck = false;
    pythonImportsCheck = [ "facexlib" ];
  };
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
    ];

    # Relax version checks - nixpkgs torchvision is 0.20.1a0 which satisfies >=0.20.1
    pythonRelaxDeps = [ "torchvision" ];

    doCheck = false;
    pythonImportsCheck = [ "sam2" ];

    meta = {
      description = "Segment Anything Model 2 (SAM 2) from Meta AI";
      homepage = "https://github.com/facebookresearch/sam2";
      license = lib.licenses.asl20;
    };
  };
}
