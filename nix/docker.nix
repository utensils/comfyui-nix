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
      gpuSupport ? "none", # "none", "cuda", "rocm"
      cudaVersion ? "cu124",
      extraLabels ? { },
    }:
    let
      useCuda = gpuSupport == "cuda";
      useRocm = gpuSupport == "rocm";
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
      labels = {
        "org.opencontainers.image.title" =
          if useCuda then
            "ComfyUI CUDA"
          else if useRocm then
            "ComfyUI ROCm"
          else
            "ComfyUI";
        "org.opencontainers.image.description" =
          if useCuda then
            "ComfyUI with CUDA support for GPU acceleration"
          else if useRocm then
            "ComfyUI with ROCm support for GPU acceleration"
          else
            "ComfyUI - The most powerful and modular diffusion model GUI";
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
        Env = baseEnv ++ cudaEnv;
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
