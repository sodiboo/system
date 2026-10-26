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

      fluxer-ci =
        args.fluxer-ci or (
          if finalAttrs ? cargoRoot then
            null
          else
            rustPlatform.buildRustPackage {
              name = "fluxer-ci";
              inherit (finalAttrs) src cargoDeps;
              buildAndTestSubdir = "tools/ci";

              meta.mainProgram = "fluxer-ci";

              # using debug mode cuts down the build time of this utility from 3min to 1min on my machine.
              # that's significant, as *everything else fluxer* blocks on this.
              # overall, this saves about 25%-33% *total build time* for fluxer-desktop.
              buildType = "debug";
            }
        );

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
