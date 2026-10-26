{
  lib,
  callPackage,

  make-fluxer-app ? callPackage ../fluxer-app.nix { },
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-app;

  extendDrvArgs =
    finalAttrs:
    args@{ ... }:
    {
      fluxer-component = "fluxer-app-desktop-${finalAttrs.build-channel}";

      patches = [
        ./patches/fluxer-ci-binary-in-desktop-build-js.patch
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
