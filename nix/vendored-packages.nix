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
    }:
    python.pkgs.buildPythonPackage {
      inherit pname version propagatedBuildInputs;
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
