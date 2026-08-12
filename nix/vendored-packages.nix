{
  pkgs,
  python,
  versions,
}:
let
  mkWheel =
    {
      pname,
      version,
      url,
      hash,
      propagatedBuildInputs ? [ ],
      pythonRelaxDeps ? [ ],
    }:
    python.pkgs.buildPythonPackage {
      inherit
        pname
        version
        propagatedBuildInputs
        pythonRelaxDeps
        ;
      format = "wheel";
      src = pkgs.fetchurl { inherit url hash; };
      doCheck = false;
    };

  workflowTemplatesCore = mkWheel {
    pname = "comfyui-workflow-templates-core";
    version = versions.vendored.workflowTemplatesCore.version;
    url = versions.vendored.workflowTemplatesCore.url;
    hash = versions.vendored.workflowTemplatesCore.hash;
  };

  workflowTemplatesJson = mkWheel {
    pname = "comfyui-workflow-templates-json";
    version = versions.vendored.workflowTemplatesJson.version;
    url = versions.vendored.workflowTemplatesJson.url;
    hash = versions.vendored.workflowTemplatesJson.hash;
  };

  workflowTemplatesMediaApi = mkWheel {
    pname = "comfyui-workflow-templates-media-api";
    version = versions.vendored.workflowTemplatesMediaApi.version;
    url = versions.vendored.workflowTemplatesMediaApi.url;
    hash = versions.vendored.workflowTemplatesMediaApi.hash;
  };

  workflowTemplatesMediaVideo = mkWheel {
    pname = "comfyui-workflow-templates-media-video";
    version = versions.vendored.workflowTemplatesMediaVideo.version;
    url = versions.vendored.workflowTemplatesMediaVideo.url;
    hash = versions.vendored.workflowTemplatesMediaVideo.hash;
  };

  workflowTemplatesMediaImage = mkWheel {
    pname = "comfyui-workflow-templates-media-image";
    version = versions.vendored.workflowTemplatesMediaImage.version;
    url = versions.vendored.workflowTemplatesMediaImage.url;
    hash = versions.vendored.workflowTemplatesMediaImage.hash;
  };

  workflowTemplatesMediaOther = mkWheel {
    pname = "comfyui-workflow-templates-media-other";
    version = versions.vendored.workflowTemplatesMediaOther.version;
    url = versions.vendored.workflowTemplatesMediaOther.url;
    hash = versions.vendored.workflowTemplatesMediaOther.hash;
  };

  workflowTemplatesMediaAssets01 = mkWheel {
    pname = "comfyui-workflow-templates-media-assets-01";
    version = versions.vendored.workflowTemplatesMediaAssets01.version;
    url = versions.vendored.workflowTemplatesMediaAssets01.url;
    hash = versions.vendored.workflowTemplatesMediaAssets01.hash;
  };

  # comfy-angle ships platform-specific wheels (native libEGL/libGLESv2).
  # No wheel exists for x86_64-darwin; consumers must handle null.
  angleWheel =
    let
      p = pkgs.stdenv.hostPlatform;
    in
    if p.isLinux && p.isx86_64 then
      versions.vendored.comfyAngle.linuxX86_64
    else if p.isLinux && p.isAarch64 then
      versions.vendored.comfyAngle.linuxAarch64
    else if p.isDarwin && p.isAarch64 then
      versions.vendored.comfyAngle.darwinArm64
    else
      null;

  # Select a platform wheel (with native libs) when one exists, otherwise the
  # pure-Python any-wheel. Used for comfy-kitchen and comfy-aimdo (issue #66).
  selectPlatformWheel =
    wheels:
    let
      p = pkgs.stdenv.hostPlatform;
    in
    if p.isLinux && p.isx86_64 && wheels ? linuxX86_64 then
      wheels.linuxX86_64
    else if p.isLinux && p.isAarch64 && wheels ? linuxAarch64 then
      wheels.linuxAarch64
    else
      wheels.any;

  # Wheel with bundled native .so files: run autoPatchelf on Linux so their
  # glibc/libstdc++ DT_NEEDED entries resolve against the Nix store. CUDA
  # driver libraries are dlopen'ed at runtime, not linked, so nothing further
  # is needed for them. comfy-kitchen >= 0.2.26 ships a HIP backend that links
  # libamdhip64.so.7 directly; on ROCm builds torch loads that library into
  # the process before comfy-kitchen imports, and on other builds the HIP
  # backend is unused, so the unresolved dependency is safe to ignore.
  mkNativeWheel =
    {
      pname,
      version,
      url,
      hash,
    }:
    python.pkgs.buildPythonPackage {
      inherit pname version;
      format = "wheel";
      src = pkgs.fetchurl { inherit url hash; };
      doCheck = false;
      nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];
      buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib ];
      autoPatchelfIgnoreMissingDeps = [ "libamdhip64.so.7" ];
    };
