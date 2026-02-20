{
  pkgs,
  packages,
}:
let
  mkApp =
    name: description: text: runtimeInputs:
    let
      script = pkgs.writeShellApplication {
        inherit name text runtimeInputs;
      };
    in
    {
      type = "app";
      program = "${script}/bin/${name}";
      meta = { inherit description; };
    };
in
{
  default = {
    type = "app";
    program = "${packages.default}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with Nix";
    };
  };

  update =
    mkApp "update-comfyui" "Check for ComfyUI updates"
      ''
        set -e
        echo "Fetching latest ComfyUI release..."
        LATEST=$(curl -s https://api.github.com/repos/Comfy-Org/ComfyUI/releases/latest | jq -r '.tag_name')
        echo "Latest version: $LATEST"
        echo ""
        echo "To update, modify these values in nix/versions.nix:"
        echo "  comfyui.version = \"''${LATEST#v}\";"
        echo ""
        echo "Then run: nix flake update"
        echo "And update the hash with: nix build 2>&1 | grep 'got:' | awk '{print $2}'"
      ''
      [
        pkgs.curl
        pkgs.jq
      ];
}
// pkgs.lib.optionalAttrs (packages ? cuda) {
  cuda = {
    type = "app";
    program = "${packages.cuda}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with CUDA (all GPU architectures)";
    };
  };
}
# Architecture-specific CUDA apps - Consumer GPUs
// pkgs.lib.optionalAttrs (packages ? cuda-sm61) {
  cuda-sm61 = {
    type = "app";
    program = "${packages.cuda-sm61}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with CUDA SM 6.1 (Pascal: GTX 1080, 1070, 1060)";
    };
  };
}
// pkgs.lib.optionalAttrs (packages ? cuda-sm75) {
  cuda-sm75 = {
    type = "app";
    program = "${packages.cuda-sm75}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with CUDA SM 7.5 (Turing: RTX 2080, 2070, GTX 1660)";
    };
  };
}
// pkgs.lib.optionalAttrs (packages ? cuda-sm86) {
  cuda-sm86 = {
    type = "app";
    program = "${packages.cuda-sm86}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with CUDA SM 8.6 (Ampere: RTX 3080, 3090, 3070)";
    };
  };
}
// pkgs.lib.optionalAttrs (packages ? cuda-sm89) {
  cuda-sm89 = {
    type = "app";
    program = "${packages.cuda-sm89}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with CUDA SM 8.9 (Ada Lovelace: RTX 4090, 4080, 4070)";
    };
  };
}
# Architecture-specific CUDA apps - Data center GPUs
// pkgs.lib.optionalAttrs (packages ? cuda-sm70) {
  cuda-sm70 = {
    type = "app";
    program = "${packages.cuda-sm70}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with CUDA SM 7.0 (Volta: V100)";
    };
  };
}
// pkgs.lib.optionalAttrs (packages ? cuda-sm80) {
  cuda-sm80 = {
    type = "app";
    program = "${packages.cuda-sm80}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with CUDA SM 8.0 (Ampere Datacenter: A100)";
    };
  };
}
// pkgs.lib.optionalAttrs (packages ? cuda-sm90) {
  cuda-sm90 = {
    type = "app";
    program = "${packages.cuda-sm90}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with CUDA SM 9.0 (Hopper: H100)";
    };
  };
}
// pkgs.lib.optionalAttrs (packages ? rocm) {
  rocm = {
    type = "app";
    program = "${packages.rocm}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with ROCm";
    };
  };
}
// pkgs.lib.optionalAttrs (packages ? dockerImage) {
  buildDocker = mkApp "build-docker" "Build ComfyUI Docker image (CPU)" ''
    echo "Building Docker image for ComfyUI..."
    docker load < ${packages.dockerImage}
    echo "Docker image built successfully! You can now run it with:"
    echo "docker run -p 8188:8188 -v \$PWD/data:/data comfy-ui:latest"
  '' [ pkgs.docker ];
}
// pkgs.lib.optionalAttrs (packages ? dockerImageCuda) {
  buildDockerCuda = mkApp "build-docker-cuda" "Build ComfyUI Docker image with CUDA support" ''
    echo "Building Docker image for ComfyUI with CUDA support..."
    docker load < ${packages.dockerImageCuda}
    echo "CUDA-enabled Docker image built successfully! You can now run it with:"
    echo "docker run --gpus all -p 8188:8188 -v \$PWD/data:/data comfy-ui:cuda"
    echo ""
    echo "Note: Requires nvidia-container-toolkit and Docker GPU support."
  '' [ pkgs.docker ];
}
// pkgs.lib.optionalAttrs (packages ? dockerImageRocm) {
  buildDockerRocm = mkApp "build-docker-rocm" "Build ComfyUI Docker image with ROCm support" ''
    echo "Building Docker image for ComfyUI with ROCm support..."
    docker load < ${packages.dockerImageRocm}
    echo "ROCm-enabled Docker image built successfully! You can now run it with:"
    echo "docker run --gpus all -p 8188:8188 -v \$PWD/data:/data comfy-ui:rocm"
  '' [ pkgs.docker ];
}
# Cross-platform Docker build apps (always available, use remote builder on non-Linux)
// pkgs.lib.optionalAttrs (packages ? dockerImageLinux) {
  buildDockerLinux = mkApp "build-docker-linux" "Build ComfyUI Docker image for Linux x86_64 (CPU)" ''
    echo "Building Linux x86_64 Docker image for ComfyUI..."
    echo "Note: Uses remote builder if running on non-Linux system"
    docker load < ${packages.dockerImageLinux}
    echo "Docker image built successfully! You can now run it with:"
    echo "docker run -p 8188:8188 -v \$PWD/data:/data comfy-ui:latest"
  '' [ pkgs.docker ];
}
// pkgs.lib.optionalAttrs (packages ? dockerImageLinuxCuda) {
  buildDockerLinuxCuda =
    mkApp "build-docker-linux-cuda" "Build ComfyUI Docker image for Linux x86_64 with CUDA"
      ''
        echo "Building Linux x86_64 Docker image for ComfyUI with CUDA support..."
        echo "Note: Uses remote builder if running on non-Linux system"
        docker load < ${packages.dockerImageLinuxCuda}
        echo "CUDA-enabled Docker image built successfully! You can now run it with:"
        echo "docker run --gpus all -p 8188:8188 -v \$PWD/data:/data comfy-ui:cuda"
        echo ""
        echo "Note: Requires nvidia-container-toolkit and Docker GPU support."
      ''
      [ pkgs.docker ];
}
// pkgs.lib.optionalAttrs (packages ? dockerImageLinuxRocm) {
  buildDockerLinuxRocm =
    mkApp "build-docker-linux-rocm" "Build ComfyUI Docker image for Linux x86_64 with ROCm"
      ''
        echo "Building Linux x86_64 Docker image for ComfyUI with ROCm support..."
        echo "Note: Uses remote builder if running on non-Linux system"
        docker load < ${packages.dockerImageLinuxRocm}
        echo "ROCm-enabled Docker image built successfully! You can now run it with:"
        echo "docker run --gpus all -p 8188:8188 -v \$PWD/data:/data comfy-ui:rocm"
      ''
      [ pkgs.docker ];
}
// pkgs.lib.optionalAttrs (packages ? dockerImageLinuxArm64) {
  buildDockerLinuxArm64 =
    mkApp "build-docker-linux-arm64" "Build ComfyUI Docker image for Linux ARM64 (CPU)"
      ''
        echo "Building Linux ARM64 Docker image for ComfyUI..."
        echo "Note: Uses remote builder if running on non-Linux system"
        docker load < ${packages.dockerImageLinuxArm64}
        echo "Docker image built successfully! You can now run it with:"
        echo "docker run -p 8188:8188 -v \$PWD/data:/data comfy-ui:latest"
      ''
      [ pkgs.docker ];
}
