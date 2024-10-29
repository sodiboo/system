{
  personal.modules = [
    ({config, ...}: {
      # mDNS
      networking.firewall.allowedUDPPorts = [5353];
      networking.firewall.allowedTCPPorts = [config.home-manager.users.sodiboo.services.spotifyd.settings.global.zeroconf_port];
    })
  ];
  personal.home_modules = [
    # Spotify has started to block direct login, such that providing username+password to spotifyd causes a forced password reset.
    # This honestly doesn't affect me that much because i can use zeroconf mode, and this still works fine. That's fine on sodium.
    # However, on nitrogen, i would love to use username+password. This is because it is frequently on a public network,
    # where devices are blocked from communicating. In practice, that doesn't matter for my personal use, because i rarely use audio on nitrogen,
    # and i can always listen to Spotify on my phone. So i can just keep nitrogen muted, lol.
    #
    # Nonetheless, before Spotify became hostile to that approach, this was my configuration below.
    # I'm overriding ExecStart because to my knowledge i cannot use `username_cmd` from the config file.
    # And i'd rather not make my spotify username public; it was created when i was a child and it's cringe. I wish i could change it.

    # ({
    #   nixosConfig,
    #   config,
    #   pkgs,
    #   lib,
    #   ...
    # }: let
    #   cfg = config.services.spotifyd;
    #   tomlFormat = pkgs.formats.toml {};
    #   configFile = tomlFormat.generate "spotifyd.conf" cfg.settings;
    # in {
    #   systemd.user.services.spotifyd.Service.ExecStart = lib.mkForce "${lib.getExe cfg.package} ${lib.escapeShellArgs [
    #     "--no-daemon"
    #     "--username-cmd"
    #     "cat ${nixosConfig.sops.secrets."spotify/username".path}"
    #     "--password-cmd"
    #     "cat ${nixosConfig.sops.secrets."spotify/password".path}"
    #     "--config-path"
    #     configFile
    #   ]}";
    # })
    ({
      nixosConfig,
      pkgs,
      ...
    }: {
      services.spotifyd = {
        enable = true;

        settings.global.device_name = nixosConfig.networking.hostName;
        settings.global.zeroconf_port = 7878;
      };

      home.packages = with pkgs; [
        spotify-player
        sptlrx
      ];

      programs.fish.shellAliases.sptlrx = "sptlrx --before faint";
    })
  ];
}
