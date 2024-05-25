{
  personal.home_modules = [
    ({
      nixosConfig,
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
            "--username-cmd"
            "cat ${nixosConfig.sops.secrets."spotify/username".path}"
            "--password-cmd"
            "cat ${nixosConfig.sops.secrets."spotify/password".path}"
            "--config-path"
            configFile
          ]}";
          Restart = "always";
          RestartSec = 12;
        };
      };
    })
    ({
      nixosConfig,
      pkgs,
      ...
    }: {
      services.spotifyd = {
        enable = true;

        settings.global.device_name = nixosConfig.networking.hostName;
      };

      home.packages = with pkgs; [
        spotify-player
        sptlrx
      ];

      programs.fish.shellAliases.sptlrx = "sptlrx --before faint";
    })
  ];
}
