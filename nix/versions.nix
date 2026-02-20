{
  comfyui = {
    version = "0.14.2";
    releaseDate = "2026-02-18T06:12:02Z";
    rev = "185c61dc26cdc631a1fd57b53744b67393a97fc6";
    hash = "sha256-rrkVEnoWp0BBFZS4fMHo72aYZSxy0I3O8C9DMKXsr88=";
  };

  vendored = {
    spandrel = {
      version = "0.4.1";
      url = "https://files.pythonhosted.org/packages/d3/1e/5dce7f0d3eb2aa418bd9cf3e84b2f5d2cf45b1c62488dd139fc93c729cfe/spandrel-0.4.1-py3-none-any.whl";
      hash = "sha256-SaOaqXl2l0mkIgNCg1W8SEBFKFTWM0zg1GWvRgmN1Eg=";
    };

    frontendPackage = {
      version = "1.38.14";
      url = "https://files.pythonhosted.org/packages/24/26/d7b2f6442d9252bc760379a87aeeeaa6b7e21750b0283301399776f115d9/comfyui_frontend_package-1.38.14-py3-none-any.whl";
      hash = "sha256-Mg94aaKJuKNKY23DguF3EcvIQgYhW5aPxii4Pn5Z1To=";
    };

    workflowTemplates = {
      version = "0.8.43";
      url = "https://files.pythonhosted.org/packages/3a/a7/c15e6a7aa40f6716d8d5db4d680c07525ae1cc72867d0d6af9836df12b72/comfyui_workflow_templates-0.8.43-py3-none-any.whl";
      hash = "sha256-JMowTkEs8SXmBw813VdsXKRB3DvNTYzN0DuY2HRYgnE=";
    };

    workflowTemplatesCore = {
      version = "0.3.147";
      url = "https://files.pythonhosted.org/packages/b2/87/0635b9dddf6963a90c7a08f6f55235a872ac53d6fbf6a56fe847678ca583/comfyui_workflow_templates_core-0.3.147-py3-none-any.whl";
      hash = "sha256-3c1aCGnaPE+Q+bE/6HWBJS3Lzf90KNGPHp20c4oX1po=";
    };

    workflowTemplatesMediaApi = {
      version = "0.3.54";
      url = "https://files.pythonhosted.org/packages/8e/f1/162f2730e73169421c3804d39ee786d2de2e9bcb8a8e619c253f7cdd32ce/comfyui_workflow_templates_media_api-0.3.54-py3-none-any.whl";
      hash = "sha256-L0YUSw1exVBTZ1dfSisbpJFaO+Y+2bVwb6N97b7U9GM=";
    };

    workflowTemplatesMediaVideo = {
      version = "0.3.49";
      url = "https://files.pythonhosted.org/packages/1b/41/678f247f8007f40b92e8ff42bf1152c6b21937b6fad7d1fd3ef6e562fab3/comfyui_workflow_templates_media_video-0.3.49-py3-none-any.whl";
      hash = "sha256-xdfaYyyeOAqCdh4UIZ4iZiH3JmL3SQIHpYuXdDx2G3Y=";
    };

    workflowTemplatesMediaImage = {
      version = "0.3.90";
      url = "https://files.pythonhosted.org/packages/de/76/53c62e0627f13865386ad31fcb3cfbc80169e6e3e4ea8c65bf5fb11b6fde/comfyui_workflow_templates_media_image-0.3.90-py3-none-any.whl";
      hash = "sha256-77cBHBqA8jLfoVF46phLFDhDqk+pRl6ihA3O86endZ0=";
    };

    workflowTemplatesMediaOther = {
      version = "0.3.123";
      url = "https://files.pythonhosted.org/packages/35/4c/89c0a06310816d5dae1026a6a7016125f27c126dc245af2372c31b1bc6d0/comfyui_workflow_templates_media_other-0.3.123-py3-none-any.whl";
      hash = "sha256-0KrByksldVxXYUwqE2YH5d3S/rpSZAGKz833U2DU5mM=";
    };

    embeddedDocs = {
      version = "0.4.1";
      url = "https://files.pythonhosted.org/packages/2b/c1/6fd983ff14ac93d3ae31ef48b23d6a63b09f2b595279258105b821083247/comfyui_embedded_docs-0.4.1-py3-none-any.whl";
      hash = "sha256-t2rdrw66DR3OZWV4bIgIcDxjWQskIUu/ZwwsDkzvxgU=";
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
      version = "0.1.8";
      url = "https://files.pythonhosted.org/packages/06/59/47e8f1a513d5e4c041edf8afb164e7fbd42635e78974cbfd609fcda3506e/comfy_aimdo-0.1.8-py3-none-any.whl";
      hash = "sha256-BVs3sDetESkbqH2knvJ4weuw4ix0IRH6+a4xWzru3Zk=";
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
    # Linux x86_64 CUDA 12.4
    cu124 = {
      torch = {
        version = "2.5.1";
        url = "https://download.pytorch.org/whl/cu124/torch-2.5.1%2Bcu124-cp312-cp312-linux_x86_64.whl";
        hash = "sha256-v2SEv+W8T5KkoaG/VTBBUF4ZqRH3FwZTMOsGGv4OFNc=";
      };
      torchvision = {
        version = "0.20.1";
        url = "https://download.pytorch.org/whl/cu124/torchvision-0.20.1%2Bcu124-cp312-cp312-linux_x86_64.whl";
        hash = "sha256-0QU+xQVFSefawmE7FRv/4yPzySSTnSlt9NfTSSWq860=";
      };
      torchaudio = {
        version = "2.5.1";
        url = "https://download.pytorch.org/whl/cu124/torchaudio-2.5.1%2Bcu124-cp312-cp312-linux_x86_64.whl";
        hash = "sha256-mQJZjgMwrurQvBVFg3gE6yaFSbm0zkGuPKUbI4SQTok=";
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
      version = "git-2026-02-04-fb9d5764d21d";
      owner = "kijai";
      repo = "ComfyUI-KJNodes";
      rev = "fb9d5764d21d23a3f52186aeccbb259efac96f9c";
      hash = "sha256-+dFN00f72NqJb6WVLt8CnBoKQnceEt+eTs7nSRY/tgw=";
    };

    gguf = {
      version = "git-2026-02-04-6ea2651e7df6";
      owner = "city96";
      repo = "ComfyUI-GGUF";
      rev = "6ea2651e7df66d7585f6ffee804b20e92fb38b8a";
      hash = "sha256-/ZwecgxTTMo9J1whdEJci8lEkOy/yP+UmjbpOAA3BvU=";
    };

    ltxvideo = {
      version = "git-2026-02-04-49add6dddb2e";
      owner = "Lightricks";
      repo = "ComfyUI-LTXVideo";
      rev = "49add6dddb2e1bb2d23bc509a9fac3edd2834961";
      hash = "sha256-KU96XLNjO6tGEUB26vDjE5LVu2bCBiKcYRNehCIBhWY=";
    };

    florence2 = {
      version = "git-2026-02-04-ee64d1ef3fed";
      owner = "kijai";
      repo = "ComfyUI-Florence2";
      rev = "ee64d1ef3fedcb26fff9bcc78065f9eea21ccb87";
      hash = "sha256-WXqJ3T6Zm7zUw4SEmDujRKvLAQDY1G9al6NTag9YWXo=";
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
      version = "git-2026-02-04-3d7b49e2df66";
      owner = "kijai";
      repo = "ComfyUI-WanVideoWrapper";
      rev = "3d7b49e2df66bbbe379cd54748baf9decfe678a2";
      hash = "sha256-KzzcCQ3ieis9xZRqGJ3usqDJ7xvutp/GEDi7kBFDFTU=";
    };
  };
}
