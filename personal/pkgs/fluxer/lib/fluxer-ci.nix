{
  lib,
  stdenv,
  runCommand,
  rustPlatform,
  ...
}:
lib.extendMkDerivation {
  constructDrv = rustPlatform.buildRustPackage;

  extendDrvArgs = finalAttrs: args: {
    name = "fluxer-ci";
    buildAndTestSubdir = "tools/ci";

    meta.mainProgram = "fluxer-ci";

    # using debug mode cuts down the build time of this utility from 3min to 1min on my machine.
    # that's significant, as *everything else fluxer* blocks on this.
    # overall, this saves about 25%-33% *total build time* for fluxer-desktop.
    buildType = "debug";
  };

}
