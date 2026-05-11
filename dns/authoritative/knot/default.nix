{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
let
  cfg = config.knot;
in
{
  # There's a knot module in nixpkgs. I looked at it, and felt it provided little value for configuration, so i wanted to start completely fresh.
  # Disabling the upstream one will prevent it from being accidentally enabled.
  # I use `knot` option namespace over `services.knot` for brevity and conflict avoidance.
  disabledModules = [
    "${modulesPath}/services/networking/knot.nix"
  ];

  imports = [
    # the other module still needs to *exist*, else empty definitions for it are invalid
    (lib.mkRemovedOptionModule [ "services" "knot" ] "nothing should touch services.knot")
  ];

  options.knot = {
    enable = lib.mkEnableOption "knot";

    package = lib.mkPackageOption pkgs "knot-dns" { };

    # ports = lib.mkOption {
    #   type = lib.types.attrsOf lib.types.port;
    #   default = { };
    # };

    # ports-dgram = lib.mkOption {
    #   type = lib.types.attrsOf lib.types.port;
    #   default = { };
    # };

    settings = lib.mkOption {
      type = lib.types.submodule {
        imports = [
          "${modulesPath}/misc/assertions.nix"
          ./settings/toplevel.nix
        ];
        config._module.args.pkgs = pkgs;
      };
      default = { };
      apply = settings: lib.asserts.checkAssertWarn settings.assertions settings.warnings settings;
    };
  };

  config =
    let
      inherit
        (config.knot.lib.secrets-impl.prepare-systemd {
          inherit pkgs;
          settings = cfg.settings;
        })
        config-template
        substitute-config
        credentials
        ;
    in

    lib.mkIf cfg.enable {

      inherit (cfg.settings) assertions warnings;
      # caddy.settings.storage = lib.mkDefault {
      #   module = "file_system";
      #   root = "/var/lib/caddy";
      # };

      # systemd.sockets = lib.mkMerge (
      #   (map
      #     (
      #       {
      #         name,
      #         listenStreams,
      #         listenDatagrams,
      #       }:
      #       {
      #         "caddy-${name}" = {
      #           inherit listenStreams listenDatagrams;
      #           wantedBy = [ "multi-user.target" ];
      #           requiredBy = [ config.systemd.services.caddy.name ];
      #           socketConfig = {
      #             FileDescriptorName = name;
      #             Service = config.systemd.services.caddy.name;
      #           };
      #         };
      #       }
      #     )
      #     (
      #       lib.mapAttrsToList (name: port: {
      #         inherit name;
      #         listenStreams = [ (toString port) ];
      #         listenDatagrams = [ ];
      #       }) cfg.ports
      #       ++ lib.mapAttrsToList (name: port: {
      #         inherit name;
      #         listenStreams = [ ];
      #         listenDatagrams = [ (toString port) ];
      #       }) cfg.ports-dgram
      #     )
      #   )
      # );

      environment.etc."knot/knot.conf".source = config-template;

      systemd.services.knot = {
        wantedBy = [ "multi-user.target" ];
        wants = [ "network.target" ];
        after = [ "network.target" ];

        preStart = ''
          ${substitute-config} > /run/caddy/caddy.json
        '';

        confinement.enable = true;

        serviceConfig = {
          Type = "notify";
          ExecStart = "";

          LoadCredential = builtins.map ({ identifier, path }: "${identifier}:${path}") credentials;

          DynamicUser = true;
          StateDirectory = "knot";
          StateDirectoryMode = "700";
          LogsDirectory = "knot";
          LogsDirectoryMode = "700";
          RuntimeDirectory = "knot";
          RuntimeDirectoryMode = "700";
          WorkingDirectory = "%S/knot";

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
