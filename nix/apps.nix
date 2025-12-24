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
        LATEST=$(curl -s https://api.github.com/repos/comfyanonymous/ComfyUI/releases/latest | jq -r '.tag_name')
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
      description = "Run ComfyUI with the CUDA-enabled Nix runtime";
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
