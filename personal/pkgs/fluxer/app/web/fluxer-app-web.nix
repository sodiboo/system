{
  lib,
  callPackage,

  compressDrvWeb,
  brotli,
  zopfli,

  make-fluxer-app ? callPackage ../fluxer-app.nix { },
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-app;

  extendDrvArgs = finalAttrs: args: {
    fluxer-component = "fluxer-app-web-${finalAttrs.build-channel}";
    fluxer-ci = null;

    buildPhase = ''
      (
        cd fluxer_app

        pnpm build
      )
    '';

    installPhase = ''
      cp -r fluxer_app/dist $out
    '';

    passthru = {
      compressed = compressDrvWeb finalAttrs.finalPackage {
        extraFormats = [
          "mjs"
          "wasm"
        ];

        compressors = {
          br = "${lib.getExe brotli} --keep --no-copy-stat {}";
          gz = "${lib.getExe zopfli} --keep {}";
        };
      };
    }
    // args.passthru or { };
  };

}
