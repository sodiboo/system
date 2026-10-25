{
  lib,
  stdenv,
  runCommand,
  rustPlatform,
  ...
}:
let
  merge-cargo-deps =
    root-dep: extra-dep-list:
    runCommand "merge-vendor-deps" { } ''
      mkdir -p $out

      cp -r --no-preserve=mode "${root-dep}/." "$out/"

      ${lib.join "\n" (
        lib.map (
          deps:
          ''cp -r --no-clobber --no-preserve=mode "${deps}/source-registry-0/." "$out/source-registry-0/"''
        ) extra-dep-list
      )}
    '';
in
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

      cargoHash,
      custom-deps ? [ ],
      extraCargoDeps ? [ ],

      update-script,
      ...
    }:
    let
      root-cargoDeps = rustPlatform.fetchCargoVendor {
        name = "fluxer";
        inherit src;
        hash = cargoHash;
      };

      inherit (finalAttrs) fluxer-ci;
    in
    {
      __structuredAttrs = true;
      strictDeps = true;

      pname = fluxer-component;
      name =
        let
          inherit (finalAttrs) pname version;
        in
        if (version != null) then "${pname}-${version}" else "${pname}";

      inherit version build-channel src;

      fluxer-ci = rustPlatform.buildRustPackage {
        name = "fluxer-ci";
        inherit (finalAttrs) src;
        buildAndTestSubdir = "tools/ci";
        cargoDeps = root-cargoDeps;

        meta.mainProgram = "fluxer-ci";

        # using debug mode cuts down the build time of this utility from 3min to 1min on my machine.
        # that's significant, as *everything else fluxer* blocks on this.
        # overall, this saves about 25%-33% *total build time* for fluxer-desktop.
        buildType = "debug";
      };

      postPatch = ''
        patchShebangs --build tools/ci/run.sh
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

      cargoDeps =
        if extraCargoDeps != [ ] then merge-cargo-deps root-cargoDeps extraCargoDeps else root-cargoDeps;
      custom-deps =
        lib.optionals (extraCargoDeps != [ ]) (
          map (cargoDeps: cargoDeps.vendorStaging) ([ root-cargoDeps ] ++ extraCargoDeps)
        )
        ++ custom-deps;
    };

  transformDrv = drv: drv // drv.custom-deps-attrs;
}
