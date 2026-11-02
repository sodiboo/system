{
  lib,
  callPackage,
  makeWrapper,

  make-fluxer-derivation,

  make-fluxer-app-proxy ? callPackage ./fluxer-app-proxy.nix { },
  make-fluxer-app-web ? callPackage ./fluxer-app-web.nix { },
}:
let
  web-app-args = [
    "pnpmHash"
    "pnpmDeps"
    "libfluxcore"
    "libfluxwebp"
  ];
in
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  excludeDrvArgNames = web-app-args;

  extendDrvArgs = finalAttrs: args: {
    fluxer-ci = null;

    unwrapped = make-fluxer-app-proxy { inherit (finalAttrs) version src cargoDeps; };

    custom-deps = [
      finalAttrs.dist.pnpmDeps
      finalAttrs.dist.libfluxcore.cargoDeps.vendorStaging
      finalAttrs.dist.libfluxwebp.cargoDeps.vendorStaging
    ];

    inherit (finalAttrs.unwrapped) fluxer-component;
    pname = "${finalAttrs.fluxer-component}-wrapper";

    build-channel = "stable";

    dist = make-fluxer-app-web (
      {
        inherit (finalAttrs) version src cargoDeps;
      }
      // lib.filterAttrs (name: _: lib.elem name web-app-args) args
    );

    nativeBuildInputs = [
      makeWrapper
    ];

    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${lib.getExe finalAttrs.unwrapped} $out/bin/fluxer-app-proxy \
        --set-default FLUXER_STATIC_DIR ${finalAttrs.dist.compressed} \
        --set-default RELEASE_CHANNEL ${lib.escapeShellArg finalAttrs.build-channel}
    '';

    inherit (finalAttrs.unwrapped) meta;
  };
}
