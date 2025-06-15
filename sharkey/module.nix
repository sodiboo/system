{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.sharkey;

  createDB = cfg.database.host == "127.0.0.1" && cfg.database.createLocally;
  createRedis = cfg.redis.host == "127.0.0.1" && cfg.redis.createLocally;
  createMeili = cfg.meilisearch.host == "127.0.0.1" && cfg.meilisearch.createLocally;

  settingsFormat = pkgs.formats.yaml { };
  configFile = settingsFormat.generate "sharkey-config.yml" cfg.settings;
in
{
  options = {
    services.sharkey = {
      enable = lib.mkEnableOption "sharkey";

      domain = lib.mkOption {
        type = lib.types.str;
        example = "shonk.social";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.sharkey;
        defaultText = lib.literalExpression "pkgs.sharkey";
        description = "Sharkey package to use.";
      };

      database = {
        createLocally = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 5432;
        };

        name = lib.mkOption {
          type = lib.types.str;
          default = "sharkey";
        };

        passwordFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to a file containing the database password.

            Corresponds to `services.sharkey.settings.db.pass`.
          '';
        };
      };

      redis = {
        createLocally = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 6379;
        };

        passwordFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to a file containing the password to the redis server.

            Corresponds to `services.sharkey.settings.redis.pass`.
          '';
        };
      };

      meilisearch = {
        createLocally = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 7700;
        };

        index = lib.mkOption {
          type = lib.types.str;
          default = lib.replaceStrings [ "." ] [ "_" ] cfg.domain;
        };

        apiKeyFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to a file containing the Meilisearch API key.

            Corresponds to `services.sharkey.settings.meilisearch.apiKey`.
          '';
        };
      };

      settings = lib.mkOption {
        type = settingsFormat.type;
        default = { };
        description = ''
          Configuration for Sharkey, see
          <link xlink:href="https://activitypub.software/TransFem-org/Sharkey/-/blob/develop/.config/example.yml"/>
          for supported settings.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.sharkey.settings = {
      url = "https://${cfg.domain}/";
      db.host = cfg.database.host;
      db.port = cfg.database.port;
      db.db = cfg.database.name;
      db.user = cfg.database.name;
      db.pass = "@DATABASE_PASSWORD@";
      redis.host = cfg.redis.host;
      redis.port = cfg.redis.port;
      redis.pass = "@REDIS_PASSWORD@";
      meilisearch.host = cfg.meilisearch.host;
      meilisearch.port = cfg.meilisearch.port;
      meilisearch.apiKey = "@MEILISEARCH_KEY@";
      meilisearch.index = cfg.meilisearch.index;
      meilisearch.ssl = !createMeili;
      meilisearch.scope = "global";
    };

    environment.etc."sharkey.yml".source = configFile;

    systemd.services.sharkey = {
      after =
        [ "network-online.target" ]
        ++ lib.optionals createDB [ "postgresql.service" ]
        ++ lib.optionals createRedis [ "redis-sharkey.service" ]
        ++ lib.optionals createMeili [ "meilisearch.service" ];
      wantedBy = [ "multi-user.target" ];

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
        Restart = "always";

        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "sharkey";

        LoadCredential = [
          "database_password:${cfg.database.passwordFile}"
          "redis_password:${cfg.redis.passwordFile}"
          "meilisearch_key:${cfg.meilisearch.apiKeyFile}"
        ];
      };

      preStart = ''
        install -m 700 ${configFile} $MISSKEY_CONFIG_YML
        ${lib.getExe pkgs.replace-secret} '@DATABASE_PASSWORD@' "$CREDENTIALS_DIRECTORY/database_password" $MISSKEY_CONFIG_YML
        ${lib.getExe pkgs.replace-secret} '@REDIS_PASSWORD@' "$CREDENTIALS_DIRECTORY/redis_password" $MISSKEY_CONFIG_YML
        ${lib.getExe pkgs.replace-secret} '@MEILISEARCH_KEY@' "$CREDENTIALS_DIRECTORY/meilisearch_key" $MISSKEY_CONFIG_YML
      '';
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
      ensureDatabases = [ cfg.database.name ];
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

    services.meilisearch = lib.mkIf createMeili {
      enable = true;
      listenAddress = "127.0.0.1";
      listenPort = cfg.meilisearch.port;
      environment = "production";
    };

    users.users.sharkey = {
      group = "sharkey";
      isSystemUser = true;
      home = "/run/sharkey";
      packages = [ cfg.package ];
    };

    users.groups.sharkey = { };
  };
  meta.maintainers = with lib.maintainers; [ sodiboo ];
}
