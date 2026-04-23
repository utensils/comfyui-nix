{
  pkgs,
  lib,
  versions,
}:
{
  mkDockerImage =
    {
      name,
      tag,
      comfyUiPackage,
      gpuSupport ? "none", # "none", "cuda", "rocm", "xpu"
      cudaVersion ? "cu128",
      extraLabels ? { },
    }:
    let
      useCuda = gpuSupport == "cuda";
      useRocm = gpuSupport == "rocm";
      useXpu = gpuSupport == "xpu";
      useCpu = gpuSupport == "none";
      baseEnv = [
        "HOME=/root"
        "COMFY_USER_DIR=/data"
        "TMPDIR=/tmp"
        "PATH=/bin:/usr/bin"
        "PYTHONUNBUFFERED=1"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
      ];
      cudaEnv = lib.optionals useCuda [
        "NVIDIA_VISIBLE_DEVICES=all"
        "NVIDIA_DRIVER_CAPABILITIES=compute,utility"
      ];
      # Intel compute-runtime ICD is registered via OCL_ICD_VENDORS so that
      # ocl-icd (via /etc/OpenCL/vendors) can find it inside the container.
      xpuEnv = lib.optionals useXpu [
        "OCL_ICD_VENDORS=${pkgs.intel-compute-runtime}/etc/OpenCL/vendors"
      ];
      titleSuffix =
        if useCuda then
          " CUDA"
        else if useRocm then
          " ROCm"
        else if useXpu then
          " XPU"
        else
          "";
      descSuffix =
        if useCuda then
          " with CUDA support for GPU acceleration"
        else if useRocm then
          " with ROCm support for GPU acceleration"
        else if useXpu then
          " with Intel XPU support (oneAPI / SYCL) for GPU acceleration"
        else
          " - The most powerful and modular diffusion model GUI";
      labels = {
        "org.opencontainers.image.title" = "ComfyUI" + titleSuffix;
        "org.opencontainers.image.description" = "ComfyUI" + descSuffix;
        "org.opencontainers.image.source" = "https://github.com/utensils/comfyui-nix";
        "org.opencontainers.image.licenses" = "GPL-3.0";
      }
      // extraLabels;
    in
    pkgs.dockerTools.buildImage {
      inherit name tag;
      created = versions.comfyui.releaseDate;

      copyToRoot = pkgs.buildEnv {
        name = "comfy-ui-root";
        paths = [
          pkgs.bash
          pkgs.coreutils
          pkgs.netcat
          pkgs.git
          pkgs.curl
          pkgs.jq
          pkgs.cacert
          pkgs.glib
          pkgs.libGL
          pkgs.libGLU
          pkgs.stdenv.cc.cc.lib
          comfyUiPackage
        ]
        ++ lib.optionals useRocm [
          # rocminfo suppresses a ComfyUI startup warning about missing AMD GPU info
          pkgs.rocmPackages.rocminfo
        ]
        ++ lib.optionals useXpu [
          # XPU userland: Level Zero loader, Intel compute-runtime (OpenCL ICD
          # + Level Zero driver). Users still must pass `--device /dev/dri` and
          # have a compatible i915/xe kernel driver on the host.
          pkgs.level-zero
          pkgs.intel-compute-runtime
          pkgs.ocl-icd
        ];
        pathsToLink = [
          "/bin"
          "/lib"
          "/share"
          "/etc"
        ];
      };

      config = {
        Entrypoint = [ "/bin/comfy-ui" ];
        Cmd = [
          "--listen"
          "0.0.0.0"
        ]
        ++ lib.optionals useCpu [ "--cpu" ];
        Env = baseEnv ++ cudaEnv ++ xpuEnv;
        ExposedPorts = {
          "8188/tcp" = { };
        };
        WorkingDir = "/data";
        Volumes = {
          "/data" = { };
          "/tmp" = { };
        };
        Healthcheck = {
          Test = [
            "CMD"
            "nc"
            "-z"
            "localhost"
            "8188"
          ];
          Interval = 30000000000;
          Timeout = 5000000000;
          Retries = 3;
          StartPeriod = 60000000000;
        };
        Labels = labels;
      };
    };
}
