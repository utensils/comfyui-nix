# Custom node packages for ComfyUI
#
# These are pre-packaged custom nodes with their source code.
# Python dependencies are provided by the main ComfyUI environment.
#
# Users can reference these in their NixOS config:
#
#   services.comfyui.customNodes = {
#     impact-pack = comfyui-nix.customNodes.impact-pack;
#   };
#
{
  pkgs,
  lib,
  python,
  versions,
}:
let
  # Impact Pack custom node
  impact-pack = pkgs.stdenv.mkDerivation {
    pname = "comfyui-impact-pack";
    version = versions.customNodes.impact-pack.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.impact-pack.owner;
      repo = versions.customNodes.impact-pack.repo;
      rev = versions.customNodes.impact-pack.rev;
      hash = versions.customNodes.impact-pack.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    # Python dependencies required by Impact Pack
    passthru.pythonDeps = ps: with ps; [
      scikit-image
      piexif
      scipy
      numpy
      opencv4
      matplotlib
      dill
      segment-anything
      sam2
    ];

    meta = with lib; {
      description = "ComfyUI Impact Pack - Detection, segmentation, and more";
      homepage = "https://github.com/ltdrdata/ComfyUI-Impact-Pack";
      license = licenses.gpl3;
    };
  };

in
{
  inherit impact-pack;
}
