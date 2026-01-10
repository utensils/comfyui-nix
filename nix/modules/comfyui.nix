{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.comfyui;

  # Determine which package to use based on configuration
  # CUDA package uses pre-built wheels supporting all GPU architectures (Pascal through Hopper)
  resolvePackage = if cfg.cuda then pkgs.comfy-ui-cuda else pkgs.comfy-ui;
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

        When enabled, uses pre-built PyTorch CUDA wheels that support all GPU
        architectures from Pascal (GTX 1080) through Hopper (H100) in a single package.
        Requires NVIDIA drivers to be installed on the system.
      '';
    };

    cudaCapabilities = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = ''
        Optional list of CUDA compute capabilities to use for builds that honor
        `nixpkgs.config.cudaCapabilities`. When set, this updates the global
        nixpkgs configuration, so it affects other CUDA packages too.

        Note: ComfyUI's pre-built PyTorch wheels already support all GPU
        architectures (Pascal through Hopper). This setting is primarily useful
        for optimizing other CUDA-enabled packages in your system configuration.

        Example: [ "8.9" ] for Ada Lovelace (RTX 40xx) GPUs.

        Common values:
        - "6.1": Pascal (GTX 1080/1070)
        - "7.0": Volta (V100)
        - "7.5": Turing (RTX 20xx, GTX 16xx)
        - "8.0": Ampere (A100)
        - "8.6": Ampere (RTX 30xx)
        - "8.9": Ada Lovelace (RTX 40xx)
        - "9.0": Hopper (H100)

        See: https://developer.nvidia.com/cuda-gpus
      '';
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
        if cuda then pkgs.comfy-ui-cuda else pkgs.comfy-ui
      '';
      description = ''
        ComfyUI package to run. Automatically set based on CUDA configuration:
        - `cuda = true`: CUDA package (supports all GPU architectures)
        - Otherwise: CPU-only build

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
    nixpkgs.config = lib.mkIf (cfg.cudaCapabilities != null) {
      cudaCapabilities = cfg.cudaCapabilities;
    };

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
