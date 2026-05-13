{
  oxygen =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      caddy.sites."turning.computers.gay".routes = [
        {
          terminal = true;
          handle = [
            {
              handler = "subroute";
              routes = [
                {
                  handle = [
                    {
                      handler = "reverse_proxy";
                      upstreams = [ { dial = "unix/@forgejo"; } ];
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];

      # just the default robots.txt for forgejo, but through my stuff to also append ai.robots.txt
      caddy.sites."turning.computers.gay".robots-txt = builtins.readFile ./forgejo.robots.txt;

      # I disable this for my user, intentionally. But forgejo depends on this to actually update the list of authorized keys at runtime.
      services.openssh.extraConfig = ''
        match User forgejo
            AuthorizedKeysFile %h/.ssh/authorized_keys
      '';

      services.forgejo = {
        enable = true;
        database.type = "postgres";

        settings = {
          DEFAULT = {
            APP_NAME = "turning computers gay";
          };

          server = {
            PROTOCOL = "http+unix";
            HTTP_ADDR = "@forgejo";
            # START_SSH_SERVER = true;
            # SSH_PORT = 242;

            DOMAIN = "turning.computers.gay";
            ROOT_URL = "https://turning.computers.gay";
          };

          session = {
            PROVIDER = "file";
            PROVIDER_CONFIG = "${config.services.forgejo.stateDir}/data/sessions";
            COOKIE_NAME = "we_love_forgejo";
          };
          security = {
            COOKIE_REMEMBER_NAME = "forgejo_inspiring";
          };

          ui = {
            SHOW_USER_EMAIL = false;
          };
          service = {
            DISABLE_REGISTRATION = true;
            DEFAULT_KEEP_EMAIL_PRIVATE = true;
            LANDING_PAGE = "explore";
          };
          "service.explore" = {
            DISABLE_USERS_PAGE = true;
          };
          other = {
            SHOW_FOOTER_VERSION = false;
            SHOW_FOOTER_TEMPLATE_LOAD_TIME = false;
          };
          repository = {
            DEFAULT_REPO_UNITS = "repo.code,repo.issues,repo.pulls,repo.actions,repo.releases";
          };
          actions = {
            DEFAULT_ACTIONS_URL = "${config.services.forgejo.settings.server.ROOT_URL}";
          };
        };
      };

      home-shortcut.home.packages =
        let
          cfg = config.services.forgejo;
        in
        [
          (pkgs.writeShellScriptBin "forgejo" ''
            ${
              lib.escapeShellArgs [
                "sudo"
                "--user=forgejo"
                "env"
                "--chdir=${cfg.stateDir}"
                "FORGEJO_WORK_DIR=${cfg.stateDir}"
                "FORGEJO_CUSTOM_DIR=${cfg.customDir}"
                (lib.getExe config.services.forgejo.package)
              ]
            } "$@"
          '')
        ];

      sops.secrets."forgejo-actions-runner-token" = { };

      sops.templates.forgejo-actions-runner-env.content = ''
        TOKEN="${config.sops.placeholder.forgejo-actions-runner-token}"
      '';

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;

        defaultNetwork.settings.dns_enabled = true;
      };
      services.gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances.default = {
          enable = true;
          url = "${config.services.forgejo.settings.server.ROOT_URL}";
          tokenFile = config.sops.templates.forgejo-actions-runner-env.path;
          name = "runner";
          labels = [
            "nixos-unstable:docker://turning.computers.gay/actions/nixos:unstable"
            "nixos-stable:docker://turning.computers.gay/actions/nixos:stable"
            "nixos-25.11:docker://turning.computers.gay/actions/nixos:25.11"
          ];

          settings = {
            runner = {
              capacity = 4;
              timeout = "2h";
            };
            container.network = "host";
          };
        };
      };
    };
}
