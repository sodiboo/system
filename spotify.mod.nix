{secrets, ...}: {
  personal.home_modules = [
    ({
      pkgs,
      lib,
      ...
    }: {
      services.spotifyd.enable = true;
      services.spotifyd.settings.global = {
        username = secrets.spotify-username;
        password = secrets.spotify-password;
      };

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
