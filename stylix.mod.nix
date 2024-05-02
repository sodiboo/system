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

      hex-lines.url = "https://w.wallhaven.cc/full/gj/wallhaven-gjkxke.png";
      hex-lines.hash = "sha256-qrTyeb54cfEuQIu4YDYilu9dydlFEAfgyMvMcdymtWw=";

      firewatch.url = "https://w.wallhaven.cc/full/kx/wallhaven-kxj3l1.jpg";
      firewatch.hash = "sha256-qNrWmpKvMoPVzHsQb6t87PN6ftja96hrBszXrB4GTAA=";
    };
in {
  shared.modules = [
    stylix.nixosModules.stylix
    ({
      pkgs,
      config,
      ...
    }: {
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
    wallpapers.hex-lines
  ];

  lithium.modules = [
    wallpapers.firewatch
  ];

  shared.home_modules = [
    {
      # stylix.targets.gtk.enable = false;
      # stylix.targets.firefox.enable = false;
      stylix.targets.vscode.enable = false;
    }
    ({
      pkgs,
      config,
      ...
    }: {
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
