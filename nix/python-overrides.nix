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
lib.optionalAttrs (prev ? torch) (
  let
    torchForCuda = if useCuda && prev ? torchWithCuda then prev.torchWithCuda else final.torch;
  in
  {
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
        lib.optionals (prev ? torch) [ torchForCuda ]
        ++ lib.optionals (prev ? torchvision) [ final.torchvision ]
        ++ lib.optionals (prev ? safetensors) [ final.safetensors ]
        ++ lib.optionals (prev ? numpy) [ final.numpy ]
        ++ lib.optionals (prev ? einops) [ final.einops ]
        ++ lib.optionals (prev ? typing-extensions) [ final.typing-extensions ];
      pythonImportsCheck = [ ];
      doCheck = false;
    };
  }
  // lib.optionalAttrs (useCuda && prev ? torchWithCuda) (
    (lib.optionalAttrs (prev ? torchvision) {
      torchvision = prev.torchvision.override { torch = prev.torchWithCuda; };
    })
    // (lib.optionalAttrs (prev ? torchaudio) {
      torchaudio = prev.torchaudio.override { torch = prev.torchWithCuda; };
    })
    // (lib.optionalAttrs (prev ? torchsde) {
      torchsde = prev.torchsde.override { torch = prev.torchWithCuda; };
    })
    // (lib.optionalAttrs (prev ? kornia) {
      kornia = prev.kornia.override { torch = prev.torchWithCuda; };
    })
  )
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

# Override av (PyAV) to version 14.2.0 for comfy_api_nodes compatibility
// lib.optionalAttrs (prev ? av) {
  av = prev.av.overrideAttrs (old: rec {
    version = "14.2.0";
    src = pkgs.fetchFromGitHub {
      owner = "PyAV-Org";
      repo = "PyAV";
      tag = "v${version}";
      hash = "sha256-hgbQTkyRdZW8ik0az3qilLdPcuebjs6uWOygCaLhxCg=";
    };
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

# Segment Anything Model (SAM) - not in nixpkgs
// lib.optionalAttrs (prev ? torch) (
  let
    torchPkg = if useCuda && prev ? torchWithCuda then prev.torchWithCuda else final.torch;
    torchvisionPkg = if useCuda && prev ? torchWithCuda then final.torchvision else final.torchvision;
  in
  {
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
        torchPkg
        torchvisionPkg
        final.numpy
        final.opencv4
        final.matplotlib
        final.pillow
      ];

      # Skip conflict check - we're using the correct torch variant
      catchConflicts = false;
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
        torchPkg
        torchvisionPkg
        final.numpy
        final.pillow
        final.tqdm
        final.hydra-core
        final.iopath
      ];

      # Relax version checks - nixpkgs torchvision is 0.20.1a0 which satisfies >=0.20.1
      pythonRelaxDeps = [ "torchvision" ];

      # Skip conflict check - we're using the correct torch variant
      catchConflicts = false;
      doCheck = false;
      pythonImportsCheck = [ "sam2" ];

      meta = {
        description = "Segment Anything Model 2 (SAM 2) from Meta AI";
        homepage = "https://github.com/facebookresearch/sam2";
        license = lib.licenses.asl20;
      };
    };
  }
)
