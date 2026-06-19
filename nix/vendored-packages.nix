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
      dontCheckRuntimeDeps ? false,
    }:
    python.pkgs.buildPythonPackage {
      inherit
        pname
        version
        propagatedBuildInputs
        dontCheckRuntimeDeps
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
      workflowTemplatesMediaApi
      workflowTemplatesMediaVideo
      workflowTemplatesMediaImage
      workflowTemplatesMediaOther
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
    # Wheel's Requires-Dist lists gitpython, pygithub, transformers,
    # huggingface-hub, typer, rich, typing-extensions, toml, uv, and chardet
    # as mandatory runtime deps. They are provided by the surrounding ComfyUI
    # pythonRuntime (see `extras` in nix/packages.nix), not propagated by this
    # wheel itself, so the per-package pythonRuntimeDepsCheckHook fails the
    # standalone build under newer nixpkgs that enable the hook by default.
    dontCheckRuntimeDeps = true;
  };

  comfyKitchen = mkWheel {
    pname = "comfy-kitchen";
    version = versions.vendored.comfyKitchen.version;
    url = versions.vendored.comfyKitchen.url;
    hash = versions.vendored.comfyKitchen.hash;
  };

  comfyAimdo = mkWheel {
    pname = "comfy-aimdo";
    version = versions.vendored.comfyAimdo.version;
    url = versions.vendored.comfyAimdo.url;
    hash = versions.vendored.comfyAimdo.hash;
  };

  gradioClient = mkWheel {
    pname = "gradio-client";
    version = versions.vendored.gradioClient.version;
    url = versions.vendored.gradioClient.url;
    hash = versions.vendored.gradioClient.hash;
    propagatedBuildInputs = with python.pkgs; [
      fsspec
      httpx
      huggingface-hub
      packaging
      typing-extensions
      websockets
    ];
    # Wheel pins websockets<16.0; newer nixpkgs ships websockets 16.x. The
    # gradio-client API surface used by ComfyUI custom nodes is unaffected
    # by the major bump, so skip the standalone runtime version check.
    dontCheckRuntimeDeps = true;
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
    # Same as gradio-client: wheel constrains several deps to versions that
    # have moved on in newer nixpkgs. The propagatedBuildInputs above pull
    # in the current versions, which work in practice for the surfaces
    # ComfyUI uses.
    dontCheckRuntimeDeps = true;
  };

  sageattention = mkWheel {
    pname = "sageattention";
    version = versions.vendored.sageattention.version;
    url = versions.vendored.sageattention.url;
    hash = versions.vendored.sageattention.hash;
  };
}
