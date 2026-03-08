{
  comfyui = {
    version = "0.16.4";
    releaseDate = "2026-03-07T22:37:49Z";
    rev = "a7a6335be538f55faa2abf7404c9b8e970847d1f";
    hash = "sha256-wPPsXQytzpb7gSzE4dUT5JME/q03Z2g6pk9RidHNy8A=";
  };

  vendored = {
    spandrel = {
      version = "0.4.2";
      url = "https://files.pythonhosted.org/packages/74/31/411ea965835534c43d4b98d451968354876e0e867ea1fd42669e4cca0732/spandrel-0.4.2-py3-none-any.whl";
      hash = "sha256-bJPj7L6w5Uj9LfRaYFRys0wWFCh8VrUbszze965SNbU=";
    };

    frontendPackage = {
      version = "1.39.19";
      url = "https://files.pythonhosted.org/packages/a4/26/de6a7662abbbf8a77bab23f3077530a1bebf55473ff68e67c4086466602f/comfyui_frontend_package-1.39.19-py3-none-any.whl";
      hash = "sha256-WDQ9157KNxutvjVMErm8R8fcWPf5IkO+U34XjfuvIDY=";
    };

    workflowTemplates = {
      version = "0.9.11";
      url = "https://files.pythonhosted.org/packages/eb/8c/45932048be4573d780e055288ae734798f36c3d76e6991f2dd38f4e3aa01/comfyui_workflow_templates-0.9.11-py3-none-any.whl";
      hash = "sha256-C7CwtGBAkNTaSi2S5S2wRIaKT9ktDCSBmng5erM+cZc=";
    };

    workflowTemplatesCore = {
      version = "0.3.159";
      url = "https://files.pythonhosted.org/packages/36/43/cee9a36447b51f8d62f3cbd9fbf8db37c0bdf31a1f6f8e270633717520b8/comfyui_workflow_templates_core-0.3.159-py3-none-any.whl";
      hash = "sha256-d2I/9a29/4WFocJwF+8NNF29PiCntfbmoL1te5piCdE=";
    };

    workflowTemplatesMediaApi = {
      version = "0.3.59";
      url = "https://files.pythonhosted.org/packages/a2/a0/8de362bdc99cdb8c40329910609f4042a74670e35c29e13c199563ecf8ef/comfyui_workflow_templates_media_api-0.3.59-py3-none-any.whl";
      hash = "sha256-j2IAb/MByv9kiintlmDlpkpYNHuAfeDvwGd2l5GDNcs=";
    };

    workflowTemplatesMediaVideo = {
      version = "0.3.57";
      url = "https://files.pythonhosted.org/packages/f6/cc/dab7b5227e206245aa0566e636031f9b3fa8eb4b9986f4a0a83cf3cff5aa/comfyui_workflow_templates_media_video-0.3.57-py3-none-any.whl";
      hash = "sha256-A35Ix3AKKFczpWC1wcSLL05OLGj3TiWF0rUUnehcaX8=";
    };

    workflowTemplatesMediaImage = {
      version = "0.3.98";
      url = "https://files.pythonhosted.org/packages/81/fd/1989fe77a2cc165231dbd7e65427934a63176f7ad5ba8ee708174af31ac1/comfyui_workflow_templates_media_image-0.3.98-py3-none-any.whl";
      hash = "sha256-CY7b7bV5ht4uxOYt58pJL5O4oL4DGbtGr2WMEo2SYjg=";
    };

    workflowTemplatesMediaOther = {
      version = "0.3.131";
      url = "https://files.pythonhosted.org/packages/bb/25/b923bad1ffcaea2e28e425e1cd556fd6873bd1cfb7f2686f6bb8f6c08ddd/comfyui_workflow_templates_media_other-0.3.131-py3-none-any.whl";
      hash = "sha256-zQbi0OC/6vAQmJSZ56cFoJT+479B9maQYiGL6goq4Ko=";
    };

    embeddedDocs = {
      version = "0.4.3";
      url = "https://files.pythonhosted.org/packages/e9/3d/f77a91b500e7005b995ab922c03d9f87ff3f7955e9ab13b6e334c14a7229/comfyui_embedded_docs-0.4.3-py3-none-any.whl";
      hash = "sha256-2mBmnSV566hv0ozutQIrkC7Yov1QxmeoYCWTZyzFRKk=";
    };

    manager = {
      version = "4.0.5";
      url = "https://files.pythonhosted.org/packages/e3/e2/9ff20f1f14462ed8c13612a26d274ae4adf916ad495292d50319ad46a619/comfyui_manager-4.0.5-py3-none-any.whl";
      hash = "sha256-mh4ZGoFzWQemx0WItAu2KhFZPrBoXTwZQICAQBfoi00=";
    };

    # New ComfyUI core deps (not in nixpkgs)
    comfyKitchen = {
      version = "0.2.7";
      url = "https://files.pythonhosted.org/packages/f8/65/d483613734d0b9753bd9bfa297ff334cb2c7766e82306099db6b259b4e2c/comfy_kitchen-0.2.7-py3-none-any.whl";
      hash = "sha256-+PqlebadMx0vHqwJ6WqVWGwqa5WKVLwZ5/HBp3hS3TY=";
    };

    comfyAimdo = {
      version = "0.2.7";
      url = "https://files.pythonhosted.org/packages/cd/b7/aeb11a92468f97dd2ed1fb7ac25a54d6de9cd252dda0d1fb7d2f131cac4c/comfy_aimdo-0.2.7-py3-none-any.whl";
      hash = "sha256-+VFU9BDtAbybx2qugbvckHc5srl3VedAuHSGYoxwm5U=";
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
