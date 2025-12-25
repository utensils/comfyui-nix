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
    passthru.pythonDeps =
      ps: with ps; [
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

  # rgthree-comfy - Quality of life nodes
  rgthree-comfy = pkgs.stdenv.mkDerivation {
    pname = "rgthree-comfy";
    version = versions.customNodes.rgthree-comfy.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.rgthree-comfy.owner;
      repo = versions.customNodes.rgthree-comfy.repo;
      rev = versions.customNodes.rgthree-comfy.rev;
      hash = versions.customNodes.rgthree-comfy.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    # No additional Python dependencies needed
    passthru.pythonDeps = ps: [ ];

    meta = with lib; {
      description = "rgthree-comfy - Quality of life nodes for ComfyUI";
      homepage = "https://github.com/rgthree/rgthree-comfy";
      license = licenses.mit;
    };
  };

  # KJNodes - Utility nodes
  kjnodes = pkgs.stdenv.mkDerivation {
    pname = "comfyui-kjnodes";
    version = versions.customNodes.kjnodes.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.kjnodes.owner;
      repo = versions.customNodes.kjnodes.repo;
      rev = versions.customNodes.kjnodes.rev;
      hash = versions.customNodes.kjnodes.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    # Python dependencies required by KJNodes
    passthru.pythonDeps =
      ps: with ps; [
        color-matcher
        mss
      ];

    meta = with lib; {
      description = "ComfyUI KJNodes - Various utility nodes";
      homepage = "https://github.com/kijai/ComfyUI-KJNodes";
      license = licenses.gpl3;
    };
  };

in
{
  inherit impact-pack rgthree-comfy kjnodes;
}
