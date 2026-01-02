{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.comfyui;

  # Architecture-to-package mapping for cudaArch option
  archPackages = {
    # Consumer GPUs
    sm61 = pkgs.comfy-ui-cuda-sm61; # Pascal (GTX 1080, 1070, 1060)
    sm75 = pkgs.comfy-ui-cuda-sm75; # Turing (RTX 2080, 2070, GTX 1660)
    sm86 = pkgs.comfy-ui-cuda-sm86; # Ampere (RTX 3080, 3090, 3070)
    sm89 = pkgs.comfy-ui-cuda-sm89; # Ada Lovelace (RTX 4090, 4080, 4070)
    # Data center GPUs
    sm70 = pkgs.comfy-ui-cuda-sm70; # Volta (V100)
    sm80 = pkgs.comfy-ui-cuda-sm80; # Ampere Datacenter (A100)
    sm90 = pkgs.comfy-ui-cuda-sm90; # Hopper (H100)
  };

  # Determine which package to use based on configuration
  resolvePackage =
    if cfg.cudaCapabilities != null then
      # Custom capabilities - build on demand
      pkgs.comfyui-nix.mkComfyUIWithCuda cfg.cudaCapabilities
    else if cfg.cudaArch != null then
      # Pre-built architecture-specific package
      archPackages.${cfg.cudaArch}
    else if cfg.cuda then
      # Default CUDA (RTX: SM 7.5, 8.6, 8.9)
      pkgs.comfy-ui-cuda
    else
      # CPU-only
      pkgs.comfy-ui;
  args = [
    "--listen"
    cfg.listenAddress
    "--port"
    (toString cfg.port)
    "--base-directory"
    cfg.dataDir
  ]
  ++ lib.optional cfg.enableManager "--enable-manager"
  ++ cfg.extraArgs;
  env = cfg.environment;
  escapedArgs = lib.concatStringsSep " " (map lib.escapeShellArg args);
  execStart = "${cfg.package}/bin/comfy-ui ${escapedArgs}";

  # User/group creation: only create if createUser is true AND the user doesn't
  # already exist in the system (i.e., not a pre-existing user like "nobody")
  isSystemUser = cfg.user == "comfyui";
  isSystemGroup = cfg.group == "comfyui";

  dataDirRule = "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} - -";
  isDefaultDataDir = cfg.dataDir == "/var/lib/comfyui";
  # Auto-detect if dataDir is under /home/ to disable ProtectHome
  dataDirInHome = lib.hasPrefix "/home/" cfg.dataDir;
  serviceDescription = "ComfyUI - A powerful and modular diffusion model GUI";

  # Generate preStart script for symlinking custom nodes
  customNodesPreStart = lib.optionalString (cfg.customNodes != { }) ''
    # Create custom_nodes directory if it doesn't exist
    mkdir -p "${cfg.dataDir}/custom_nodes"

    # Symlink declarative custom nodes
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: src:
        let
          targetPath = "${cfg.dataDir}/custom_nodes/${name}";
        in
        ''
          # Handle ${name}: remove if not a symlink or points elsewhere
          if [[ -e "${targetPath}" || -L "${targetPath}" ]]; then
            if [[ ! -L "${targetPath}" ]] || [[ "$(readlink "${targetPath}")" != "${src}" ]]; then
              rm -rf "${targetPath}"
            fi
          fi
          # Create symlink if needed
          if [[ ! -e "${targetPath}" ]]; then
            ln -s "${src}" "${targetPath}"
            echo "Linked custom node: ${name} -> ${src}"
          fi
        ''
      ) cfg.customNodes
    )}
  '';
