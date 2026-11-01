{
  lib,
  pkgs,
  config,
  ...
}:

let

  credential-unit = { name, ... }: {
    options = {
      enable = lib.mkEnableOption "this oneshot credential" // {
        default = true;
      };

      name = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = config.systemd.sockets."oneshot-credential-${name}".name;
      };

      path = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = "/run/oneshot-credentials/${name}";
      };

      socket = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
        description = "The socket unit for the credential. See {option}`systemd.sockets`.";
      };

      service = lib.mkOption {
        type = lib.types.deferredModule;
        default = { };
        description = "The service unit for the credential. See {option}`systemd.services`.";
      };
    };
  };
in
{

  options.oneshot-credentials = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule credential-unit);
    default = { };
    description = ''
      Configuration for oneshot credentials.

      Each oneshot credential is a socket-activated service that prints to `stdout`.

      You can define the addresses/paths they listen on in `socket.listenStreams`.
    '';
  };

  config.systemd = lib.mkMerge (
    lib.mapAttrsToList (name: cfg: {
      sockets."oneshot-credential-${name}" =
        { ... }:
        {
          imports = [ cfg.socket ];
          config = {
            enable = cfg.enable;

            listenStreams = [ cfg.path ];

            socketConfig = {
              # if the upstream service is ready too early, its socket may not exist yet
              # and therefore the socket proxy startup is skipped.
              # but, that's a "cheap" fail; it shouldn't prevent triggering the socket proxy ever again.
              TriggerLimitBurst = 0;

              # additionally, let's not spam the logs: when inactive, poll once every 3 seconds.
              PollLimitBurst = 1;
              PollLimitIntervalSec = 3;
              # and after one is skipped, flush the rest.
              FlushPending = true;

              Accept = lib.mkForce true;

              SocketMode = lib.mkDefault "0400";
              DirectoryMode = lib.mkDefault "0400";
            };
          };
        };
      services."oneshot-credential-${name}@" =
        { ... }:
        {
          imports = [ cfg.service ];
          config = {
            enable = cfg.enable;

            confinement.enable = true;
            confinement.mode = "chroot-only";

            serviceConfig = {
              StandardOutput = "socket";
              CollectMode = "inactive-or-failed";

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
              DynamicUser = lib.mkDefault true;

              CapabilityBoundingSet = lib.mkDefault ""; # no implicit capabilities
            };
          };
        };
    }) config.oneshot-credentials
  );
}
