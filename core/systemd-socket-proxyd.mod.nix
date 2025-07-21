{
  universal =
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

          backend = lib.mkOption {
            type = lib.types.str;
            example = "/run/path/to/socket";
            description = ''
              The backend socket to which the socket proxy will forward connections.

              Can be one of the following:
              - starting with `/`: a file system socket in the `AF_UNIX` family
              - starting with `@`: an abstract socket in the `AF_UNIX` family
              - a network address in the format `host:port` (TCP connection)

              If connecting to a network socket (or an abstract socket), the socket proxy service will run in the host namespace by default.
              You can use `service.serviceConfig` to configure a private namespace for the service if needed.
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

          The options `listenStreams` and `socketConfig` are used to configure the `.socket` unit.
          All other options are used to configure the socket proxy service.
        '';
      };

      config.systemd = lib.mkMerge (
        lib.mapAttrsToList (name: cfg: {
          sockets."socket-proxy-${name}" =
            { ... }:
            {
              imports = [ cfg.socket ];
              config.enable = cfg.enable;
            };
          services."socket-proxy-${name}" =
            { ... }:
            {
              imports = [ cfg.service ];
              config = {
                enable = cfg.enable;
                requires = [ config.systemd.sockets."socket-proxy-${name}".name ];
                serviceConfig = lib.mkMerge [
                  {
                    Type = "notify";
                    ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd ${
                      lib.escapeShellArgs [
                        "--connections-max"
                        cfg.connections-max
                        "--exit-idle-time"
                        cfg.exit-idle-time
                        cfg.backend
                      ]
                    }";

                    # `systemd-socket-proxyd` has to run as root (Scary!)
                    # so, let's should harden it as much as possible.
                    #   RootDirectory = "/var/empty";
                    #   PrivateMounts = true;
                    #   PrivatePIDs = true;
                    #   PrivateUsers = true;
                    # }
                    # (lib.mkIf (lib.strings.hasPrefix "/" cfg.backend) {
                    #   BindPaths = cfg.backend;
                    #   PrivateNetwork = true;
                    # })
                    # {

                  }
                ];
              };
            };
        }) config.systemd-socket-proxyd
      );

    };
}
