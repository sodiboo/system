{
  personal =
    { lib, pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        # extest.enable = true;
        extraPackages = with pkgs; [
          sodi-x-run
          gamescope
          xwayland-run
        ];
        extraCompatPackages =
          let
            proton-ge-rtsp-bin = pkgs.proton-ge-bin.overrideAttrs rec {
              version = "GE-Proton9-22-rtsp17-1";
              src = pkgs.fetchzip {
                url = "https://github.com/SpookySkeletons/proton-ge-rtsp/releases/download/${version}/${version}.tar.gz";
                hash = "sha256-GeExWNW0J3Nfq5rcBGiG2BNEmBg0s6bavF68QqJfuX8=";
              };
            };
            proton-ge-rtsp-bin' = proton-ge-rtsp-bin.override { steamDisplayName = "GE-Proton-rtsp"; };
          in
          with pkgs;
          [
            proton-ge-bin
            proton-ge-rtsp-bin'
          ];
      };
      programs.steam.package =
        let
          x-wrapped =
            steam:
            pkgs.runCommand "x-run-steam"
              {
                inherit (steam) passthru meta;
              }
              ''
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

          patchedBwrap = pkgs.bubblewrap.overrideAttrs (o: {
            patches = (o.patches or [ ]) ++ [
              ./bwrap.patch
            ];
          });
          steam' = pkgs.steam.override {
            buildFHSEnv = (
              args:
              (
                (pkgs.buildFHSEnv.override {
                  bubblewrap = patchedBwrap;
                })
                (
                  args
                  // {
                    extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [ "--cap-add ALL" ];
                  }
                )
              )
            );
          };
        in
        x-wrapped steam'
        // {
          override = f: x-wrapped (pkgs.steam.override f);
        };

      home-shortcut = {
        home.packages = with pkgs; [
          simutrans
          prismlauncher
          ringracers
          lutris
          adwaita-icon-theme
          itch
        ];
      };
    };
}
