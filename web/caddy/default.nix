{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
let
  cfg = config.caddy;

  caddy-runner = pkgs.callPackage ./runner.nix {
    caddy = cfg.package;
  };
in
{
  # There's a caddy module in nixpkgs. I looked at it, and felt it provided little value for configuration, so i wanted to start completely fresh.
  # Disabling the upstream one will prevent it from being accidentally enabled.
  # I use `caddy` option namespace over `services.caddy` for brevity and conflict avoidance.
  disabledModules = [
    "${modulesPath}/services/web-servers/caddy/default.nix"
  ];

  imports = lib.filesystem.listFilesRecursive ./types ++ [
    # the other module still needs to *exist*, else empty definitions for it are invalid
    (lib.mkRemovedOptionModule [ "services" "caddy" ] "nothing should touch services.caddy")
  ];

  options.caddy = {
    enable = lib.mkEnableOption "caddy";

    package = lib.mkPackageOption pkgs "caddy" { };

    ports = lib.mkOption {
      type = lib.types.attrsOf lib.types.port;
      default = { };
    };

    ports-dgram = lib.mkOption {
      type = lib.types.attrsOf lib.types.port;
      default = { };
    };

    settings = lib.mkOption {
      type = config.caddy.lib.types.settings;
      default = { };
    };
  };

  config =
    let
      inherit
        (config.caddy.lib.secrets-impl.prepare-systemd {
          inherit pkgs;
          settings = cfg.settings;
        })
        config-template
        substitute-config
        credentials
        ;
    in

    lib.mkIf cfg.enable {
      caddy.settings.storage = lib.mkDefault {
        module = "file_system";
        root = "/var/lib/caddy";
      };

      systemd.sockets = lib.mkMerge (
        (map
          (
            {
              name,
              listenStreams,
              listenDatagrams,
            }:
            {
              "caddy-${name}" = {
                inherit listenStreams listenDatagrams;
                wantedBy = [ "multi-user.target" ];
                requiredBy = [ config.systemd.services.caddy.name ];
                socketConfig = {
                  FileDescriptorName = name;
                  Service = config.systemd.services.caddy.name;
                };
              };
            }
          )
          (
            lib.mapAttrsToList (name: port: {
              inherit name;
              listenStreams = [ (toString port) ];
              listenDatagrams = [ ];
            }) cfg.ports
            ++ lib.mapAttrsToList (name: port: {
              inherit name;
              listenStreams = [ ];
              listenDatagrams = [ (toString port) ];
            }) cfg.ports-dgram
          )
        )
      );

      environment.etc."caddy/caddy.json".source = config-template;

      systemd.services.caddy = {
        startLimitIntervalSec = 14400;
        startLimitBurst = 10;

        after = [ "network.target" ];

        preStart = ''
          ${substitute-config} > /run/caddy/caddy.json
        '';

        # Caddy needs `HOME` to be set or it throws warnings.
        environment.HOME = "%S/caddy";

        confinement.enable = true;

        serviceConfig = {
          # IMPORTANT: need resolv.conf, or Go stdlib will try and (fail) to resolve DNS on localhost.
          # DNS is *necessary* and not configurable in Caddy for things like communicating with ACME directory.
          # and i only noticed this because i set `confinement.enable` last. i thought everything just worked. NO IT DIDN'T.
          # lmao. ugh. horrible to debug.
          BindReadOnlyPaths = ["/etc/resolv.conf"];

          Type = "notify";
          ExecStart = "${lib.getExe caddy-runner} run --config /run/caddy/caddy.json";

          LoadCredential = builtins.map ({ identifier, path }: "${identifier}:${path}") credentials;

          DynamicUser = true;
          StateDirectory = "caddy";
          StateDirectoryMode = "700";
          LogsDirectory = "caddy";
          LogsDirectoryMode = "700";
          RuntimeDirectory = "caddy";
          RuntimeDirectoryMode = "700";
          WorkingDirectory = "%S/caddy";

          Restart = "on-failure";
          RestartPreventExitStatus = 1;
          RestartSec = "5s";

          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectClock = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          PrivateTmp = true;
          PrivateMounts = true;
          PrivateUsers = true;
          PrivateDevices = true;
          RestrictRealtime = true;
          RestrictNamespaces = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;

          ProcSubset = "pid";
          ProtectProc = "invisible";

          NoNewPrivileges = true;

          RestrictAddressFamilies = [
            "AF_UNIX"
            "AF_INET"
            "AF_INET6"
          ];

          CapabilityBoundingSet = "";
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged @resources"
          ];

          UMask = "0077";
        };
      };
    };
}