in
rec {
  comfyuiFrontendPackage = mkWheel {
    pname = "comfyui-frontend-package";
    version = versions.vendored.frontendPackage.version;
    url = versions.vendored.frontendPackage.url;
    hash = versions.vendored.frontendPackage.hash;
  };

  comfyuiWorkflowTemplates = mkWheel {
    pname = "comfyui-workflow-templates";
    version = versions.vendored.workflowTemplates.version;
    url = versions.vendored.workflowTemplates.url;
    hash = versions.vendored.workflowTemplates.hash;
    propagatedBuildInputs = [
      workflowTemplatesCore
      workflowTemplatesJson
      workflowTemplatesMediaApi
      workflowTemplatesMediaVideo
      workflowTemplatesMediaImage
      workflowTemplatesMediaOther
      workflowTemplatesMediaAssets01
    ];
  };

  comfyuiEmbeddedDocs = mkWheel {
    pname = "comfyui-embedded-docs";
    version = versions.vendored.embeddedDocs.version;
    url = versions.vendored.embeddedDocs.url;
    hash = versions.vendored.embeddedDocs.hash;
  };

  comfyuiManager = mkWheel {
    pname = "comfyui-manager";
    version = versions.vendored.manager.version;
    url = versions.vendored.manager.url;
    hash = versions.vendored.manager.hash;
    propagatedBuildInputs = with python.pkgs; [
      chardet
      gitpython
      huggingface-hub
      pygithub
      rich
      toml
      transformers
      typer
      typing-extensions
      uv
    ];
  };

  comfyKitchen = mkNativeWheel {
    pname = "comfy-kitchen";
    version = versions.vendored.comfyKitchen.version;
    inherit (selectPlatformWheel versions.vendored.comfyKitchen) url hash;
  };

  comfyAimdo = mkNativeWheel {
    pname = "comfy-aimdo";
    version = versions.vendored.comfyAimdo.version;
    inherit (selectPlatformWheel versions.vendored.comfyAimdo) url hash;
  };

  # null on platforms without an upstream wheel (e.g. x86_64-darwin)
  comfyAngle =
    if angleWheel == null then
      null
    else
      python.pkgs.buildPythonPackage {
        pname = "comfy-angle";
        version = versions.vendored.comfyAngle.version;
        format = "wheel";
        src = pkgs.fetchurl { inherit (angleWheel) url hash; };
        doCheck = false;
        # The wheel bundles native ANGLE libs (libEGL.so/libGLESv2.so) that need
        # their DT_NEEDED entries resolved against Nix store paths on Linux.
        nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.autoPatchelfHook ];
        buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
          pkgs.stdenv.cc.cc.lib
          pkgs.libx11
          pkgs.libxcb
          pkgs.libxext
        ];
      };

  gradioClient = mkWheel {
    pname = "gradio-client";
    version = versions.vendored.gradioClient.version;
    url = versions.vendored.gradioClient.url;
    hash = versions.vendored.gradioClient.hash;
    pythonRelaxDeps = [ "websockets" ];
    propagatedBuildInputs = with python.pkgs; [
      fsspec
      httpx
      huggingface-hub
      packaging
      typing-extensions
      websockets
    ];
  };

  gradio = mkWheel {
    pname = "gradio";
    version = versions.vendored.gradio.version;
    url = versions.vendored.gradio.url;
    hash = versions.vendored.gradio.hash;
    propagatedBuildInputs = with python.pkgs; [
      aiofiles
      anyio
      brotli
      fastapi
      ffmpy
      gradioClient
      groovy
      httpx
      huggingface-hub
      jinja2
      markupsafe
      numpy
      orjson
      packaging
      pandas
      pillow
      pydantic
      pydub
      python-multipart
      pyyaml
      ruff
      safehttpx
      semantic-version
      starlette
      tomlkit
      typer
      typing-extensions
      uvicorn
    ];
  };

  sageattention = mkWheel {
    pname = "sageattention";
    version = versions.vendored.sageattention.version;
    url = versions.vendored.sageattention.url;
    hash = versions.vendored.sageattention.hash;
  };
}
