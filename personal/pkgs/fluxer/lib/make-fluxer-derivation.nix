{
  lib,
  stdenv,
  runCommand,
  rustPlatform,
  ...
}:
lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;
  excludeDrvArgNames = [
    "custom-deps"
    "update-script"
    "extraCargoDeps"
    "cargoHash"
    "fluxer-ci"
  ];
  extendDrvArgs =
    finalAttrs:
    args@{
      fluxer-component,
      version,
      build-channel ? null,
      src,

      cargoHash ? builtins.throw "missing cargoHash argument",
      cargoDeps ?
        if cargoHash == null then
          null
        else
          rustPlatform.fetchCargoVendor (
            {
              name = "fluxer";
              inherit src;
              hash = cargoHash;
            }
            // lib.optionalAttrs (finalAttrs ? cargoRoot) {
              name = finalAttrs.pname;
              inherit (finalAttrs) cargoRoot;
            }
          ),
      custom-deps ? [ ],

      update-script,
      ...
    }:
    let
      inherit (finalAttrs) fluxer-ci;
    in
    {
      __structuredAttrs = true;
      strictDeps = true;

      pname = args.pname or fluxer-component;
      name =
        args.name or (
          let
            inherit (finalAttrs) pname version;
          in
          if (version != null) then "${pname}-${version}" else "${pname}"
        );

      inherit
        build-channel
        cargoDeps
        custom-deps
        ;

      fluxer-ci = builtins.addErrorContext "in ${finalAttrs.name}" args.fluxer-ci;

      postPatch = ''
        ${lib.optionalString (fluxer-ci != null) ''
          patchShebangs --build tools/ci/run.sh
        ''}
        ${args.postPatch or ""}
      '';

      env =
        let
          inherit (finalAttrs) version build-channel;
        in
        lib.optionalAttrs (version != null) {
          VERSION = version;
          BUILD_VERSION = version;
          PUBLIC_BUILD_VERSION = version;
        }
        // lib.optionalAttrs (build-channel != null) {
          CHANNEL = build-channel;
          BUILD_CHANNEL = build-channel;
          RELEASE_CHANNEL = build-channel;
          PUBLIC_RELEASE_CHANNEL = build-channel;
        }
        // lib.optionalAttrs (fluxer-ci != null) { FLUXER_CI_BIN = lib.getExe fluxer-ci; }
        // args.env or { };

      nativeBuildInputs =
        lib.optionals (fluxer-ci != null) [ fluxer-ci ] ++ args.nativeBuildInputs or [ ];

      passthru = {
        inherit (finalAttrs) fluxer-ci;
        updateScript = update-script;
        custom-deps-attrs = builtins.foldl' (
          ret: drv:
          if ret ? "custom-dep-${drv.name}" then
            lib.throw "make-fluxer-derivation: custom dep named ${drv.name} appears twice"
          else
            ret
            // {
              "custom-dep-${drv.name}" = drv;
            }
        ) { } finalAttrs.custom-deps;
      }
      // args.passthru or { };
    };

  transformDrv = drv: drv // drv.custom-deps-attrs;
}
