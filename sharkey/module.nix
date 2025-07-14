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

  credentials' = lib.imap0 (i: env: {
    identifier = "sharkey-cred-${toString i}";
    inherit env;
    path = cfg.credentials.${env};
  }) (builtins.attrNames cfg.credentials);
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

      credentials = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = { };
        description = ''
          Credentials to be used by Sharkey, such as database passwords or API keys.
          The key should be the environment variable `MK_CONFIG_*_FILE` that matches the relevant Sharkey config option.
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
      (
        let
          badly-named-credentials = builtins.filter (env: builtins.match "^MK_CONFIG_.*_FILE$" env == null) (
            builtins.attrNames cfg.credentials
          );
        in
        {
          assertion = badly-named-credentials == [ ];
          message = ''
            services.sharkey.credentials contains invalid environment variables: ${builtins.concatStringsSep ", " badly-named-credentials}
            They should all be of the form MK_CONFIG_*_FILE.
          '';
        }
      )
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
    ];

    services.sharkey.credentials = {
      MK_CONFIG_DB_PASS_FILE = lib.mkIf (cfg.database.passwordFile != null) cfg.database.passwordFile;
      MK_CONFIG_REDIS_PASS_FILE = lib.mkIf (cfg.redis.passwordFile != null) cfg.redis.passwordFile;
      MK_CONFIG_MEILISEARCH_APIKEY_FILE = lib.mkIf (
        cfg.meilisearch.apiKeyFile != null
      ) cfg.meilisearch.apiKeyFile;
    };

    environment.etc."sharkey.yml".source = configFile;

    systemd.services.sharkey = {
      after =
        [ "network-online.target" ]
        ++ lib.optionals cfg.database.createLocally [ "postgresql.service" ]
        ++ lib.optionals cfg.redis.createLocally [ "redis-sharkey.service" ]
        ++ lib.optionals cfg.meilisearch.createLocally [ "meilisearch.service" ];
      wantedBy = [ "multi-user.target" ];

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

        LoadCredential = map (cred: "${cred.identifier}:${cred.path}") credentials';
      };

      environment = lib.mkMerge (
        [ { MISSKEY_CONFIG_YML = "${configFile}"; } ]
        ++ map (cred: {
          ${cred.env} = "%d/${cred.identifier}";
        }) credentials'
      );
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
