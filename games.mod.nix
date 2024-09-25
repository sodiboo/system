{
  personal.modules = [
    ({pkgs, ...}: {
      programs.steam = {
        enable = true;
        # extest.enable = true;
        extraPackages = with pkgs; [
          sodi-x-run
          gamescope
          xwayland-run
        ];
        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };
      programs.steam.package = pkgs.steam.overrideAttrs (attrs: {
        buildCommand = ''
          ${attrs.buildCommand or ""}
          sed -i 's/Exec=steam/Exec=x-run steam/g' $out/share/applications/steam.desktop
        '';
      });
    })
  ];

  personal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        simutrans
        prismlauncher
        lutris
        adwaita-icon-theme
        itch
      ];
    })
  ];
}
