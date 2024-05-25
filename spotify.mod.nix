{secrets, ...}: {
  personal.home_modules = [
    ({
      config,
      pkgs,
      lib,
      ...
    }: let
      cfg = config.services.spotifyd;
      tomlFormat = pkgs.formats.toml {};
      configFile = tomlFormat.generate "spotifyd.conf" cfg.settings;
    in {
      systemd.user.services.spotifyd = lib.mkForce {
        Unit = {
          Description = "spotify daemon";
          Documentation = "https://github.com/Spotifyd/spotifyd";
        };

        Install.WantedBy = ["default.target"];

        Service = {
          ExecStart = "${cfg.package}/bin/spotifyd ${lib.escapeShellArgs [
            "--no-daemon"
            "--username" secrets.spotify-username
            "--password" secrets.spotify-password
            "--config-path" configFile
          ]}";
          Restart = "always";
          RestartSec = 12;
        };
      };
    })
    ({
      pkgs,
      ...
    }: {
      services.spotifyd.enable = true;

      home.packages = with pkgs; [
        spotify-player
        sptlrx
      ];

      programs.fish.shellAliases.sptlrx = "sptlrx --before faint";
    })
  ];

  sodium.home_modules = [
    {
      services.spotifyd.settings.global.device_name = "sodi computer";
    }
  ];

  lithium.home_modules = [
    {
      services.spotifyd.settings.global.device_name = "sodi laptop";
    }
  ];
}
