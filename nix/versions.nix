{
  comfyui = {
    version = "0.17.2";
    releaseDate = "2026-03-15T02:28:33Z";
    rev = "040460495c5713b852e4aac29a909aa63b309da7";
    hash = "sha256-jymf2noIR/QUk7pd1yA3Z+HQ1BZdAVM3Wax91G/d35I=";
  };

  vendored = {
    spandrel = {
      version = "0.4.2";
      url = "https://files.pythonhosted.org/packages/74/31/411ea965835534c43d4b98d451968354876e0e867ea1fd42669e4cca0732/spandrel-0.4.2-py3-none-any.whl";
      hash = "sha256-bJPj7L6w5Uj9LfRaYFRys0wWFCh8VrUbszze965SNbU=";
    };

    frontendPackage = {
      version = "1.41.20";
      url = "https://files.pythonhosted.org/packages/3b/e6/f7222e0c17e1f9a91c4cfa04feb759387bf26edd577ea6a9ca6f8e37a99f/comfyui_frontend_package-1.41.20-py3-none-any.whl";
      hash = "sha256-dLbXqC5K8V88yDh8KeyATuBuSkWUIjT2lf1QYaUCTjU=";
    };

    workflowTemplates = {
      version = "0.9.21";
      url = "https://files.pythonhosted.org/packages/3f/26/080d3fb30bea9f91b361d640324ef94cc4ed378616f0427704323b707ac5/comfyui_workflow_templates-0.9.21-py3-none-any.whl";
      hash = "sha256-qC10QM9IZG6Xmedde4ysYBRl89M1p+eLnAMyIqZmya0=";
    };

    workflowTemplatesCore = {
      version = "0.3.168";
      url = "https://files.pythonhosted.org/packages/8d/05/c8f8419d31d683263bfdf51295ab79e50dfc5434d6ebf7a4c8fbcb9fbe69/comfyui_workflow_templates_core-0.3.168-py3-none-any.whl";
      hash = "sha256-viY0lsCIXGIY0yeLqPycGmpmsePwwAfgdQY8gpW6A+w=";
    };

    workflowTemplatesMediaApi = {
      version = "0.3.64";
      url = "https://files.pythonhosted.org/packages/d5/f6/47c7e4413bb5e30e3a2788b742ce7f6f6bc162a0ab805b8a7f7962ca8860/comfyui_workflow_templates_media_api-0.3.64-py3-none-any.whl";
      hash = "sha256-6p4Or4rbuct5B3SDQhoyCGoHGYMvyA7czoTiPxoc9Hc=";
    };

    workflowTemplatesMediaVideo = {
      version = "0.3.60";
      url = "https://files.pythonhosted.org/packages/6d/a0/6e915c086938572c6e1ae7f1dcffc3b3b44f9898e9a19f4aa0c66f6c977b/comfyui_workflow_templates_media_video-0.3.60-py3-none-any.whl";
      hash = "sha256-thoDH1amsg5yfg4eZtlxXSo7ogopctM/SPlraIZP990=";
    };

    workflowTemplatesMediaImage = {
      version = "0.3.104";
      url = "https://files.pythonhosted.org/packages/e7/da/200a361d7d6880549c76b0e22bdd03dfea9315a0d920b1b99d15da01aa6e/comfyui_workflow_templates_media_image-0.3.104-py3-none-any.whl";
      hash = "sha256-GMjU/48YtZcSZYmP8S97+JCJhgh06jX+WJgkbK8taLw=";
    };

    workflowTemplatesMediaOther = {
      version = "0.3.141";
      url = "https://files.pythonhosted.org/packages/a5/b3/179745959152231283dcae2c4db455c7a07d83b51e933ff193938b8e44e8/comfyui_workflow_templates_media_other-0.3.141-py3-none-any.whl";
      hash = "sha256-lagRSSPtGVZ3Iq6ecQb6pgFlD9am0bPGKvgaksaSiAQ=";
    };

    embeddedDocs = {
      version = "0.4.3";
      url = "https://files.pythonhosted.org/packages/e9/3d/f77a91b500e7005b995ab922c03d9f87ff3f7955e9ab13b6e334c14a7229/comfyui_embedded_docs-0.4.3-py3-none-any.whl";
      hash = "sha256-2mBmnSV566hv0ozutQIrkC7Yov1QxmeoYCWTZyzFRKk=";
    };

    manager = {
      version = "4.1b2";
      url = "https://files.pythonhosted.org/packages/55/72/94ae1dca446db396d6eadc0549a59e51c3477dc7cda5fbfd4d4ead55e83a/comfyui_manager-4.1b2-py3-none-any.whl";
      hash = "sha256-JeOFpniZ8gdKBOYoW+20A1M11ou833sFIirVwKLS3Us=";
    };

    # New ComfyUI core deps (not in nixpkgs)
    comfyKitchen = {
      version = "0.2.8";
      url = "https://files.pythonhosted.org/packages/46/b0/64c3e0656db822cb4f7dbc928d6a13cf2cad861cc178e6386114634e355b/comfy_kitchen-0.2.8-py3-none-any.whl";
      hash = "sha256-CzIpks8Wgevj1BOseVDznlzEJVBcE8740IUnzoL+XjI=";
    };

    comfyAimdo = {
      version = "0.2.10";
      url = "https://files.pythonhosted.org/packages/82/bf/8324fc034d07a975292c2dba2443acbf90e7ff8c30584dfdc286a6d8ee4d/comfy_aimdo-0.2.10-py3-none-any.whl";
      hash = "sha256-d6eTQS1Q+Z9Ux/73tIaQ0UbuYUseIhyjCBVZUQOsAQ4=";
    };

    # UI deps some custom nodes expect
    gradioClient = {
      version = "1.13.3";
      url = "https://files.pythonhosted.org/packages/6e/0b/337b74504681b5dde39f20d803bb09757f9973ecdc65fd4e819d4b11faf7/gradio_client-1.13.3-py3-none-any.whl";
      hash = "sha256-P2Pk0zoomcGhKxD+PPd7gqaRn/Gh+2OR9qoiWBGqOQw=";
    };

    gradio = {
      version = "5.49.1";
      url = "https://files.pythonhosted.org/packages/8d/95/1c25fbcabfa201ab79b016c8716a4ac0f846121d4bbfd2136ffb6d87f31e/gradio-5.49.1-py3-none-any.whl";
      hash = "sha256-Gxk2k4eAGiamun/S901GxbDirJ3e8U8k3cDRH7GUIbc=";
    };

    # Optional attention optimization (used by --use-sage-attention)
    sageattention = {
      version = "1.0.6";
      url = "https://files.pythonhosted.org/packages/53/06/f7b47adb766bcb38b3f88763374a3e8dffea05ee9b556bc24dbcbd60fd29/sageattention-1.0.6-py3-none-any.whl";
      hash = "sha256-+vxmVpvtYqFoOeggwmEhQbWiCsz1W4dtlBurnArF2Ig=";
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

    color-matcher = {
      version = "0.6.0";
      url = "https://files.pythonhosted.org/packages/a0/3a/f3c2c5012f59235ff5885db7cc75dc209eca90e42ae3728db56f8a9e28a4/color_matcher-0.6.0-py3-none-any.whl";
      hash = "sha256-/WQvlBTDO38+vJb+CIjBxiAINhQmZFic4sy1LrzadzQ=";
    };

    # facexlib - face processing library needed by PuLID
    facexlib = {
      version = "0.3.0";
      url = "https://files.pythonhosted.org/packages/36/7b/2147339dafe1c4800514c9c21ee4444f8b419ce51dfc7695220a8e0069a6/facexlib-0.3.0-py3-none-any.whl";
      hash = "sha256-JF1YhhU3uCDGFuiz72GMz60qJHJKLXS+KwVCZDwBqHg=";
    };
  };

  # Pre-built PyTorch wheels from pytorch.org
  # These avoid compiling PyTorch from source (which requires 30-60GB RAM)
  # CUDA wheels bundle CUDA libraries, so no separate CUDA toolkit needed at runtime
  # macOS wheels use PyTorch 2.5.1 to avoid MPS issues on macOS 26 (Tahoe)
  pytorchWheels = {
    # macOS Apple Silicon (arm64) - PyTorch 2.5.1 (2.9.x has MPS bugs on macOS 26)
    darwinArm64 = {
      torch = {
        version = "2.5.1";
        url = "https://download.pytorch.org/whl/cpu/torch-2.5.1-cp312-none-macosx_11_0_arm64.whl";
        hash = "sha256-jHEt9hEBlk6xGRCoRlFAEfC29ZIMVdv1Z7/4o0Fj1bE=";
      };
      torchvision = {
        version = "0.20.1";
        url = "https://download.pytorch.org/whl/cpu/torchvision-0.20.1-cp312-cp312-macosx_11_0_arm64.whl";
        hash = "sha256-GjElb/lF1k8Aa7MGgTp8laUx/ha/slNcg33UwQRTPXo=";
      };
      torchaudio = {
        version = "2.5.1";
        url = "https://download.pytorch.org/whl/cpu/torchaudio-2.5.1-cp312-cp312-macosx_11_0_arm64.whl";
        hash = "sha256-8cv9/Ru9++conUenTzb/bF2HwyBWBiAv71p/tpP2HPA=";
      };
    };
    # Linux x86_64 CUDA 12.8
    cu128 = {
      torch = {
        version = "2.10.0";
        url = "https://download.pytorch.org/whl/cu128/torch-2.10.0%2Bcu128-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-Yo6JvVEQztfevuKlfGmVlyW3+8ZOq4GjndcORsfii6U=";
      };
      torchvision = {
        version = "0.25.0";
        url = "https://download.pytorch.org/whl/cu128/torchvision-0.25.0%2Bcu128-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-ElWgyiv5h6z58QO5bFxM/jQV/Eoe7xf6CK9SegSk9XM=";
      };
      torchaudio = {
        version = "2.10.0";
        url = "https://download.pytorch.org/whl/cu128/torchaudio-2.10.0%2Bcu128-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-0muRoXPO5tuav/aLSNZCNpUP/FYo0GRI7N16xWhB4Qo=";
      };
    };
    # Linux x86_64 ROCm 7.1
    rocm71 = {
      torch = {
        version = "2.10.0";
        url = "https://download.pytorch.org/whl/rocm7.1/torch-2.10.0%2Brocm7.1-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-AI7g13u4tfn07h8AISAZxGGRcePEGV3lbyUzMbO8Mg0=";
      };
      torchvision = {
        version = "0.25.0";
        url = "https://download.pytorch.org/whl/rocm7.1/torchvision-0.25.0%2Brocm7.1-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-iuo929t0gB0zdFd6ELPwTUmJfCet0jXLJTE99uZbGSk=";
      };
      torchaudio = {
        version = "2.10.0";
        url = "https://download.pytorch.org/whl/rocm7.1/torchaudio-2.10.0%2Brocm7.1-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-pUuMH2HeAbGrlGWJqgFYId0RCTVEcCJJ0gq6VpE8aLs=";
      };
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

    rgthree-comfy = {
      version = "1.0.0";
      owner = "rgthree";
      repo = "rgthree-comfy";
      rev = "v.1.0.0";
      hash = "sha256-bzQcQ37v7ZrHDitZV6z3h/kdNbWxpLxNSvh0rSxnLss=";
    };

    kjnodes = {
      version = "git-2026-03-07-c88ac88a8f8a";
      owner = "kijai";
      repo = "ComfyUI-KJNodes";
      rev = "c88ac88a8f8a6a090a0d5d607156090cb2911503";
      hash = "sha256-wr1ynNRvD9ehrlnvi+0RJuawfeYLQmi3hFK9FCGdr1g=";
    };

    gguf = {
      version = "git-2026-02-04-6ea2651e7df6";
      owner = "city96";
      repo = "ComfyUI-GGUF";
      rev = "6ea2651e7df66d7585f6ffee804b20e92fb38b8a";
      hash = "sha256-/ZwecgxTTMo9J1whdEJci8lEkOy/yP+UmjbpOAA3BvU=";
    };

    ltxvideo = {
      version = "git-2026-03-07-531512f72869";
      owner = "Lightricks";
      repo = "ComfyUI-LTXVideo";
      rev = "531512f7286963dc7aff1fd8bf5556e95eae03af";
      hash = "sha256-s0KH5Mer2jhYR1gENglR1EYUobK8yMHeixqmBhWsS2c=";
    };

    florence2 = {
      version = "git-2026-03-07-606bc5cd3465";
      owner = "kijai";
      repo = "ComfyUI-Florence2";
      rev = "606bc5cd3465d48c66aa573bc1680c9bbe78edd9";
      hash = "sha256-R/o9BG/92fsoWAnpdmr9xi9f/SIuNLx4VGufstRc9hw=";
    };

    bitsandbytes-nf4 = {
      version = "2024-08-15";
      owner = "comfyanonymous";
      repo = "ComfyUI_bitsandbytes_NF4";
      rev = "6c65152bc48b28fc44cec3aa44035a8eba400eb9";
      hash = "sha256-akwKtwW3uDOe/anox5B/WT7Fx2n+7hP0elaYO2cyJFk=";
    };

    x-flux = {
      version = "2024-10-30";
      owner = "XLabs-AI";
      repo = "x-flux-comfyui";
      rev = "00328556efc9472410d903639dc9e68a8471f7ac";
      hash = "sha256-9487Ijtwz0VZGOHknMTbrJgZHsNjDHJnLK9NtohpO0A=";
    };

    mmaudio = {
      version = "git-2026-02-04-8eaeb72edc3a";
      owner = "kijai";
      repo = "ComfyUI-MMAudio";
      rev = "8eaeb72edc3aaf2059b57f2d96a1f6f689f19ae2";
      hash = "sha256-kN2Q4j3z0Z8uSZCh4sK/1f2cVa9Ymw7fOtTYl5MDEv8=";
    };

    pulid = {
      version = "2025-04-14";
      owner = "cubiq";
      repo = "PuLID_ComfyUI";
      rev = "93e0c4c226b87b23c0009d671978bad0e77289ff";
      hash = "sha256-gzAqb8rNIKBOR41tPWMM1kUoKOQTOHtPIdS0Uv1Keac=";
    };

    wanvideo = {
      version = "git-2026-03-07-df8f3e49daaa";
      owner = "kijai";
      repo = "ComfyUI-WanVideoWrapper";
      rev = "df8f3e49daaad117cf3090cc916c83f3d001494c";
      hash = "sha256-nfKQAojS5HsvXNa1vw1Dz9R/vNZxyRYI5CFp/WnjZ4k=";
    };
  };
}
