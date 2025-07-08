{
  personal =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      options.wallpaper = lib.mkOption { readOnly = true; };

      config.wallpaper = {
        base = pkgs.fetchurl {
          name = "wallpaper.png";
          url = "https://w.wallhaven.cc/full/o3/wallhaven-o3r9p7.png";
          hash = "sha256-IN1+5sIyuSOEilxsq/v5gxsSdCYCT3ZGrp0IzY64ICo=";
        };

        modulated = pkgs.runCommand "modulated-wallpaper.png" { } ''
          ${config.scripts.modulate} ${config.wallpaper.base} $out
        '';

        blurred = pkgs.runCommand "blurred-wallpaper.png" { } ''
          ${config.scripts.blur} ${config.wallpaper.base} $out
        '';

        blurred-and-modulated = pkgs.runCommand "blurred-and-modulated-wallpaper.png" { } ''
          ${config.scripts.blur} ${config.wallpaper.modulated} $out
        '';
      };

      config.home-shortcut = {
        home.file = lib.mapAttrs' (name: source: {

          name = ".wallpaper/${name}.png";
          value.source = source;
        }) config.wallpaper;
      };
    };
}
