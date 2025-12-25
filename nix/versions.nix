{
  comfyui = {
    version = "0.6.0";
    releaseDate = "2025-12-24T03:32:16Z";
    rev = "e4c61d75555036fa28b6bb34e5fd67b007c9f391";
    hash = "sha256-gd02tXWjFJ7kTGF8GT1RfVdzhXu4mM2EoQnAVt83qjQ=";
  };

  vendored = {
    spandrel = {
      version = "0.4.1";
      url = "https://files.pythonhosted.org/packages/d3/1e/5dce7f0d3eb2aa418bd9cf3e84b2f5d2cf45b1c62488dd139fc93c729cfe/spandrel-0.4.1-py3-none-any.whl";
      hash = "sha256-SaOaqXl2l0mkIgNCg1W8SEBFKFTWM0zg1GWvRgmN1Eg=";
    };

    frontendPackage = {
      version = "1.34.9";
      url = "https://files.pythonhosted.org/packages/c8/1b/0d61705cc7e74cbf98f73219ba4e643495e72ba8e13633bbd3bfcd9bb371/comfyui_frontend_package-1.34.9-py3-none-any.whl";
      hash = "sha256-g2ypUoTVcFc5RjJAw8SCanqKdycpJlanfL8LQaOa7HY=";
    };

    workflowTemplates = {
      version = "0.7.59";
      url = "https://files.pythonhosted.org/packages/fd/f5/6d861fa649ea1c58e410d6e8d0bd068db3677a5c057539f4a05e947a6844/comfyui_workflow_templates-0.7.59-py3-none-any.whl";
      hash = "sha256-erNdXjtaKJOkZdLGmJkLFXzSOf7knD+0rDDbDgTI/tM=";
    };

    workflowTemplatesCore = {
      version = "0.3.43";
      url = "https://files.pythonhosted.org/packages/4f/f7/4188d3482c322986ea4be3f64ca1f3a2dad32b92746535409efa0dd63c8d/comfyui_workflow_templates_core-0.3.43-py3-none-any.whl";
      hash = "sha256-Yw5s20oVXqGlVDH4h/qmhiNCRuk+XDlSPPj1yHR2Y0w=";
    };

    workflowTemplatesMediaApi = {
      version = "0.3.22";
      url = "https://files.pythonhosted.org/packages/2c/ac/eeca4a06026f473fe294e6cf46b42b25ece230289bb0c9619028284670eb/comfyui_workflow_templates_media_api-0.3.22-py3-none-any.whl";
      hash = "sha256-7DuNvZpHCraEtGRaz8bQVM2BCgei5cErUSWRIeF5MXU=";
    };

    workflowTemplatesMediaVideo = {
      version = "0.3.19";
      url = "https://files.pythonhosted.org/packages/78/f6/1e12cfae3c41d55100916f03dffb32041fe15e805aebd4ca4a445886b624/comfyui_workflow_templates_media_video-0.3.19-py3-none-any.whl";
      hash = "sha256-+VfMz3VtbZJ722NCURNgJPGMBiIgt7yxPu3e5ENZPC0=";
    };

    workflowTemplatesMediaImage = {
      version = "0.3.36";
      url = "https://files.pythonhosted.org/packages/6c/61/e3b3f2df32628fb3a42598f481a26a729512d5fd472a9eeda95757b858d5/comfyui_workflow_templates_media_image-0.3.36-py3-none-any.whl";
      hash = "sha256-D4yUfLfK4rOW6cw4Q5ryedsWUZYlPm3wqGFUm5YBbIs=";
    };

    workflowTemplatesMediaOther = {
      version = "0.3.47";
      url = "https://files.pythonhosted.org/packages/3b/cc/548f5fc42d8cdd8c03458baad8d17385f2e21741f8f73f7d26edaced3f80/comfyui_workflow_templates_media_other-0.3.47-py3-none-any.whl";
      hash = "sha256-CwSnKkz9PSAgLiLV6SjHjNY7u9l+N0LcicZXAkOHRd8=";
    };

    embeddedDocs = {
      version = "0.3.1";
      url = "https://files.pythonhosted.org/packages/25/29/84cf6f3cb9ef558dc5056363d1676174f0f4444a741f5cb65554af06836c/comfyui_embedded_docs-0.3.1-py3-none-any.whl";
      hash = "sha256-+7sO+Z6r2Hh8Zl7+I1ZlsztivV+bxNlA6yBV02g0yRw=";
    };

    manager = {
      version = "4.0.2";
      url = "https://files.pythonhosted.org/packages/2e/45/42fdbe83f6fa2daf9981cd10c024197644c731db99032634bb7efc0da69a/comfyui_manager-4.0.2-py3-none-any.whl";
      hash = "sha256-W5l22ZijI0vohlgjygsaqR/zXmINxlAUKbRFOtLmsj8=";
    };

    # Python packages not in nixpkgs (vendored for custom nodes)
    segment-anything = {
      version = "1.0";
      rev = "dca509fe793f601edb92606367a655c15ac00fdf";
      hash = "sha256-28XHhv/hffVIpbxJKU8wfPvDB63l93Z6r9j1vBOz/P0=";
    };

    sam2 = {
      version = "1.0";
      rev = "2b90b9f5ceec907a1c18123530e92e794ad901a4";
      hash = "sha256-pUPaUD/5wOhdJcNYPH9LV5oA1noDeWKconfpIFOyYBQ=";
    };
  };

  # Custom nodes with pinned versions
  customNodes = {
    impact-pack = {
      version = "8.28";
      owner = "ltdrdata";
      repo = "ComfyUI-Impact-Pack";
      rev = "8.28";
      hash = "sha256-V/gMPqo9Xx21+KpG5LPzP5bML9nGlHHMyVGoV+YgFWE=";
    };
  };
}
