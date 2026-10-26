{
  lib,

  rustc,
  cargo,
  rustPlatform,

  make-fluxer-derivation,
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  extendDrvArgs = finalAttrs: args: {
    fluxer-component = "fluxer-app-proxy";

    fluxer-ci = null;
    update-script = null;

    nativeBuildInputs = [
      rustc
      cargo
      rustPlatform.cargoSetupHook
      rustPlatform.cargoBuildHook
      rustPlatform.cargoInstallHook
    ]
    ++ args.nativeBuildInputs or [ ];

    env = {
      buildAndTestSubdir = "fluxer_app_proxy";
      cargoBuildType = "release";
    }
    // args.env or { };

    postInstall = ''
      mv $out/bin/fluxer_app_proxy $out/bin/fluxer-app-proxy

      ${args.postInstall or ""}
    '';

    meta = {
      description = "A free and open source instant messaging and VoIP chat app";
      license = lib.licenses.agpl3Plus;
      homepage = "https://github.com/fluxerapp/fluxer";
      maintainers = with lib.maintainers; [ sodiboo ];
      mainProgram = "fluxer-app-proxy";
    }
    // args.meta or { };
  };
}
