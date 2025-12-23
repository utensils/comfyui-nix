{
  pkgs,
  packages,
  linuxSystem,
  isLinuxCrossCompile,
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

  buildDockerScript = ''
    echo "Building Docker image for ComfyUI..."
    docker load < ${packages.dockerImage}
    echo "Docker image built successfully! You can now run it with:"
    echo "docker run -p 8188:8188 -v \$PWD/data:/data comfy-ui:latest"
  '';

  buildDockerCudaScript = ''
    echo "Building Docker image for ComfyUI with CUDA support..."
    docker load < ${packages.dockerImageCuda}
    echo "CUDA-enabled Docker image built successfully! You can now run it with:"
    echo "docker run --gpus all -p 8188:8188 -v \$PWD/data:/data comfy-ui:cuda"
    echo ""
    echo "Note: Requires nvidia-container-toolkit and Docker GPU support."
  '';

  buildDockerLinuxScript = ''
    echo "Building Linux Docker image for ComfyUI (cross-compiled from macOS)..."
    echo "Target architecture: ${linuxSystem}"
    docker load < ${packages.dockerImageLinux}
    echo ""
    echo "Linux Docker image built successfully! You can now run it with:"
    echo "docker run -p 8188:8188 -v \$PWD/data:/data comfy-ui:latest"
  '';

  buildDockerLinuxCudaScript = ''
    echo "Building Linux CUDA Docker image for ComfyUI (cross-compiled from macOS)..."
    echo "Target architecture: ${linuxSystem}"
    docker load < ${packages.dockerImageLinuxCuda}
    echo ""
    echo "Linux CUDA Docker image built successfully! You can now run it with:"
    echo "docker run --gpus all -p 8188:8188 -v \$PWD/data:/data comfy-ui:cuda"
    echo ""
    echo "Note: Requires nvidia-container-toolkit and Docker GPU support."
  '';

  updateScript = ''
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
  '';

  lintScript = ''
    echo "Running ruff linter..."
    ruff check --no-cache src/
  '';

  formatScript = ''
    echo "Formatting code with ruff..."
    ruff format --no-cache src/
  '';

  lintFixScript = ''
    echo "Running ruff linter with auto-fix..."
    ruff check --no-cache --fix src/
  '';

  typeCheckScript = ''
    echo "Running pyright type checker..."
    pyright --pythonpath ${packages.pythonRuntime}/bin/python src/
  '';

  checkAllScript = ''
    echo "Running all checks..."
    echo ""
    echo "==> Running ruff linter..."
    ruff check --no-cache src/
    RUFF_EXIT=$?
    echo ""
    echo "==> Running pyright type checker..."
    pyright --pythonpath ${packages.pythonRuntime}/bin/python src/
    PYRIGHT_EXIT=$?
    echo ""
    if [ $RUFF_EXIT -eq 0 ] && [ $PYRIGHT_EXIT -eq 0 ]; then
      echo "All checks passed!"
      exit 0
    else
      echo "Some checks failed."
      exit 1
    fi
  '';

  mutableScript = ''
    export COMFY_MODE=mutable
    exec ${packages.default}/bin/comfy-ui "$@"
  '';
in
{
  default = {
    type = "app";
    program = "${packages.default}/bin/comfy-ui";
    meta = {
      description = "Run ComfyUI with Nix";
    };
  };

  buildDocker = mkApp "build-docker" "Build ComfyUI Docker image (CPU)" buildDockerScript [
    pkgs.docker
  ];
  buildDockerCuda =
    mkApp "build-docker-cuda" "Build ComfyUI Docker image with CUDA support" buildDockerCudaScript
      [ pkgs.docker ];

  update = mkApp "update-comfyui" "Check for ComfyUI updates" updateScript [
    pkgs.curl
    pkgs.jq
  ];

  lint = mkApp "lint" "Run ruff linter on Python code" lintScript [ pkgs.ruff ];
  format = mkApp "format" "Format Python code with ruff" formatScript [ pkgs.ruff ];
  lint-fix = mkApp "lint-fix" "Run ruff linter with auto-fix" lintFixScript [ pkgs.ruff ];
  type-check = mkApp "type-check" "Run pyright type checker on Python code" typeCheckScript [
    pkgs.pyright
  ];
  check-all = mkApp "check-all" "Run all Python code checks (ruff + pyright)" checkAllScript [
    pkgs.ruff
    pkgs.pyright
  ];

  mutable =
    mkApp "comfy-ui-mutable" "Run ComfyUI in mutable mode (allows ComfyUI-Manager/pip installs)"
      mutableScript
      [ ];
}
// (
  if isLinuxCrossCompile then
    {
      buildDockerLinux =
        mkApp "build-docker-linux" "Build Linux Docker image from macOS (cross-compile)"
          buildDockerLinuxScript
          [ pkgs.docker ];
      buildDockerLinuxCuda =
        mkApp "build-docker-linux-cuda" "Build Linux CUDA Docker image from macOS (cross-compile)"
          buildDockerLinuxCudaScript
          [ pkgs.docker ];
    }
  else
    { }
)
