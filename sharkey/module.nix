{
  options,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  cfg = config.services.sharkey;

  settingsFormat = pkgs.formats.yaml { };

  credentials' = lib.imap0 (i: env: {
    identifier = "sharkey-cred-${toString i}";
    inherit env;
    path = cfg.credentials.${env};
  }) (builtins.attrNames cfg.credentials);

  scrub-secrets =
    loc: this:
    (
      if builtins.typeOf this == "set" then
        if builtins.attrNames this == [ "file" ] then
          {
            leaf = "secret";
            value = "";
            secret =
              if lib.types.path.check this.file then
                this.file
              else
                # we lose definition file information here. but fuck it we ball. half decent error still :3
                throw ''
                  The value for the option `${
                    lib.showOption (loc ++ [ "file" ])
                  }` is not of type `${lib.types.path.description}`. Value: ${
                    lib.generators.toPretty { } (
                      lib.generators.withRecursion {
                        depthLimit = 10;
                        throwOnDepthLimit = false;
                      } this.file
                    )
                  }
                '';
          }
        else
          let
            scrubbed = builtins.mapAttrs (k: scrub-secrets (loc ++ [ k ])) this;
            except-leaves = kind: lib.filterAttrs (_: v: v.leaf or null != kind);

            except-empty = lib.filterAttrs (_: v: v != { } && v != [ ]);
          in
          {
            value = lib.pipe scrubbed [
              (except-leaves "secret")
              (builtins.mapAttrs (_: v: v.value))
            ];

            secret = lib.pipe scrubbed [
              (except-leaves "value")
              (builtins.mapAttrs (_: v: v.secret))
              except-empty
            ];
          }

      else if lib.typeOf this == "list" then
        let
          scrubbed = lib.imap0 (i: v: scrub-secrets (loc ++ [ "[index ${toString i}]" ]) v) this;
        in
        {
          # do not eagerly prune lists: this will fuck with all the other indices.
          value = builtins.map (builtins.getAttr "value") scrubbed;
          secret = builtins.map (builtins.getAttr "secret") scrubbed;
        }
      else
        {
          leaf = "value";
          value = this;
          secret = { };
        }
    );

  scrubbed-settings = scrub-secrets (options.services.sharkey.settings.loc) cfg.settings;

  configFile = settingsFormat.generate "sharkey-config.yml" scrubbed-settings.value;

  make-credentials =
    loc: this:
    if builtins.typeOf this == "set" then
      lib.mapAttrsToList (name: make-credentials (loc ++ [ (lib.strings.toUpper name) ])) this
    else if builtins.typeOf this == "list" then
      lib.imap0 (i: make-credentials (loc ++ [ (toString i) ])) this
    else
      {
        name = "MK_CONFIG_${builtins.concatStringsSep "_" loc}_FILE";
        value = lib.mkDefinition {
          file = lib.unknownModule;
          value = this;
        };
      };

  extracted-credentials = builtins.listToAttrs (
    lib.flatten (make-credentials [ ] scrubbed-settings.secret)
  );

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

      database.createLocally = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Create the PostgreSQL database locally and configure Sharkey to use it.
        '';
      };

      redis.createLocally = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Create the Redis server locally and configure Sharkey to use it.
        '';
      };

      meilisearch.createLocally = lib.mkOption {
        type = lib.types.bool;
        default = false;
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

      scrubbed-settings = lib.mkOption {
        default = scrubbed-settings;
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
      (lib.mkIf (cfg.meilisearch.createLocally && config.services.meilisearch.masterKeyFile != null) {
        meilisearch.apiKey = lib.mkDefault { file = config.services.meilisearch.masterKeyFile; };
      })
    ];

    services.sharkey.credentials = extracted-credentials;

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
