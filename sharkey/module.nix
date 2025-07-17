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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          (
            let
              package-is-very-likely-unmodified =
                cfg.package.src.gitRepoUrl or null == "https://activitypub.software/TransFem-org/Sharkey.git"
                && cfg.package.patches or [ ] == [ ];

              has-git-repo-url = cfg.package.src.gitRepoUrl or null != null;
              has-patches = cfg.package.patches or [ ] != [ ];

              user-probably-knows-what-they're-doing = cfg.settings ? publishTarballInsteadOfProvideRepositoryUrl;
            in
            {
              assertion = package-is-very-likely-unmodified || user-probably-knows-what-they're-doing;

              message =
                ''
                  The Sharkey setting `publishTarballInsteadOfProvideRepositoryUrl` must be explicitly set.
                  Please read its documentation to avoid violating the AGPLv3 license that Sharkey is distributed under.
                  https://activitypub.software/TransFem-org/Sharkey/-/blob/05a499ac55f13d654453eb3419ddae2c8eab1a34/.config/example.yml#L5-60
                ''
                + lib.optionalString (has-git-repo-url && !has-patches) ''
                  note: you probably need to ensure the repository in the settings is ${cfg.package.src.gitRepoUrl}
                '';
            }
          )
        ];
      }
      {
        users.users.sharkey = {
          group = "sharkey";
          isSystemUser = true;
          home = "/run/sharkey";
          packages = [ cfg.package ];
        };
        users.groups.sharkey = { };

        services.sharkey.settings.mediaDirectory = lib.mkForce "/var/lib/sharkey";

        systemd.services.sharkey = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          environment.MISSKEY_CONFIG_YML = "${configFile}";
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
          };
        };
      }
      {

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

        services.sharkey.credentials = extracted-credentials;
      }
      (
        let
          credentials' = lib.imap0 (i: env: {
            identifier = "sharkey-cred-${toString i}";
            inherit env;
            path = cfg.credentials.${env};
          }) (builtins.attrNames cfg.credentials);
        in
        {
          systemd.services.sharkey = {
            serviceConfig.LoadCredential = map (cred: "${cred.identifier}:${cred.path}") credentials';
            environment = lib.mkMerge (map (cred: { ${cred.env} = "%d/${cred.identifier}"; }) credentials');
          };
        }
      )
      (lib.mkIf cfg.database.createLocally {
        systemd.services.sharkey.after = [ "postgresql.service" ];
        services.postgresql = {
          enable = true;
          ensureDatabases = [ "sharkey" ];
          ensureUsers = [
            {
              name = "sharkey";
              ensureDBOwnership = true;
            }
          ];
        };
        services.sharkey.settings = {
          db.host = lib.mkDefault "/run/postgresql";
          db.port = lib.mkDefault config.services.postgresql.settings.port;
        };
      })
      (lib.mkIf cfg.redis.createLocally {
        services.redis.servers.sharkey.enable = true;
        systemd.services.sharkey = {
          after = [ "redis-sharkey.service" ];
          serviceConfig.SupplementaryGroups = [ config.services.redis.servers.sharkey.group ];
        };
        services.sharkey.settings = {
          redis.path = lib.mkDefault config.services.redis.servers.sharkey.unixSocket;
        };
      })
      (lib.mkIf cfg.meilisearch.createLocally {
        systemd.services.sharkey.after = [ "meilisearch.service" ];
        services.meilisearch = {
          enable = true;
          environment = "production";
        };
        services.sharkey.settings = {
          fulltextSearch.provider = lib.mkDefault "meilisearch";
          meilisearch.host = lib.mkDefault "localhost";
          meilisearch.port = lib.mkDefault config.services.meilisearch.listenPort;
          meilisearch.index = lib.mkDefault "sharkey";
          meilisearch.apiKey = lib.mkIf (config.services.meilisearch.masterKeyFile != null) (
            lib.mkDefault {
              file = config.services.meilisearch.masterKeyFile;
            }
          );
        };
      })
    ]
  );
  meta.maintainers = with lib.maintainers; [ sodiboo ];
}
