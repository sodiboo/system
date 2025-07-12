{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  cfg = config.services.sharkey;

  settingsFormat = pkgs.formats.yaml { };
  configFile = settingsFormat.generate "sharkey-config.yml" cfg.settings;
in
{
  disabledModules = [ "${modulesPath}/services/web-apps/sharkey.nix" ];

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
          description = ''
            Create the Redis server locally and configure Sharkey to use it.
          '';
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
      {
        assertion = cfg.redis.createLocally -> cfg.redis.passwordFile == null;
        message = "services.sharkey.redis.createLocally should not be used with a passwordFile.";
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
      (lib.mkIf cfg.redis.createLocally {
        redis.path = lib.mkDefault config.services.redis.servers.sharkey.unixSocket;
      })
      (lib.mkIf cfg.meilisearch.createLocally {
        fulltextSearch.provider = lib.mkDefault "meilisearch";
        meilisearch.host = lib.mkDefault "localhost";
        meilisearch.port = lib.mkDefault config.services.meilisearch.listenPort;
        meilisearch.index = lib.mkDefault (lib.replaceStrings [ "." ] [ "_" ] cfg.domain);
      })
      (lib.mkIf (cfg.database.passwordFile != null) { db.pass = "@DATABASE_PASSWORD@"; })
      (lib.mkIf (cfg.redis.passwordFile != null) { redis.pass = "@REDIS_PASSWORD@"; })
      (lib.mkIf (cfg.meilisearch.apiKeyFile != null) { meilisearch.apiKey = "@MEILISEARCH_KEY@"; })
    ];

    environment.etc."sharkey.yml".source = configFile;

    systemd.services.sharkey = {
      after =
        [ "network-online.target" ]
        ++ lib.optionals cfg.database.createLocally [ "postgresql.service" ]
        ++ lib.optionals cfg.redis.createLocally [ "redis-sharkey.service" ]
        ++ lib.optionals cfg.meilisearch.createLocally [ "meilisearch.service" ];
      wantedBy = [ "multi-user.target" ];

      environment.MISSKEY_CONFIG_YML = "/run/sharkey/config.yml";

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

    services.redis = lib.mkIf cfg.redis.createLocally {
      servers.sharkey = {
        enable = true;
        user = "sharkey";
        unixSocketPerm = 600;
      };
    };

    services.meilisearch = lib.mkIf cfg.meilisearch.createLocally {
      enable = true;
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
