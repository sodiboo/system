{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  cfg = config.services.continuwuity;

  format = pkgs.formats.toml { };
  configFile = format.generate "continuwuity.toml" cfg.settings;
in
{
  disabledModules = [
    "${modulesPath}/services/matrix/continuwuity.nix"
  ];

  meta.maintainers = with lib.maintainers; [ sodiboo ];

  options.services.continuwuity = {
    enable = lib.mkEnableOption "continuwuity";

    package = lib.mkPackageOption pkgs "matrix-continuwuity" { };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = format.type;
        options = {
          global.server_name = lib.mkOption {
            type = lib.types.nonEmptyStr;
            example = "example.com";
            description = "The server_name is the name of this server. It is used as a suffix for user and room ids.";
          };
          global.database_path = lib.mkOption {
            readOnly = true;
            type = lib.types.path;
            default = "/var/lib/continuwuity/";
            description = ''
              Path to the continuwuity database, the directory where continuwuity will save its data.
              Note that database_path cannot be edited because of the service's reliance on systemd StateDir.
            '';
          };
        };
      };
      default = { };
      description = ''
        Generates the continuwuity.toml configuration file. Refer to
        <https://continuwuity.org/configuration.html>
        for details on supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.settings ? global.unix_socket_path) || !(cfg.settings ? global.address);
        message = ''
          In `services.continuwuity.settings.global`, `unix_socket_path` and `address` cannot be set at the
          same time.
          Leave one of the two options unset or explicitly set them to `null`.
        '';
      }
    ];

    systemd.services.continuwuity = {
      description = "Continuwuity Matrix Server";
      documentation = [ "https://continuwuity.org/" ];
      environment.CONTINUWUITY_CONFIG = configFile;
      startLimitBurst = 5;
      startLimitIntervalSec = 60;
      serviceConfig = {
        DynamicUser = true;

        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        PrivateIPC = true;
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = "";
        SystemCallFilter = [
          "@system-service @resources"
          "~@clock @debug @module @mount @reboot @swap @cpu-emulation @obsolete @timer @chown @setuid @privileged @keyring @ipc"
        ];
        SystemCallErrorNumber = "EPERM";

        StateDirectory = "continuwuity";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "continuwuity";
        RuntimeDirectoryMode = "0700";

        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
