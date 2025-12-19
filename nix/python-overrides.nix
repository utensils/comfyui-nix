{ pkgs, versions }:
final: prev: {
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
    propagatedBuildInputs = with final; [
      torch
      torchvision
      safetensors
      numpy
      einops
      typing-extensions
    ];
    pythonImportsCheck = [ ];
    doCheck = false;
  };
}
