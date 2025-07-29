{
  lib,
  pkgs,
  config,
  utils,
  ...
}:
let
  socket-proxy-unit = {
    options = {
      enable = lib.mkEnableOption "this systemd socket proxy" // {
        default = true;
      };

      connections-max = lib.mkOption {
        type = lib.types.ints.positive;
        default = 256;
        description = ''
          The maximum number of simultaneous connections that the socket proxy will handle.
          Any connections beyond this limit will be refused.
        '';
      };

      exit-idle-time = lib.mkOption {
        type = lib.types.str;
        default = "infinity";
        description = ''
          The time before exiting when no connections are active.
          Takes a unit-less value in seconds, or a time span value such as "5min 20s".
        '';
      };

      upstream = lib.mkOption {
        type = lib.types.str;
        example = "/run/path/to/socket";
        description = ''
          The upstream socket to which the socket proxy will forward connections.

          Can be one of the following:
          - starting with `/`: a file system socket in the `AF_UNIX` family
          - starting with `@`: an abstract socket in the `AF_UNIX` family
          - a internet address in the format `host:port` (TCP endpoint)

          If connecting to an internet socket, or an abstract socket, the socket proxy service will run in the host namespace by default.
          You can use `service.serviceConfig` to configure a private namespace for the service if needed.

          If connecting to a filesystem socket, the socket file must be accessible to all users (chmod 666).
          The containing directory can have more restrictive permissions, as the socket file is bind-mounted by systemd.
        '';
      };

      bypass-file-permissions = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If `upstream` is a file system socket, it is subject to file permissions.
          By default, we assume that it is accessible (chmod 666).

          If the socket has more restrictive permissions than chmod 666, you can set this option to `true`.
          This grants the socket proxy service the `CAP_DAC_OVERRIDE` ambient capability,
          allowing it to connect to the socket regardless of its permissions.

          This is not recommended, as it grants a powerful capability, but it can be useful in certain setups.
        '';
      };

      socket = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
        description = "The socket unit for the socket proxy. See {option}`systemd.sockets`.";
      };

      service = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
        description = "The service unit for the socket proxy. See {option}`systemd.services`.";
      };
    };
  };
in
{
  options.systemd-socket-proxyd = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule socket-proxy-unit);
    default = { };
    description = ''
      Configuration for systemd socket proxy units.

      Each socket proxy is a socket-activated service.

      You can define the addresses/paths they listens on in `socket.listenStreams`.
    '';
  };

  config.assertions = builtins.concatLists (
    lib.mapAttrsToList (
      name: cfg:
      let
        is-fs-upstream = lib.strings.hasPrefix "/" cfg.upstream;
      in
      [
        {
          assertion = cfg.bypass-file-permissions -> is-fs-upstream;
          message = ''
            systemd-socket-proxyd.${name}.bypass-file-permissions is enabled, but the upstream socket is not a filesystem socket.
            upstream = ${cfg.upstream}
          '';
        }
      ]
    ) config.systemd-socket-proxyd
  );

  config.systemd = lib.mkMerge (
    lib.mapAttrsToList (name: cfg: {
      sockets."socket-proxy-${name}" =
        { ... }:
        {
          imports = [ cfg.socket ];
          config = {
            enable = cfg.enable;
            requiredBy = [ config.systemd.services."socket-proxy-${name}".name ];
            socketConfig = {
              # this "polling" only applies *before* the connection is established.
              # in particular, if a service doesn't create its socket right away (it's `ready` too early)
              # then, the socket proxy will not initialize (`ConditionPathExists`) and that connection will be dropped
              PollLimitBurst = 1;
              PollLimitIntervalSec = 3;

              # additionally, when it fails that way, we want to ensure the remaining "pending" connections do not *immediately* flood the trigger limit.
              # as such, we flush them and just disconnect those clients.
              FlushPending = true;
            };
          };
        };
      services."socket-proxy-${name}" =
        { ... }:
        {
          imports = [ cfg.service ];
          config =
            let
              is-fs-upstream = lib.strings.hasPrefix "/" cfg.upstream;
              is-abstract-upstream = lib.strings.hasPrefix "@" cfg.upstream;
              is-internet-upstream = !(is-fs-upstream || is-abstract-upstream);
            in
            {
              enable = cfg.enable;
              unitConfig = lib.mkIf is-fs-upstream {
                ConditionPathExists = [ cfg.upstream ];
                AssertPathIsDirectory = [ "!${cfg.upstream}" ];
              };
              serviceConfig = lib.mkMerge [
                {
                  Type = "notify";
                  ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd ${
                    lib.escapeShellArgs [
                      "--connections-max"
                      cfg.connections-max
                      "--exit-idle-time"
                      cfg.exit-idle-time
                      (if is-fs-upstream then "/upstream" else cfg.upstream)
                    ]
                  }";

                  # This service needs access to the upstream socket file, and nothing else.
                  # So, let's put it in "chroot jail", in its own runtime directory.
                  # I would use something like `/var/empty` for this,
                  # but its permissions are too restrictive; so a runtime dir will do.
                  RuntimeDirectory = "socket-proxy/${name}";
                  RuntimeDirectoryMode = "0700";
                  RootDirectory = "%t/socket-proxy/${name}";
                  BindReadOnlyPaths = [ "/nix/store" ];

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
                  PrivateDevices = true;
                  RestrictRealtime = true;
                  RestrictNamespaces = true;
                  RestrictSUIDSGID = true;
                  LockPersonality = true;
                  MemoryDenyWriteExecute = true;

                  ProcSubset = "pid";
                  ProtectProc = "invisible";

                  NoNewPrivileges = true;

                  SystemCallArchitectures = "native";
                  SystemCallFilter = [
                    "@system-service"
                    "~@privileged @resources"
                    "~@chown @setuid @keyring"
                  ];

                  UMask = "0777";
                  DynamicUser = true;

                  CapabilityBoundingSet = lib.mkDefault ""; # no implicit capabilities
                }
                (lib.mkIf is-fs-upstream {
                  RestrictAddressFamilies = "AF_UNIX";

                  # systemd recommends *not* using `BindPaths` in a `DynamicUser`.
                  # in particular, you can potentially leak the dynamic uid through this.
                  # however, systemd-socket-proxyd never creates or chmods anything, so it's a non-issue.
                  # and, it also doesn't proxy ancillary data (fds), so nothing can leak through that either.
                  BindPaths = [ "${cfg.upstream}:/upstream" ];

                  # in an fs socket (but not an abstract socket),
                  # we can always isolate the networking namespace
                  PrivateNetwork = true;
                })
                (lib.mkIf (is-fs-upstream && !cfg.bypass-file-permissions) {
                  PrivateUsers = true;
                })
                (lib.mkIf (is-fs-upstream && cfg.bypass-file-permissions) {
                  # cannot set `PrivateUsers=true` here because `CAP_DAC_OVERRIDE` allows
                  # access to files owned by any user, but not files with an unknown owner

                  AmbientCapabilities = [ "CAP_DAC_OVERRIDE" ];
                  CapabilityBoundingSet = [ "CAP_DAC_OVERRIDE" ];
                })
                (lib.mkIf is-abstract-upstream {
                  RestrictAddressFamilies = "AF_UNIX";
                })
                (lib.mkIf is-internet-upstream {
                  RestrictAddressFamilies = [
                    "AF_INET"
                    "AF_INET6"
                  ];
                })
              ];
            };
        };
    }) config.systemd-socket-proxyd
  );
}
