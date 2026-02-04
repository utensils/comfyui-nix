{
  comfyui = {
    version = "0.12.2";
    releaseDate = "2026-02-04T06:09:31Z";
    rev = "5087f1d497c5b615fbb5d1ff03fcc1df308bd025";
    hash = "sha256-VH9p45CRT7L2cJ4tT4d4KAfLUFMPtI1gD8AawGMkfQk=";
  };

  vendored = {
    spandrel = {
      version = "0.4.1";
      url = "https://files.pythonhosted.org/packages/d3/1e/5dce7f0d3eb2aa418bd9cf3e84b2f5d2cf45b1c62488dd139fc93c729cfe/spandrel-0.4.1-py3-none-any.whl";
      hash = "sha256-SaOaqXl2l0mkIgNCg1W8SEBFKFTWM0zg1GWvRgmN1Eg=";
    };

    frontendPackage = {
      version = "1.37.11";
      url = "https://files.pythonhosted.org/packages/31/0d/adb224e976d677bf1f53330a1cd34f704cefe6a32bbcd2c8d960e49db73d/comfyui_frontend_package-1.37.11-py3-none-any.whl";
      hash = "sha256-b+0TnslCsFQwVZ+o5FtYQCmz7WI4mSEuxv+1sJzcBCw=";
    };

    workflowTemplates = {
      version = "0.8.31";
      url = "https://files.pythonhosted.org/packages/56/95/f3640696a8e3ff91095a159edc2f04d49b9f6f12c7fcea44d35de114817d/comfyui_workflow_templates-0.8.31-py3-none-any.whl";
      hash = "sha256-t6tiYuSO2vIfRKwX1YWTrbf19hsZnY4b9wSvRWH8OLo=";
    };

    workflowTemplatesCore = {
      version = "0.3.124";
      url = "https://files.pythonhosted.org/packages/0a/73/27ee0d64553d9f06e285a7af9732fa5b7f925353f77ca0247ba04a43653c/comfyui_workflow_templates_core-0.3.124-py3-none-any.whl";
      hash = "sha256-ES4jJPf6b6ALzE2Y66CyhZLCDfiUkYqJbtBmebCHFus=";
    };

    workflowTemplatesMediaApi = {
      version = "0.3.47";
      url = "https://files.pythonhosted.org/packages/97/09/ba489ac9e43cff062e02c432dd9730a7f254943211d3416a21e5c95f71c8/comfyui_workflow_templates_media_api-0.3.47-py3-none-any.whl";
      hash = "sha256-D3aZRzP4tbkI3yEh/WZM3H4E6yUmMD2d8i3x5BricRI=";
    };

    workflowTemplatesMediaVideo = {
      version = "0.3.43";
      url = "https://files.pythonhosted.org/packages/c0/7c/76de8646ee47bca827dfc9d3e3739784c7e4c717c4eb788c3588de923cca/comfyui_workflow_templates_media_video-0.3.43-py3-none-any.whl";
      hash = "sha256-ocA99s+i/GjYZRetjKjuurNPrhUYfPD5LBl9PQeiOLY=";
    };

    workflowTemplatesMediaImage = {
      version = "0.3.77";
      url = "https://files.pythonhosted.org/packages/5f/53/addaccedefb60f4277d4629a1934156c203b443525ed16d92ea21c315a24/comfyui_workflow_templates_media_image-0.3.77-py3-none-any.whl";
      hash = "sha256-ipPIYSco/7z17GjRUg2ogxSeeHXdeGKIKuDpSVcQzDc=";
    };

    workflowTemplatesMediaOther = {
      version = "0.3.106";
      url = "https://files.pythonhosted.org/packages/5f/da/4153d05ef54a5702161b5786373adfdac6c21cb8ada266264937d7045bae/comfyui_workflow_templates_media_other-0.3.106-py3-none-any.whl";
      hash = "sha256-SiN0u/IEINchQL3ZlRNlsrekXHsHigwSarM84wl/8R0=";
    };

    embeddedDocs = {
      version = "0.4.0";
      url = "https://files.pythonhosted.org/packages/3a/d9/c7976795a9b44483e6b1657ccd3d45fcb7409842a7d6f6c0fe1d11e83ae3/comfyui_embedded_docs-0.4.0-py3-none-any.whl";
      hash = "sha256-l8T4zcrOHpSnVBKMTvU+3ODj3wMI354MmYCA68Slv7I=";
    };

    manager = {
      version = "4.0.4";
      url = "https://files.pythonhosted.org/packages/24/52/ecc15ce24f7ed9c336a13553e6b4dc0777e2082f1e6afca0ecbe5e02564f/comfyui_manager-4.0.4-py3-none-any.whl";
      hash = "sha256-H08Wrr2ZDk5NfeQhF5Csr1QUBa/Ohmpvkwrp1tuRu50=";
    };

    # New ComfyUI core deps (not in nixpkgs)
    comfyKitchen = {
      version = "0.2.7";
      url = "https://files.pythonhosted.org/packages/f8/65/d483613734d0b9753bd9bfa297ff334cb2c7766e82306099db6b259b4e2c/comfy_kitchen-0.2.7-py3-none-any.whl";
      hash = "sha256-+PqlebadMx0vHqwJ6WqVWGwqa5WKVLwZ5/HBp3hS3TY=";
    };

    comfyAimdo = {
      version = "0.1.7";
      url = "https://files.pythonhosted.org/packages/2a/2a/e776cbcfcfe7a9c791ab6baea167ad00e1f285657d11c760dae28e4bba9f/comfy_aimdo-0.1.7-py3-none-any.whl";
      hash = "sha256-agx8NRD1OwomwcH1J4PH1kVjnzre8BQxE33UGOGTgm0=";
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
      version = "2025-12-28";
      owner = "kijai";
      repo = "ComfyUI-KJNodes";
      rev = "7b1327192e4729085788a3020a9cbb095e0c7811";
      hash = "sha256-5poI2WQb8ZDfFFqL/INVQICgkshD61YUL2lcXw/nS+U=";
    };

    gguf = {
      version = "2025-12-18";
      owner = "city96";
      repo = "ComfyUI-GGUF";
      rev = "795e45156ece99afbc3efef911e63fcb46e6a20d";
      hash = "sha256-A/mI+S7WqxGi0eHvmM8VuyjWPIshxjeWdPoi0osaBpM=";
    };

    ltxvideo = {
      version = "2025-12-02";
      owner = "Lightricks";
      repo = "ComfyUI-LTXVideo";
      rev = "08f892eace7a20ea441440f320dfa92f6d2abf5f";
      hash = "sha256-6oAp+7dd5rmZrxV8K3q0Z6vQZSJ35mQ6hC/e2EmftB0=";
    };

    florence2 = {
      version = "1.0.7";
      owner = "kijai";
      repo = "ComfyUI-Florence2";
      rev = "6c766b13f4908a86cfbd6357d6d485c80e0f3a2f";
      hash = "sha256-XNr5DFT18hhxb9DwQZxlkLVVRgF2B6ZK9LR/1ukLWIo=";
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
      version = "2025-12-12";
      owner = "kijai";
      repo = "ComfyUI-MMAudio";
      rev = "e2f9b93aa81fd40ab9f7c71c631863f8b70a72dc";
      hash = "sha256-uNeblSy7z/BGG3NiqMWvXRN4qGcRTGFrfJTvnZ8Tbkw=";
    };

    pulid = {
      version = "2025-04-14";
      owner = "cubiq";
      repo = "PuLID_ComfyUI";
      rev = "93e0c4c226b87b23c0009d671978bad0e77289ff";
      hash = "sha256-gzAqb8rNIKBOR41tPWMM1kUoKOQTOHtPIdS0Uv1Keac=";
    };

    wanvideo = {
      version = "2025-12-31";
      owner = "kijai";
      repo = "ComfyUI-WanVideoWrapper";
      rev = "bf1d77fe155c0bdbefd3d48bf5b320dce8c55849";
      hash = "sha256-H7YMFd0LVCgY3ZpTBu1a47DQ6R25ulJkuteRV2/zgD8=";
    };
  };
}
