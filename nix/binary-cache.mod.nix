{ systems, ... }:
{
  universal =
    {
      config,
      lib,
      ...
    }:
    {
      options.personal-binary-cache-url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "https://cache.sodi.boo";
      };

      config = lib.mkIf (config.personal-binary-cache-url != null) {
        nix.settings = {
          substituters = [ config.personal-binary-cache-url ];
          trusted-public-keys = [ "sodiboo/system:N1cJgHSRSRKvlItFJDjXQBCgAhRo7hvTNw8TqyrhCUw=" ];
        };
      };
    };

  oxygen.reverse-proxy."cache.sodi.boo".locations."/".vpn.iridium.port =
    systems.iridium.services.nix-serve.port;

  oxygen.caddy.sites."cache.sodi.boo".routes = [
    {
      terminal = true;
      handle = [
        {
          handler = "reverse_proxy";
          upstreams = [
            { dial = "${systems.iridium.vpn.hostname}:${toString systems.iridium.services.nix-serve.port}"; }
          ];
        }
      ];
    }
  ];

  iridium =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      sops.secrets.binary-cache-secret = { };

      # This is publicly served from https://cache.sodi.boo
      # That's proxied through oxygen from nginx.
      services.nix-serve = {
        enable = true;
        port = 5020;
        openFirewall = true;
        secretKeyFile = config.sops.secrets.binary-cache-secret.path;
      };

      systemd.timers."auto-update-rebuild" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitInactiveSec = "1h";
          Unit = "auto-update-rebuild.service";
        };
      };

      systemd.services."auto-update-rebuild" = {
        script = ''
          mkdir -p /tmp/auto-update-rebuild && cd /tmp/auto-update-rebuild

          export PATH=${
            lib.makeBinPath (
              with pkgs;
              [
                nix
                git
                coreutils
              ]
            )
          }

          nix build github:sodiboo/system#all-systems --recreate-lock-file --no-write-lock-file
        '';

        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "15m";
          Type = "oneshot";
        };
      };

      # Don't use iridium as a substitute for itself. That would be silly.
      personal-binary-cache-url = null;
    };

  # sodium and iridium are on the same network, so let's not go through a hop to germany.
  sodium.personal-binary-cache-url = "http://iridium.lan:${toString systems.iridium.services.nix-serve.port}";
}
