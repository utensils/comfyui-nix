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
