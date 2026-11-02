{
  lib,

  cargo,
  rustc,
  rustPlatform,

  make-fluxer-derivation,
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  extendDrvArgs = finalAttrs: args: {
    fluxer-component = "fluxer-push";

    fluxer-ci = null;

    nativeBuildInputs = [
      cargo
      rustc
      rustPlatform.cargoSetupHook
      rustPlatform.cargoBuildHook
      rustPlatform.cargoInstallHook
    ]
    ++ args.nativeBuildInputs or [ ];

    env = {
      buildAndTestSubdir = "fluxer_push";
      cargoBuildType = "release";
    }
    // args.env or { };

    meta = {
      description = "A free and open source instant messaging and VoIP chat app";
      license = lib.licenses.agpl3Plus;
      homepage = "https://github.com/fluxerapp/fluxer";
      maintainers = with lib.maintainers; [ sodiboo ];
      mainProgram = "fluxer-push";
    }
    // args.meta or { };
  };
}
