{
  pkgs,
  versions,
  cudaSupport ? false,
}:
let
  lib = pkgs.lib;
in
final: prev:
lib.optionalAttrs (prev ? torch) {
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
      lib.optionals (prev ? torch) [ final.torch ]
      ++ lib.optionals (prev ? torchvision) [ final.torchvision ]
      ++ lib.optionals (prev ? safetensors) [ final.safetensors ]
      ++ lib.optionals (prev ? numpy) [ final.numpy ]
      ++ lib.optionals (prev ? einops) [ final.einops ]
      ++ lib.optionals (prev ? typing-extensions) [ final.typing-extensions ];
    pythonImportsCheck = [ ];
    doCheck = false;
  };
}
