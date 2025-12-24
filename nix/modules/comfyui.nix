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
  shouldCreateUser = cfg.createUser && cfg.user == "comfyui";
  shouldCreateGroup = cfg.createUser && cfg.group == "comfyui";
  dataDirRule = "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} - -";
  isDefaultDataDir = cfg.dataDir == "/var/lib/comfyui";
  serviceDescription = "ComfyUI service";
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
      description = "Whether to create the ComfyUI system user/group when using defaults.";
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
  };

  config = lib.mkIf cfg.enable {
    users.users = lib.mkIf shouldCreateUser {
      ${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
      };
    };

    users.groups = lib.mkIf shouldCreateGroup {
      ${cfg.group} = { };
    };

    systemd.tmpfiles.rules = [ dataDirRule ];

    systemd.services.comfyui = {
      description = serviceDescription;
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = lib.mkMerge [
        {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          WorkingDirectory = cfg.dataDir;
          ExecStart = execStart;
          Restart = "on-failure";
          RestartSec = 5;
        }
        (lib.optionalAttrs isDefaultDataDir { StateDirectory = "comfyui"; })
      ];

      environment = env;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
