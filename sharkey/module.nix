{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.sharkey;

  createDB = cfg.database.host == "127.0.0.1" && cfg.database.createLocally;
  createRedis = cfg.redis.host == "127.0.0.1" && cfg.redis.createLocally;

  settingsFormat = pkgs.formats.yaml {};
  configFile = settingsFormat.generate "sharkey-config.yml" cfg.settings;
in {
  options = {
    services.sharkey = with lib; {
      enable = mkEnableOption "sharkey";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.sharkey;
        defaultText = lib.literalExpression "pkgs.sharkey";
        description = "Sharkey package to use.";
      };

      database = {
        createLocally = mkOption {
          type = lib.types.bool;
          default = true;
        };

        host = mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };

        port = mkOption {
          type = lib.types.port;
          default = 5432;
        };

        name = mkOption {
          type = lib.types.str;
          default = "sharkey";
        };

        passwordFile = mkOption {
          description = ''
            Path to a file containing the password for the database user.

            This file must be readable by the `sharkey` user.

            If creating a database locally, it must also be readable by the `postgres` user.
          '';
          type = lib.types.path;
          example = "/run/secrets/sharkey-db-password";
        };
      };

      redis = {
        createLocally = mkOption {
          type = lib.types.bool;
          default = true;
        };

        host = mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };

        port = mkOption {
          type = lib.types.port;
          default = 6379;
        };

        passwordFile = mkOption {
          description = ''
            Path to a file containing the password for the redis server.

            This file must be readable by the `sharkey` user.
          '';
          type = lib.types.path;
          example = "/run/secrets/sharkey-redis-password";
        };
      };

      settings = mkOption {
        type = settingsFormat.type;
        default = {};
        description = ''
          Configuration for Sharkey, see
          <link xlink:href="https://activitypub.software/TransFem-org/Sharkey/-/blob/develop/.config/example.yml"/>
          for supported settings.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    documentation.enable = false;

    services.sharkey.settings = {
      db.host = cfg.database.host;
      db.port = cfg.database.port;
      db.db = cfg.database.name;
      db.user = cfg.database.name;
      db.pass = "$SHARKEY_DB_PASSWORD";
      redis.host = cfg.redis.host;
      redis.port = cfg.redis.port;
      redis.pass = "$SHARKEY_REDIS_PASSWORD";
    };

    environment.etc."sharkey.yml".source = configFile;

    systemd.services.sharkey = {
      after =
        ["network-online.target"]
        ++ lib.optionals createDB ["postgresql.service"]
        ++ lib.optionals createRedis ["redis-sharkey.service"];
      wantedBy = ["multi-user.target"];

      preStart = ''
        SHARKEY_DB_PASSWORD="$(cat ${lib.escapeShellArg cfg.database.passwordFile})" \
        SHARKEY_REDIS_PASSWORD="$(cat ${lib.escapeShellArg cfg.redis.passwordFile})" \
        ${pkgs.envsubst}/bin/envsubst -i "${configFile}" | tee $MISSKEY_CONFIG_YML
      '';

      environment.MISSKEY_CONFIG_YML = "/run/sharkey/config.yml";
      environment.NODE_ENV = "production";

      serviceConfig = {
        Type = "simple";
        User = "sharkey";

        StateDirectory = "sharkey";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "sharkey";
        RuntimeDirectoryMode = "0700";
        ExecStart = "${pkgs.sharkey}/bin/sharkey migrateandstart";
        TimeoutSec = 60;

        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "sharkey";
      };
    };

    services.postgresql = lib.mkIf createDB {
      enable = true;
      settings.port = cfg.database.port;
      ensureUsers = [
        {
          name = cfg.database.name;
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [cfg.database.name];
    };

    services.redis = lib.mkIf createRedis {
      servers.sharkey = {
        enable = true;
        user = "sharkey";
        bind = "127.0.0.1";
        port = cfg.redis.port;
        requirePassFile = cfg.redis.passwordFile;
      };
    };

    systemd.services.postgresql.postStart = lib.mkIf createDB ''
      $PSQL -tAc "ALTER ROLE ${cfg.database.name} WITH ENCRYPTED PASSWORD '$(printf "%s" $(cat ${cfg.database.passwordFile} | tr -d "\n"))';"
    '';

    users.users.sharkey = {
      group = "sharkey";
      isSystemUser = true;
      home = cfg.package;
      packages = [cfg.package pkgs.nodePackages.pnpm];
    };

    users.groups.sharkey = {};
  };
  meta.maintainers = with lib.maintainers; [sodiboo];
}
