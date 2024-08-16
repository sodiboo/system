{stylix, ...}: let
  wallpapers =
    builtins.mapAttrs (name: value: {
      lib,
      pkgs,
      ...
    }: {
      stylix.image = pkgs.fetchurl {
        url = value.url;
        hash = value.hash or lib.fakeHash;
      };
    }) {
      planets.url = "https://w.wallhaven.cc/full/z8/wallhaven-z8qe8g.jpg";
      planets.hash = "sha256-+7avaRAffJj781tXMGk5WiM2DDUi6l9idCIbzIYhkC4=";

      ponies.url = "https://static1.e621.net/data/9d/90/9d90737d30897860ea6ec4de266a82ca.png";
      ponies.hash = "sha256-MEAmM++DE1FYs1w9KV+ISdEbSYaUfT8rR8T1a9pcbos=";

      hex-lines.url = "https://w.wallhaven.cc/full/gj/wallhaven-gjkxke.png";
      hex-lines.hash = "sha256-qrTyeb54cfEuQIu4YDYilu9dydlFEAfgyMvMcdymtWw=";

      firewatch-celshade.url = "https://w.wallhaven.cc/full/kx/wallhaven-kxj3l1.jpg";
      firewatch-celshade.hash = "sha256-qNrWmpKvMoPVzHsQb6t87PN6ftja96hrBszXrB4GTAA=";

      firewatch.url = "https://w.wallhaven.cc/full/x1/wallhaven-x1oe3d.jpg";
      firewatch.hash = "sha256-qRRhJvbk09TATc3wShMwrr1Z9A020SWYRykzarvPLYQ=";

      firewatch-wide.url = "https://w.wallhaven.cc/full/o3/wallhaven-o3r9p7.png";
      firewatch-wide.hash = "sha256-IN1+5sIyuSOEilxsq/v5gxsSdCYCT3ZGrp0IzY64ICo=";

      triangles.url = "https://w.wallhaven.cc/full/0w/wallhaven-0werjp.jpg";
      triangles.hash = "sha256-+ioD+OBpZg0HDrUGDWlDKJbjHHEVK2u92suXf72kRI0=";

      hax.url = "https://w.wallhaven.cc/full/q2/wallhaven-q25ler.png";
      hax.hash = "sha256-/ujHJLieuEXZUnOn981v/d1WynUi11cApgkEf8kln2E=";
    };
in {
  personal.modules = [
    stylix.nixosModules.stylix
    ({
      pkgs,
      config,
      ...
    }: {
      stylix.enable = true;

      stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/atelier-dune.yaml";
      stylix.polarity = "dark";

      stylix.fonts.monospace.package = pkgs.nerdfonts;
      stylix.fonts.monospace.name = "FiraCode Nerd Font";

      stylix.fonts.sansSerif.package = pkgs.nerdfonts;
      stylix.fonts.sansSerif.name = "Ubuntu Nerd Font";
      stylix.fonts.serif = config.stylix.fonts.sansSerif;

      stylix.fonts.sizes.applications = 10;
      stylix.fonts.sizes.desktop = 12;

      stylix.cursor.package = pkgs.phinger-cursors;
      stylix.cursor.name = "phinger-cursors-dark";
      stylix.cursor.size = 24;

      stylix.opacity.terminal = 0.9;

      # stylix.targets.fish.enable = false;
    })
  ];

  sodium.modules = [
    wallpapers.firewatch-wide
  ];

  nitrogen.modules = [
    wallpapers.firewatch-wide
  ];

  personal.home_modules = [
    {
      # stylix.targets.gtk.enable = false;
      # stylix.targets.firefox.enable = false;
      stylix.targets.vscode.enable = false;
    }
    ({
      lib,
      pkgs,
      config,
      ...
    }: {
      systemd-fuckery.auto-restart = ["swaybg"];
      systemd-fuckery.start-with-niri = ["swaybg"];
      systemd.user.services."swaybg" = {
        Unit = {
          Description = "wallpapers! brought to you by stylix! :3";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
          Requisite = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${config.stylix.image}";
          Restart = "on-failure";
        };
      };
    })
  ];
}
