{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  cfg = config.services.garage;

  settings' = builtins.removeAttrs cfg.settings [ "rpc_secret_file" ];

  rpc-secret-file = cfg.settings.rpc_secret_file;

  toml = pkgs.formats.toml { };
  configFile = toml.generate "garage.toml" settings';
in
{
  disabledModules = [
    "${modulesPath}/services/web-servers/garage.nix"
  ];

  meta = {
    doc = /. + modulesPath + "/services/web-servers/garage.md";
    maintainers = with lib.maintainers; [ sodiboo ];
  };

  options.services.garage = {
    enable = lib.mkEnableOption "Garage Object Storage (S3 compatible)";

    logLevel = lib.mkOption {
      type = lib.types.enum [
        "error"
        "warn"
        "info"
        "debug"
        "trace"
      ];
      default = "info";
      example = "debug";
      description = "Garage log level, see <https://garagehq.deuxfleurs.fr/documentation/quick-start/#launching-the-garage-server> for examples.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = toml.type;

        options = {
          metadata_dir = lib.mkOption {
            default = "/var/lib/garage/meta";
            type = lib.types.path;
            description = "The metadata directory, put this on a fast disk (e.g. SSD) if possible.";
          };

          data_dir = lib.mkOption {
            default = "/var/lib/garage/data";
            example = [
              {
                path = "/var/lib/garage/data";
                capacity = "2T";
              }
            ];
            type = lib.types.either lib.types.path (lib.types.listOf lib.types.attrs);
            description = ''
              The directory in which Garage will store the data blocks of objects. This folder can be placed on an HDD.
              Since v0.9.0, Garage supports multiple data directories, refer to <https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/#data_dir> for the exact format.
            '';
          };

          allow_world_readable_secrets = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Whether to bypass the permission check garage applies to secrets. On by default, because it doesn't work very well with systemd's `LoadCredential=`.
            '';
          };

          rpc_secret_file = lib.mkOption {
            type = lib.types.pathWith { inStore = false; };
            description = ''
              Path to the RPC secret used to communicate in the garage cluster. Generate with `openssl rand -hex 32`.

              Must match on all nodes. Should only be readable by root; it is passed to `LoadCredential=`.
            '';
          };
        };
      };
      description = "Garage configuration, see <https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/> for reference.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      description = "Garage package to use, needs to be set explicitly. If you are upgrading from a major version, please read NixOS and Garage release notes for upgrade instructions.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.settings ? rpc_secret);
        message = ''
          `services.garage.settings.rpc_secret` is set. don't do this. use `rpc_secret_file` instead.
        '';
      }
    ];
    environment.etc."garage.toml" = {
      source = configFile;
    };

    systemd.services.garage = {
      description = "Garage Object Storage (S3 compatible)";
      after = [
        "network.target"
        "network-online.target"
      ];
      wants = [
        "network.target"
        "network-online.target"
      ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [
        configFile
      ];
      serviceConfig =
        let
          paths = lib.flatten (
            with cfg.settings;
            [
              metadata_dir
            ]
            # data_dir can either be a string or a list of attrs
            # if data_dir is a list, the actual path will in in the `path` attribute of each item
            # see https://garagehq.deuxfleurs.fr/documentation/reference-manual/configuration/#data_dir
            ++ lib.optional (lib.isList data_dir) (map (item: item.path) data_dir)
            ++ lib.optionals (lib.isString data_dir) [ data_dir ]
          );
          isDefault = lib.hasPrefix "/var/lib/garage";
          isDefaultStateDirectory = lib.any isDefault paths;
        in
        {
          ExecStart = "${cfg.package}/bin/garage server";

          StateDirectory = lib.mkIf isDefaultStateDirectory "garage";
          DynamicUser = lib.mkDefault true;
          ProtectHome = true;
          NoNewPrivileges = true;
          ReadWritePaths = lib.filter (x: !(isDefault x)) (lib.flatten [ paths ]);
          # Upstream recommendation https://garagehq.deuxfleurs.fr/documentation/cookbook/systemd/
          LimitNOFILE = 42000;

          LoadCredential = [ "rpc-secret:${rpc-secret-file}" ];
        };
      environment = {
        GARAGE_RPC_SECRET_FILE = "%d/rpc-secret";
        RUST_LOG = lib.mkDefault "garage=${cfg.logLevel}";
      };
    };
  };
}