in
{
  options.services.comfyui = {
    enable = lib.mkEnableOption "ComfyUI service";

    cuda = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable CUDA support for NVIDIA GPUs. This is recommended for most users
        with NVIDIA graphics cards as it provides significant performance improvements.

        When enabled, uses the CUDA-enabled PyTorch and enables GPU acceleration.
        Requires NVIDIA drivers to be installed on the system.

        By default, CUDA builds target RTX consumer GPUs (SM 7.5, 8.6, 8.9).
        For other GPUs, use `cudaArch` or `cudaCapabilities` options.
      '';
    };

    cudaArch = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "sm61"
          "sm70"
          "sm75"
          "sm80"
          "sm86"
          "sm89"
          "sm90"
        ]
      );
      default = null;
      description = ''
        Select a pre-built CUDA architecture-specific package.
        This is faster than `cudaCapabilities` as it uses cached builds.

        Available architectures:
        - `sm61`: Pascal (GTX 1080, 1070, 1060)
        - `sm70`: Volta (V100) - data center
        - `sm75`: Turing (RTX 2080, 2070, GTX 1660)
        - `sm80`: Ampere Datacenter (A100)
        - `sm86`: Ampere Consumer (RTX 3080, 3090, 3070)
        - `sm89`: Ada Lovelace (RTX 4090, 4080, 4070)
        - `sm90`: Hopper (H100) - data center

        When set, overrides the default RTX build. Implies `cuda = true`.
      '';
      example = "sm61";
    };

    cudaCapabilities = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = ''
        Custom list of CUDA compute capabilities to build for.
        This triggers an on-demand build with the specified architectures.

        Use this when you need multiple architectures or a specific combination
        not covered by pre-built packages. Note: this will compile from source
        which can take significant time.

        Common capability values:
        - "6.1": Pascal (GTX 1080, 1070)
        - "7.0": Volta (V100)
        - "7.5": Turing (RTX 2080, GTX 1660)
        - "8.0": Ampere Datacenter (A100)
        - "8.6": Ampere Consumer (RTX 3090, 3080)
        - "8.9": Ada Lovelace (RTX 4090, 4080)
        - "9.0": Hopper (H100)

        When set, this takes precedence over `cuda` and `cudaArch`.
      '';
      example = [
        "6.1"
        "8.6"
      ];
    };

    enableManager = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable the built-in ComfyUI Manager for installing custom nodes and models.

        When enabled, adds --enable-manager to the command line arguments.
        The manager allows runtime installation of custom nodes, which will install
        additional Python packages to <dataDir>/.pip-packages/.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = resolvePackage;
      defaultText = lib.literalExpression ''
        # Resolved based on cudaCapabilities > cudaArch > cuda > CPU
        if cudaCapabilities != null then mkComfyUIWithCuda cudaCapabilities
        else if cudaArch != null then pkgs.comfy-ui-cuda-''${cudaArch}
        else if cuda then pkgs.comfy-ui-cuda
        else pkgs.comfy-ui
      '';
      description = ''
        ComfyUI package to run. Automatically set based on CUDA configuration:

        1. `cudaCapabilities` set: builds with custom CUDA capabilities
        2. `cudaArch` set: uses pre-built architecture-specific package
        3. `cuda = true`: uses default RTX package (SM 7.5, 8.6, 8.9)
        4. Otherwise: CPU-only build

        Can be overridden for fully custom builds.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8188;
      description = "Port for ComfyUI to listen on.";
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to listen on (use 0.0.0.0 for all interfaces).";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/comfyui";
      description = "Base directory for ComfyUI data (models, input, output, custom nodes).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "comfyui";
      description = "User account to run ComfyUI under.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "comfyui";
      description = "Group to run ComfyUI under.";
    };

    createUser = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to create the ComfyUI system user and group.
        When true and user/group are set to "comfyui" (default), creates a dedicated
        system account. Set to false if using a pre-existing user account.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the configured port in the firewall.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra CLI arguments passed to ComfyUI.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Environment variables for the ComfyUI service.";
    };

    customNodes = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = ''
        Declarative custom nodes to install. Each attribute name becomes
        the directory name under custom_nodes/, and the value should be
        a derivation containing the node source (e.g., from fetchFromGitHub).

        Nodes are symlinked into the data directory at service start.
        This is the pure Nix way to manage custom nodes - fully reproducible
        and version-pinned.

        Note: Custom nodes with Python dependencies beyond ComfyUI's base
        environment may require additional configuration. For complex nodes,
        consider creating a custom derivation that bundles dependencies.
      '';
      example = lib.literalExpression ''
        {
          # Fetch a custom node from GitHub
          ComfyUI-Impact-Pack = pkgs.fetchFromGitHub {
            owner = "ltdrdata";
            repo = "ComfyUI-Impact-Pack";
            rev = "v1.0.0";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };

          # Use a local path (for development)
          my-custom-node = /path/to/my-node;

          # Or reference a pre-packaged node (future)
          # controlnet-aux = comfyui-nix.customNodes.controlnet-aux;
        }
      '';
    };

    requiresMounts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of mount units that must be available before ComfyUI starts.
        Useful when dataDir is on a separate mount (NFS, ZFS dataset, etc.).

        Example: [ "home-user-AI.mount" ] for /home/user/AI
        Mount unit names use dashes instead of slashes.
      '';
      example = [ "home-jamesbrink-AI.mount" ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Create system user/group only when using default "comfyui" names
    users.users = lib.mkIf (cfg.createUser && isSystemUser) {
      ${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
        description = "ComfyUI service user";
      };
    };

    users.groups = lib.mkIf (cfg.createUser && isSystemGroup) {
      ${cfg.group} = { };
    };

    systemd.tmpfiles.rules = [ dataDirRule ];

    systemd.services.comfyui = {
      description = serviceDescription;
      after = [ "network-online.target" ] ++ cfg.requiresMounts;
      wants = [ "network-online.target" ];
      requires = cfg.requiresMounts;
      wantedBy = [ "multi-user.target" ];

      # Symlink declarative custom nodes before starting
      preStart = customNodesPreStart;

      serviceConfig = lib.mkMerge [
        {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.dataDir;
          ExecStart = execStart;
          Restart = "on-failure";
          RestartSec = 5;

          # Security hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          # Disable ProtectHome when dataDir is under /home/
          ProtectHome = !dataDirInHome;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;

          # Allow writes to data directory
          ReadWritePaths = [ cfg.dataDir ];

          # Allow GPU access (required for CUDA/ROCm)
          SupplementaryGroups = [
            "video"
            "render"
          ];
        }
        (lib.optionalAttrs isDefaultDataDir { StateDirectory = "comfyui"; })
      ];

      environment = env;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
