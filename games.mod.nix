{
  personal.modules = [
    {
      nixpkgs.overlays = [
        (final: prev: {
          # You still have to override it in settings so ig this doesn't work?
          # But at least it prevents the wrong glfw from being discovered in that case.
          prismlauncher = prev.prismlauncher.override {glfw = final.glfw-wayland-minecraft;};
        })
      ];
    }
    ({pkgs, ...}: {
      programs.steam = {
        enable = true;
        extest.enable = true;
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
        gnome.adwaita-icon-theme
        # itch
      ];
    })
  ];
}
