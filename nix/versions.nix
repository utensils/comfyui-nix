{
  comfyui = {
    version = "0.30.2";
    releaseDate = "2026-08-05T00:47:33Z";
    rev = "dec5d9450a5290bcf63430409ea41018e67f41c3";
    hash = "sha256-fLtgJpK8hEuYcfu1vKGDJtszPfED4mmyKHZYrrq/uiA=";
  };

  vendored = {
    spandrel = {
      version = "0.4.2";
      url = "https://files.pythonhosted.org/packages/74/31/411ea965835534c43d4b98d451968354876e0e867ea1fd42669e4cca0732/spandrel-0.4.2-py3-none-any.whl";
      hash = "sha256-bJPj7L6w5Uj9LfRaYFRys0wWFCh8VrUbszze965SNbU=";
    };

    frontendPackage = {
      version = "1.47.12";
      url = "https://files.pythonhosted.org/packages/63/84/ddcd368d5b7f65958a65cf549766118d0dbf2a74370b7fc5d3ec68ef1aab/comfyui_frontend_package-1.47.12-py3-none-any.whl";
      hash = "sha256-shVcGvvzCv0G7SFzB6Gr2SlVsyk2E1OhtopSl/wAkC4=";
    };

    workflowTemplates = {
      version = "0.11.31";
      url = "https://files.pythonhosted.org/packages/52/3b/61451b0d55375ec0e340af9deb55a3025deb026ec36ac3ef38b8f5005969/comfyui_workflow_templates-0.11.31-py3-none-any.whl";
      hash = "sha256-aEFBOwJdaVwW1BCy0HDGJ9FwT0L+VdzvVyGdx3+l/eI=";
    };

    workflowTemplatesCore = {
      version = "0.3.295";
      url = "https://files.pythonhosted.org/packages/b6/8c/c8187a1bcc3c07bb7ff73bc9d801971b9fa00d130f3e51dcef10d68c6217/comfyui_workflow_templates_core-0.3.295-py3-none-any.whl";
      hash = "sha256-e4mwyY5wwA6hQ5HfIX63/nyZvbrnGQfl2J/I9Kvww7M=";
    };

    workflowTemplatesJson = {
      version = "0.1.30";
      url = "https://files.pythonhosted.org/packages/d0/7a/14628970aab24e9c3a28ac8e8e27e7522e64d0a74db8702c7f65d79dee6f/comfyui_workflow_templates_json-0.1.30-py3-none-any.whl";
      hash = "sha256-YbpbQ/Ks10s9uTlemkE48XGnX0owT7P8D9jXcFG+6vk=";
    };

    workflowTemplatesMediaApi = {
      version = "0.3.84";
      url = "https://files.pythonhosted.org/packages/35/47/e4c723615b396f75893049af38a4b53bcb0e8944418819bb0e0d72f342e8/comfyui_workflow_templates_media_api-0.3.84-py3-none-any.whl";
      hash = "sha256-wtalmZrDnk839HriMcklV97+Wt2yzGq1wRQQtNWikQo=";
    };

    workflowTemplatesMediaVideo = {
      version = "0.3.101";
      url = "https://files.pythonhosted.org/packages/e5/9e/49e1fbe9f05df7e4410a8d485af2a2d6fe80b247d44b3bfa7166c54012ef/comfyui_workflow_templates_media_video-0.3.101-py3-none-any.whl";
      hash = "sha256-YnD9YcjDkxtvADGrrH1MkM7WJN5seRi/+FuJ5sPXSTw=";
    };

    workflowTemplatesMediaImage = {
      version = "0.3.160";
      url = "https://files.pythonhosted.org/packages/bd/2e/aa57dc75cc2a73921d8472a398678e1ac40c011756ad0ab2dfe41eb0ba15/comfyui_workflow_templates_media_image-0.3.160-py3-none-any.whl";
      hash = "sha256-1KXFVBxwiPatscfaQfXXwcFKA37aamHNi0t2wlH6qpM=";
    };

    workflowTemplatesMediaOther = {
      version = "0.3.229";
      url = "https://files.pythonhosted.org/packages/a7/46/feed5492a2def46fee71a52fcbb3b7443a048e402c40bedfaaebcc6fa234/comfyui_workflow_templates_media_other-0.3.229-py3-none-any.whl";
      hash = "sha256-zj2Y+p2EuRTDNf5cm8kDz+++GTKxvDy2uu9/NxtL1DU=";
    };

    workflowTemplatesMediaAssets01 = {
      version = "0.1.19";
      url = "https://files.pythonhosted.org/packages/76/f7/99e669a3d7674707a92b04af9d1905ba6efbcd566d75dbd5f4ba30790add/comfyui_workflow_templates_media_assets_01-0.1.19-py3-none-any.whl";
      hash = "sha256-oSeZXnP0fNgqNayrpyMme3S0TrGjpi+9aF1eV6dXa/w=";
    };

    embeddedDocs = {
      version = "0.5.9";
      url = "https://files.pythonhosted.org/packages/45/6a/95761ec1c888bf64ae554225892dbf934a67dd24dc44591a066890def34e/comfyui_embedded_docs-0.5.9-py3-none-any.whl";
      hash = "sha256-MK+uQypxyWqllCHQ83OIxm/2VyuMvu6P8EXk1fhPiWw=";
    };

    manager = {
      version = "4.2.2";
      url = "https://files.pythonhosted.org/packages/2c/21/ff7464c4ea1bc53741280d2b26046c2c9e8ba742e096a971aff2f83da1bb/comfyui_manager-4.2.2-py3-none-any.whl";
      hash = "sha256-mwMx5bhEg7QGJgSAuSrZHb2Ec8rm4iYhJ+jBFXfOBHM=";
    };

    # New ComfyUI core deps (not in nixpkgs).
    # comfy-kitchen and comfy-aimdo ship platform wheels with native libraries
    # (kitchen: backends/cuda/_C.abi3.so, aimdo: aimdo.so/aimdo_rocm.so). The
    # py3-none-any wheels are pure-Python and silently disable those features
    # (issue #66), so prefer the platform wheels where they exist and keep the
    # any-wheel as the macOS fallback.
    comfyKitchen = {
      version = "0.2.26";
      any = {
        url = "https://files.pythonhosted.org/packages/07/7f/43b622cdc4132ecf47300b5a516a5d186f0466dc74c246ba8077e372d8e7/comfy_kitchen-0.2.26-py3-none-any.whl";
        hash = "sha256-yUX1voDU/RKAwi9yGbSW88G0KyaMWb/gp7jYP2o/BjY=";
      };
      linuxX86_64 = {
        url = "https://files.pythonhosted.org/packages/60/46/812a577d85dd0c8a182e924b66d9253fe8fb9e3b33f18d7623c096e034c9/comfy_kitchen-0.2.26-cp312-abi3-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl";
        hash = "sha256-AoyR6Qn+olPijQ4esjQNWoZSvDlUbN7FPjiAmzwIyZg=";
      };
      linuxAarch64 = {
        url = "https://files.pythonhosted.org/packages/ed/e0/093be9143ef7b66ee794e9a46b3c9dfe75ab522bf8a9d6e906a8aeb0c67a/comfy_kitchen-0.2.26-cp312-abi3-manylinux_2_24_aarch64.manylinux_2_28_aarch64.whl";
        hash = "sha256-aAdU/GD5laK1n/fv0bkPq9TQPo7gwibgHRijA+UhfEQ=";
      };
    };

    # ANGLE libraries for the GLSL shader nodes (comfy_extras/nodes_glsl.py).
    # Replaces glfw as of ComfyUI v0.28. Platform-specific wheels containing
    # native libEGL/libGLESv2 (no wheel exists for x86_64-darwin).
    comfyAngle = {
      version = "0.1.0";
      linuxX86_64 = {
        url = "https://files.pythonhosted.org/packages/94/79/09033953c3f2ef3d31e7cd626e01db9cdd2760a50bb22b83fa6aef32561e/comfy_angle-0.1.0-py3-none-manylinux_2_28_x86_64.whl";
        hash = "sha256-L00X6YQ1PTfSR/r0c6+6vbmGP8OvPgIG+7fYK9wjrGc=";
      };
      linuxAarch64 = {
        url = "https://files.pythonhosted.org/packages/65/1d/87298bb1935268c63bc27d24487b5e40f58e74da3138e122123ce6b052cb/comfy_angle-0.1.0-py3-none-manylinux_2_28_aarch64.whl";
        hash = "sha256-KJVqfXjbrjtB+DiIpeCIQ6x0e3Zj+WdMKWFCdNPxfBU=";
      };
      darwinArm64 = {
        url = "https://files.pythonhosted.org/packages/d4/eb/f98f8aefcad8ec1a5ea55d8e83d2762a721bbc3fa625e54430776cf29a00/comfy_angle-0.1.0-py3-none-macosx_11_0_arm64.whl";
        hash = "sha256-o60v5vHwos6m8z7G6xs0OS4OMOsyOkPgbYztjC9QwPQ=";
      };
    };

    comfyAimdo = {
      version = "0.4.11";
      any = {
        url = "https://files.pythonhosted.org/packages/c4/c0/055907535b0c3ded0eda619761490dda86b1c7f7e921fbc3306a18bf9cbd/comfy_aimdo-0.4.11-py3-none-any.whl";
        hash = "sha256-s61X5U6mNUa/3s86nUbNXMWibySOuAhAk7VS+vVp2jo=";
      };
      linuxX86_64 = {
        url = "https://files.pythonhosted.org/packages/fb/e8/3838f3735423dd25930375210f818528c9efa6928ae92123e82a9dcbf3a0/comfy_aimdo-0.4.11-cp39-abi3-manylinux2010_x86_64.manylinux2014_x86_64.manylinux_2_12_x86_64.manylinux_2_17_x86_64.whl";
        hash = "sha256-Zuj+eDOFsWsAEouGsA8fn+WHJprgGW3rhHw4L522nE8=";
      };
      linuxAarch64 = {
        url = "https://files.pythonhosted.org/packages/39/3b/044e93128320018261ac64d8387ec8c2cc2e09c830645b846ca89c8af45e/comfy_aimdo-0.4.11-cp39-abi3-manylinux2014_aarch64.manylinux_2_17_aarch64.whl";
        hash = "sha256-bKSPbL5O8BDh69Aa27drD1qyfyDidR7IAjX6zfm4IFs=";
      };
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
    # Linux x86_64 CUDA 13.0
    cu130 = {
      torch = {
        version = "2.10.0";
        url = "https://download.pytorch.org/whl/cu130/torch-2.10.0%2Bcu130-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-hY8MvMeNcm/qlJnrNGT6qYOS+gk4RaMmIgm9Imt4RNY=";
      };
      torchvision = {
        version = "0.25.0";
        url = "https://download.pytorch.org/whl/cu130/torchvision-0.25.0%2Bcu130-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-wvXjjwzVeieW5FA8DxM2XeugHbwWfvgg8L7sfKlvXy4=";
      };
      torchaudio = {
        version = "2.10.0";
        url = "https://download.pytorch.org/whl/cu130/torchaudio-2.10.0%2Bcu130-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-7Vc+cxm6mm4Te0iV7d9Mn81CS7ThCmKSZ9ZLVazFf7s=";
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
    # Linux x86_64 Intel XPU (oneAPI / SYCL)
    # In-tree PyTorch XPU — no IPEX needed. Targets Arc A/B series and
    # Core Ultra (Meteor Lake+) iGPUs. Older Xe-LP iGPUs (UHD 770) are
    # not officially supported by Intel/PyTorch — untested here.
    #
    # The XPU torch wheel does NOT bundle its Intel runtime libs the way CUDA
    # and ROCm wheels do. Instead it declares ~20 Intel runtime wheel deps in
    # Requires-Dist. All are pinned in `xpuRuntime` below and wired up as
    # propagatedBuildInputs of torch in python-overrides.nix.
    xpu = {
      torch = {
        version = "2.10.0";
        url = "https://download.pytorch.org/whl/xpu/torch-2.10.0%2Bxpu-cp312-cp312-linux_x86_64.whl";
        hash = "sha256-tHNXHUeJEvkogcwT8V+hj4Rj+w+4oGjJbtR6fUWk2go=";
      };
      torchvision = {
        version = "0.25.0";
        url = "https://download.pytorch.org/whl/xpu/torchvision-0.25.0%2Bxpu-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-atJUNJa8KeWdPdYUqU0JqphwMYrttmBFNE//3f7dLPg=";
      };
      torchaudio = {
        version = "2.10.0";
        url = "https://download.pytorch.org/whl/xpu/torchaudio-2.10.0%2Bxpu-cp312-cp312-manylinux_2_28_x86_64.whl";
        hash = "sha256-oD/un3Hi9OZC/P8vaokN6kYwm7cGrahDr40K5CBa4p8=";
      };
    };
  };

  # Intel XPU runtime wheel pins (declared as Requires-Dist by torch-2.10.0+xpu).
  # These are PyPI-hosted wheels from Intel except triton-xpu which lives on
  # download.pytorch.org. All are py2.py3-none-manylinux_2_28_x86_64 binary
  # distributions containing .so files and Python shims.
  xpuRuntime = {
    intel-cmplr-lib-rt = {
      version = "2025.3.1";
      url = "https://files.pythonhosted.org/packages/3d/66/26dfd6a19f7faf595da12c21bdb4102c6f30755511c7f167f745b203fbb7/intel_cmplr_lib_rt-2025.3.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-V/ZXqklEJyPlkQL7nj9etweZ2TceynqyrUb0T6zyEM8=";
    };
    intel-cmplr-lib-ur = {
      version = "2025.3.1";
      url = "https://files.pythonhosted.org/packages/70/9a/a338de7fc24087c40d38401372618c8465103795baefe941eea3acf55678/intel_cmplr_lib_ur-2025.3.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-FzDM4MZVkdFX1foazchEep7UGbUn6lLmbbCBWg+15EQ=";
    };
    intel-cmplr-lic-rt = {
      version = "2025.3.1";
      url = "https://files.pythonhosted.org/packages/a7/3b/30ce9123fd5368ac4f9abceca8cd7ee2f495c3e2b6f1b244285737210a8d/intel_cmplr_lic_rt-2025.3.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-rWUcJpBpK/jJQO5lomuwY9BpWafirSdyL27bvx9TykY=";
    };
    intel-sycl-rt = {
      version = "2025.3.1";
      url = "https://files.pythonhosted.org/packages/76/74/27684e2d0d32923da293f22b418c0c13919839444b67e86a8986f44938e7/intel_sycl_rt-2025.3.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-KW2UWY4VC/bqTFqPFQX5jopIO/OLaTW43a1vcrHSW58=";
    };
    oneccl-devel = {
      version = "2021.17.1";
      url = "https://files.pythonhosted.org/packages/6f/69/761af812bbccc4decd4f5b7492aa533654773ae9dfc3487edec44a4d8126/oneccl_devel-2021.17.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-w/dDjxK5dj3SvLPOT0iyRieIU0lHVFpoEX9QO5qwHSo=";
    };
    oneccl = {
      version = "2021.17.1";
      url = "https://files.pythonhosted.org/packages/3d/69/8050e96e5b099b349d9109f727ce39b4f57414a24d3eb71a12fdc48bad87/oneccl-2021.17.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-x3sWoWhtJS7OffMx2o5P7rN3bEC90DqPjplCrTeNj/g=";
    };
    impi-rt = {
      version = "2021.17.0";
      url = "https://files.pythonhosted.org/packages/26/f9/4d676df06d5069144d1533a52860401ae9204cfe84ab69dc59a595233464/impi_rt-2021.17.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-e2XFpenfii/gzJjuWkTqThj5Dn0RhHq2ufmw31nB0Do=";
    };
    onemkl-license = {
      version = "2025.3.0";
      url = "https://files.pythonhosted.org/packages/88/11/b43e8cde058c368ce7f8f9b1ca9f812f7397e4309148da7d24cb6b81b513/onemkl_license-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-qBCyW7JKkNtEktgccc3hMYPYlRziaWDW3FbU9OPclf8=";
    };
    onemkl-sycl-blas = {
      version = "2025.3.0";
      url = "https://files.pythonhosted.org/packages/1e/07/df0cd5b0ec5f0a0bcbc8e73e4b2cfca78449b3b521868b1e366bfe6f97a3/onemkl_sycl_blas-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-57tfKK/ARfy72JiRT0d9fnU17J+0W7lG7Z+Be9HvH1s=";
    };
    onemkl-sycl-dft = {
      version = "2025.3.0";
      url = "https://files.pythonhosted.org/packages/7c/b8/1ec88922a9a479f567183cf82d49041451bcb7afbb3195202d9a57e5a0ff/onemkl_sycl_dft-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-OuI/OCDwZRyLQ8/2Rt3STawpOCr2yyS/RtXIpHLIuJk=";
    };
    onemkl-sycl-lapack = {
      version = "2025.3.0";
      url = "https://files.pythonhosted.org/packages/78/c4/c2cf3e1990707f7f1918f1073e3a26c56e92f06c1525af39501b271ede23/onemkl_sycl_lapack-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-0qTXuia5CrM6L2TtbJXFlshyHuJRmD6vmkyYVtHjTHs=";
    };
    onemkl-sycl-rng = {
      version = "2025.3.0";
      url = "https://files.pythonhosted.org/packages/94/6a/3fc34f47c69bdfbfce1f6d02f18e0fd41459bb4e1204e2a5cae179c0986e/onemkl_sycl_rng-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-5EBkG3waAhxJdblbmYKLgBVQSNiQ6/0k80Bg/qpbM3U=";
    };
    onemkl-sycl-sparse = {
      version = "2025.3.0";
      url = "https://files.pythonhosted.org/packages/a9/5f/4f0b81e5f83f5e42c549bd29a9398b507890ec24080d27cd7afada61521e/onemkl_sycl_sparse-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-kwzS0UquWhv+wH+hC4F8REeDRTqhplVA3kbgy/nQDeY=";
    };
    dpcpp-cpp-rt = {
      version = "2025.3.1";
      url = "https://files.pythonhosted.org/packages/9a/1f/ff1b20fe45c1a2077f1a11e2447826881987a76983facab763a72ee29fc8/dpcpp_cpp_rt-2025.3.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-ZWTxncV0XAC0nqdJUt8TwmxOI6ogtykpKKMNdeOE+YY=";
    };
    intel-opencl-rt = {
      version = "2025.3.1";
      url = "https://files.pythonhosted.org/packages/8b/de/6a4fa1e6e1ff1441a4197f08c92798367074f98e4f43ce0d94f36913ae90/intel_opencl_rt-2025.3.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-9Ux5f9g5ueXkQciU6rDhrcg5SgazxN84BFItYAWmYdk=";
    };
    mkl = {
      version = "2025.3.0";
      url = "https://files.pythonhosted.org/packages/6d/b4/ef531295ed33b929c6c5214421eeebe370f1be22536b6956b4aaf18fdbc5/mkl-2025.3.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-e4H10uA0Y3sYfKWGZoeMToiJmIp4454LbukuhGVo9mA=";
    };
    intel-openmp = {
      version = "2025.3.1";
      url = "https://files.pythonhosted.org/packages/da/ad/72e2fb7e30f5fd2b7650b721c5979cf2a614538fd99afb45672b31157fb9/intel_openmp-2025.3.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-LDVB6idfDoQXJDYSoWtvH00Vwen8yWZn2wgk0HNfFBM=";
    };
    tbb = {
      version = "2022.3.0";
      url = "https://files.pythonhosted.org/packages/e3/9e/b7f1f7af53580e4e8cf39cf51b14c8e295d767b3ae9d78b5007d6058cfc8/tbb-2022.3.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-p+Eiy5im+II5QDQaoyPc3/+nfjZxKiKhrjp2Qw+p9BI=";
    };
    tcmlib = {
      version = "1.4.1";
      url = "https://files.pythonhosted.org/packages/a1/a4/38e8b5a27b66ab286168ba6c449771ed71d71ec76524e7f12401474a5151/tcmlib-1.4.1-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-DVvZjbSNMb7H/tulwjWZv5rkPHAW1MOUbSUkLTIM7ok=";
    };
    umf = {
      version = "1.0.2";
      url = "https://files.pythonhosted.org/packages/27/8e/4a90b6aa955268988e7491f502b7ac2bd65cb954b4979bfcc892cf019b50/umf-1.0.2-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-700USiAHpzoaIu5XXuT1oYlKIGUyxvbXe0z1SGQ1Avs=";
    };
    intel-pti = {
      version = "0.15.0";
      url = "https://files.pythonhosted.org/packages/f4/f0/56874c288e637e1b8619813d5a928778a712e96456f19a2ca1f52b4c9eb0/intel_pti-0.15.0-py2.py3-none-manylinux_2_28_x86_64.whl";
      hash = "sha256-Yp+9+0wXAZh9zJ+OLAP8GLPsmrXIRi7p3nHJbGK4Lsw=";
    };
    triton-xpu = {
      version = "3.6.0";
      url = "https://download.pytorch.org/whl/triton_xpu-3.6.0-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
      hash = "sha256-e6neluXTZAC5lrn7nrOEQxlkU678Efr+GnuyJrxfuLs=";
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
      version = "1.0.2607232129";
      owner = "rgthree";
      repo = "rgthree-comfy";
      rev = "6b76ee6f2c5a007710b5a16f97c94330d6ecc871";
      hash = "sha256-tcgwh2xiUXyQpLuYy/X2kxMKZz1+VlLPRf7HQA3lvhk=";
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
      version = "git-2026-07-27-3b9c5cde4700";
      owner = "Lightricks";
      repo = "ComfyUI-LTXVideo";
      rev = "3b9c5cde4700917074823d45e25401d81049f8fc";
      hash = "sha256-Knxz0siBvoVqkwPMTtjW/W0/yvh2PYz8B4grdsvFY/I=";
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
