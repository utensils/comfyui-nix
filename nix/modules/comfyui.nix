{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.comfyui;
  args = [
    "--listen"
    cfg.listenAddress
    "--port"
    (toString cfg.port)
    "--base-directory"
    cfg.dataDir
  ] ++ cfg.extraArgs;
  env = cfg.environment;
  escapedArgs = lib.concatStringsSep " " (map lib.escapeShellArg args);
  execStart = "${cfg.package}/bin/comfy-ui ${escapedArgs}";

  # User/group creation: only create if createUser is true AND the user doesn't
  # already exist in the system (i.e., not a pre-existing user like "nobody")
  isSystemUser = cfg.user == "comfyui";
  isSystemGroup = cfg.group == "comfyui";

  dataDirRule = "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} - -";
  isDefaultDataDir = cfg.dataDir == "/var/lib/comfyui";
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

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.comfy-ui;
      description = "ComfyUI package to run.";
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
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
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
          ProtectHome = true;
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
