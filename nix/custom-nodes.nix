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

    # Convert CRLF to LF and patch __init__.py to use WEB_DIRECTORY
    # instead of shutil.copytree (which fails with read-only Nix store)
    postPatch = ''
      # Convert line endings
      sed -i 's/\r$//' __init__.py py/power_prompt.py

      # Remove shutil import and PromptServer import
      sed -i '/^import shutil$/d' __init__.py
      sed -i '/^from server import PromptServer$/d' __init__.py

      # Replace the copytree logic with WEB_DIRECTORY
      sed -i '/^DIR_WEB_JS=/,/^shutil.copytree/d' __init__.py
      sed -i '/^DIR_PY=/a # Use ComfyUI'"'"'s WEB_DIRECTORY for serving web assets (Nix-compatible)' __init__.py
      sed -i '/WEB_DIRECTORY for serving/a WEB_DIRECTORY = "./js"' __init__.py

      # Fix SyntaxWarning: invalid escape sequence in power_prompt.py
      # Change pattern='<lora:...' to pattern=r'<lora:...'
      sed -i "s/pattern='<lora:/pattern=r'<lora:/" py/power_prompt.py
    '';

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

  # ComfyUI-GGUF - GGUF quantization support for native ComfyUI models
  gguf = pkgs.stdenv.mkDerivation {
    pname = "comfyui-gguf";
    version = versions.customNodes.gguf.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.gguf.owner;
      repo = versions.customNodes.gguf.repo;
      rev = versions.customNodes.gguf.rev;
      hash = versions.customNodes.gguf.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    # Python dependencies required by ComfyUI-GGUF
    passthru.pythonDeps =
      ps: with ps; [
        gguf
        sentencepiece
        protobuf
      ];

    meta = with lib; {
      description = "ComfyUI-GGUF - GGUF quantization support for native ComfyUI models";
      homepage = "https://github.com/city96/ComfyUI-GGUF";
      license = licenses.asl20;
    };
  };

  # ComfyUI-LTXVideo - LTX-Video support for ComfyUI
  ltxvideo = pkgs.stdenv.mkDerivation {
    pname = "comfyui-ltxvideo";
    version = versions.customNodes.ltxvideo.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.ltxvideo.owner;
      repo = versions.customNodes.ltxvideo.repo;
      rev = versions.customNodes.ltxvideo.rev;
      hash = versions.customNodes.ltxvideo.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    passthru.pythonDeps =
      ps: with ps; [
        diffusers
        einops
        huggingface-hub
        transformers
        timm
      ];

    meta = with lib; {
      description = "ComfyUI-LTXVideo - LTX-Video support for ComfyUI";
      homepage = "https://github.com/Lightricks/ComfyUI-LTXVideo";
      license = licenses.asl20;
    };
  };

  # ComfyUI-Florence2 - Microsoft Florence2 VLM inference
  florence2 = pkgs.stdenv.mkDerivation {
    pname = "comfyui-florence2";
    version = versions.customNodes.florence2.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.florence2.owner;
      repo = versions.customNodes.florence2.repo;
      rev = versions.customNodes.florence2.rev;
      hash = versions.customNodes.florence2.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    passthru.pythonDeps =
      ps: with ps; [
        transformers
        matplotlib
        timm
        pillow
        peft
        accelerate
      ];

    meta = with lib; {
      description = "ComfyUI-Florence2 - Microsoft Florence2 VLM inference";
      homepage = "https://github.com/kijai/ComfyUI-Florence2";
      license = licenses.mit;
    };
  };

  # ComfyUI_bitsandbytes_NF4 - NF4 quantization support
  bitsandbytes-nf4 = pkgs.stdenv.mkDerivation {
    pname = "comfyui-bitsandbytes-nf4";
    version = versions.customNodes.bitsandbytes-nf4.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.bitsandbytes-nf4.owner;
      repo = versions.customNodes.bitsandbytes-nf4.repo;
      rev = versions.customNodes.bitsandbytes-nf4.rev;
      hash = versions.customNodes.bitsandbytes-nf4.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    passthru.pythonDeps =
      ps: with ps; [
        bitsandbytes
      ];

    meta = with lib; {
      description = "ComfyUI_bitsandbytes_NF4 - NF4 quantization for Flux models";
      homepage = "https://github.com/comfyanonymous/ComfyUI_bitsandbytes_NF4";
      license = licenses.agpl3Only;
    };
  };

  # x-flux-comfyui - XLabs Flux LoRA and ControlNet
  x-flux = pkgs.stdenv.mkDerivation {
    pname = "x-flux-comfyui";
    version = versions.customNodes.x-flux.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.x-flux.owner;
      repo = versions.customNodes.x-flux.repo;
      rev = versions.customNodes.x-flux.rev;
      hash = versions.customNodes.x-flux.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    passthru.pythonDeps =
      ps: with ps; [
        gitpython
        einops
        transformers
        diffusers
        sentencepiece
        opencv4
      ];

    meta = with lib; {
      description = "x-flux-comfyui - XLabs Flux LoRA and ControlNet support";
      homepage = "https://github.com/XLabs-AI/x-flux-comfyui";
      license = licenses.asl20;
    };
  };

  # ComfyUI-MMAudio - Audio generation from video
  mmaudio = pkgs.stdenv.mkDerivation {
    pname = "comfyui-mmaudio";
    version = versions.customNodes.mmaudio.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.mmaudio.owner;
      repo = versions.customNodes.mmaudio.repo;
      rev = versions.customNodes.mmaudio.rev;
      hash = versions.customNodes.mmaudio.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    passthru.pythonDeps =
      ps: with ps; [
        librosa
        torchdiffeq
        einops
        timm
        omegaconf
        open-clip-torch
        accelerate
        ftfy
      ];

    meta = with lib; {
      description = "ComfyUI-MMAudio - Synchronized audio generation from video";
      homepage = "https://github.com/kijai/ComfyUI-MMAudio";
      license = licenses.mit;
    };
  };

  # PuLID_ComfyUI - PuLID face ID for ComfyUI
  pulid = pkgs.stdenv.mkDerivation {
    pname = "pulid-comfyui";
    version = versions.customNodes.pulid.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.pulid.owner;
      repo = versions.customNodes.pulid.repo;
      rev = versions.customNodes.pulid.rev;
      hash = versions.customNodes.pulid.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    # Face analysis dependencies - insightface works on all platforms via onnxruntime
    # (mxnet dependency is removed in python-overrides.nix for cross-platform support)
    passthru.pythonDeps =
      ps: with ps; [
        onnxruntime
        ftfy
        timm
        insightface
        facexlib
      ];

    meta = with lib; {
      description = "PuLID_ComfyUI - PuLID face ID implementation for ComfyUI";
      homepage = "https://github.com/cubiq/PuLID_ComfyUI";
      license = licenses.asl20;
    };
  };

  # ComfyUI-WanVideoWrapper - WanVideo wrapper for ComfyUI
  wanvideo = pkgs.stdenv.mkDerivation {
    pname = "comfyui-wanvideo";
    version = versions.customNodes.wanvideo.version;

    src = pkgs.fetchFromGitHub {
      owner = versions.customNodes.wanvideo.owner;
      repo = versions.customNodes.wanvideo.repo;
      rev = versions.customNodes.wanvideo.rev;
      hash = versions.customNodes.wanvideo.hash;
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      runHook postInstall
    '';

    passthru.pythonDeps =
      ps: with ps; [
        ftfy
        accelerate
        peft
        diffusers
        sentencepiece
        protobuf
        gguf
        opencv4
        scipy
        einops
      ];

    meta = with lib; {
      description = "ComfyUI-WanVideoWrapper - WanVideo wrapper for ComfyUI";
      homepage = "https://github.com/kijai/ComfyUI-WanVideoWrapper";
      license = licenses.asl20;
    };
  };

in
{
  inherit
    impact-pack
    rgthree-comfy
    kjnodes
    gguf
    ltxvideo
    florence2
    bitsandbytes-nf4
    x-flux
    mmaudio
    pulid
    wanvideo
    ;
}
