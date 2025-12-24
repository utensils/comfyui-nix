{ pkgs, lib }:
{
  mkDockerImage =
    {
      name,
      tag,
      comfyUiPackage,
      cudaSupport ? false,
      cudaVersion ? "cu124",
      extraLabels ? { },
    }:
    let
      baseEnv = [
        "HOME=/root"
        "COMFY_USER_DIR=/data"
        "COMFY_SKIP_TEMPLATE_INPUTS=1"
        "TMPDIR=/tmp"
        "PATH=/bin:/usr/bin"
        "PYTHONUNBUFFERED=1"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
      ];
      cudaEnv = lib.optionals cudaSupport [
        "NVIDIA_VISIBLE_DEVICES=all"
        "NVIDIA_DRIVER_CAPABILITIES=compute,utility"
      ];
      labels = {
        "org.opencontainers.image.title" = if cudaSupport then "ComfyUI CUDA" else "ComfyUI";
        "org.opencontainers.image.description" =
          if cudaSupport then
            "ComfyUI with CUDA support for GPU acceleration"
          else
            "ComfyUI - The most powerful and modular diffusion model GUI";
        "org.opencontainers.image.source" = "https://github.com/utensils/comfyui-nix";
        "org.opencontainers.image.licenses" = "GPL-3.0";
      } // extraLabels;
    in
    pkgs.dockerTools.buildImage {
      inherit name tag;
      created = "now";

      copyToRoot = pkgs.buildEnv {
        name = "root";
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
        ];
        pathsToLink = [
          "/bin"
          "/etc"
          "/lib"
          "/share"
        ];
      };

      config = {
        Cmd = [
          "/bin/bash"
          "-c"
          (
            if cudaSupport then
              "mkdir -p /tmp /root/.config/comfy-ui /data && export COMFY_USER_DIR=/data && export TMPDIR=/tmp && /bin/comfy-ui --listen 0.0.0.0"
            else
              "mkdir -p /tmp /root/.config/comfy-ui /data && export COMFY_USER_DIR=/data && export TMPDIR=/tmp && /bin/comfy-ui --listen 0.0.0.0 --cpu"
          )
        ];
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
