{stylix, ...}: let
  wallpapers = builtins.mapAttrs (name: value: {pkgs, ...}: {stylix.image = pkgs.fetchurl value;}) {
    planets.url = "https://w.wallhaven.cc/full/z8/wallhaven-z8qe8g.jpg";
    planets.sha256 = "sha256-+7avaRAffJj781tXMGk5WiM2DDUi6l9idCIbzIYhkC4=";

    stabby.url = "https://w.wallhaven.cc/full/rr/wallhaven-rroo6m.png";
    stabby.sha256 = "sha256-SREdgxHXpNOs2rxoP23ohf/l41z7LP1LqhKoX5EQlIQ=";

    firewatch.url = "https://w.wallhaven.cc/full/kx/wallhaven-kxj3l1.jpg";
    firewatch.sha256 = "sha256-qNrWmpKvMoPVzHsQb6t87PN6ftja96hrBszXrB4GTAA=";
  };
in {
  shared.modules = [
    stylix.nixosModules.stylix
    ({
      pkgs,
      config,
      ...
    }: {
      stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/google-dark.yaml";
      stylix.polarity = "dark";

      stylix.fonts.monospace.package = pkgs.nerdfonts;
      stylix.fonts.monospace.name = "FiraCode Nerd Font";

      stylix.fonts.sansSerif.package = pkgs.nerdfonts;
      stylix.fonts.sansSerif.name = "Ubuntu Nerd Font";
      stylix.fonts.serif = config.stylix.fonts.sansSerif;

      stylix.fonts.sizes.applications = 10;
      stylix.fonts.sizes.desktop = 12;

      stylix.cursor.package = pkgs.phinger-cursors;
      stylix.cursor.name = "phinger-cursors";

      stylix.opacity.terminal = 0.9;

      # stylix.targets.fish.enable = false;
    })
  ];

  sodium.modules = [
    wallpapers.stabby
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
  ];
}
