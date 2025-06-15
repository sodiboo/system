{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.sharkey;

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
          description = ''
            Create the PostgreSQL database locally and configure Sharkey to use it.
          '';
        };

        passwordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
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
          type = lib.types.nullOr lib.types.path;
          default = null;
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
          type = lib.types.nullOr lib.types.path;
          default = null;
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
    assertions = [
      {
        assertion = cfg.database.createLocally -> cfg.database.passwordFile == null;
        message = "services.sharkey.database.createLocally should not be used with a passwordFile.";
      }
    ];

    services.sharkey.settings = lib.mkMerge [
      {
        url = lib.mkDefault "https://${cfg.domain}/";
      }
      (lib.mkIf cfg.database.createLocally {
        db.host = lib.mkDefault "/var/run/postgresql";
        db.port = lib.mkDefault config.services.postgresql.settings.port;
      })
      {
        redis.host = cfg.redis.host;
        redis.port = cfg.redis.port;
        meilisearch.host = cfg.meilisearch.host;
        meilisearch.port = cfg.meilisearch.port;
        meilisearch.index = cfg.meilisearch.index;
        meilisearch.ssl = !createMeili;
        meilisearch.scope = "global";
      }
      (lib.mkIf (cfg.database.passwordFile != null) { db.pass = "@DATABASE_PASSWORD@"; })
      (lib.mkIf (cfg.redis.passwordFile != null) { redis.pass = "@REDIS_PASSWORD@"; })
      (lib.mkIf (cfg.meilisearch.apiKeyFile != null) { meilisearch.apiKey = "@MEILISEARCH_KEY@"; })
    ];

    environment.etc."sharkey.yml".source = configFile;

    systemd.services.sharkey = {
      after =
        [ "network-online.target" ]
        ++ lib.optionals cfg.database.createLocally [ "postgresql.service" ]
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

        LoadCredential = lib.mkMerge [
          (lib.mkIf (cfg.database.passwordFile != null) [ "database_password:${cfg.database.passwordFile}" ])
          (lib.mkIf (cfg.redis.passwordFile != null) [ "redis_password:${cfg.redis.passwordFile}" ])
          (lib.mkIf (cfg.meilisearch.apiKeyFile != null) [ "meilisearch_key:${cfg.meilisearch.apiKeyFile}" ])
        ];
      };

      preStart = lib.mkMerge [
        "install -m 700 ${configFile} $MISSKEY_CONFIG_YML"
        (lib.mkIf (cfg.database.passwordFile != null) ''
          ${lib.getExe pkgs.replace-secret} '@DATABASE_PASSWORD@' "$CREDENTIALS_DIRECTORY/database_password" $MISSKEY_CONFIG_YML
        '')
        (lib.mkIf (cfg.redis.passwordFile != null) ''
          ${lib.getExe pkgs.replace-secret} '@REDIS_PASSWORD@' "$CREDENTIALS_DIRECTORY/redis_password" $MISSKEY_CONFIG_YML
        '')
        (lib.mkIf (cfg.meilisearch.apiKeyFile != null) ''
          ${lib.getExe pkgs.replace-secret} '@MEILISEARCH_KEY@' "$CREDENTIALS_DIRECTORY/meilisearch_key" $MISSKEY_CONFIG_YML
        '')
      ];
    };

    services.postgresql = lib.mkIf cfg.database.createLocally {
      enable = true;
      ensureDatabases = [ "sharkey" ];
      ensureUsers = [
        {
          name = "sharkey";
          ensureDBOwnership = true;
        }
      ];
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
