{
  lib,
  callPackage,
}:
lib.extendMkDerivation {
  constructDrv = callPackage ./fluxer-app.nix { };

  extendDrvArgs =
    finalAttrs:
    args@{ ... }:
    {
      fluxer-component = "fluxer-app-desktop-${finalAttrs.build-channel}";

      patches = [
        ../fluxer-ci-binary-in-desktop-build-js.patch
      ]
      ++ args.patches or [ ];

      postConfigure = ''
        (
          cd fluxer_desktop

          fluxer-ci build-desktop --step update_version
          fluxer-ci build-desktop --step set_build_channel
        )
      '';

      buildPhase = ''
        (
          cd fluxer_desktop
          
          fluxer-ci build-desktop --step build_shared_assets
        )
      '';

      installPhase = ''
        cp -r fluxer_desktop/dist/renderer $out
      '';
    };

}
