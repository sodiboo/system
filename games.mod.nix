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
      programs.steam.package = let
        x-wrapped = steam:
          pkgs.runCommand "x-run-steam" {
            inherit (steam) passthru meta;
          } ''
            cp -r ${steam} $out

            # $out/share is a symlink to ${steam}/share
            # but since we need to edit its internals, we need to expand it to a real directory
            # that can be edited

            # first we need to make sure we can remove it
            chmod -R +w $out

            # then remove, recreate, and populate it
            rm $out/share
            mkdir $out/share
            cp -r ${steam}/share/* $out/share/

            # and of course, make sure we can edit the desktop file again
            chmod -R +w $out

            sed -i 's/Exec=steam/Exec=x-run steam/g' $out/share/applications/steam.desktop
          '';
      in
        x-wrapped pkgs.steam
        // {
          override = f: x-wrapped (pkgs.steam.override f);
        };
    })
  ];

  personal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        # simutrans # borked
        prismlauncher
        ringracers
        lutris
        adwaita-icon-theme
        itch
      ];
    })
  ];
}
