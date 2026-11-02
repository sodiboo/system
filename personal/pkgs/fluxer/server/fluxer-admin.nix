{
  lib,

  tailwindcss_4,

  cargo,
  rustc,
  rustPlatform,

  make-fluxer-derivation,
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  extendDrvArgs = finalAttrs: args: {
    fluxer-component = "fluxer-admin";

    fluxer-ci = null;

    nativeBuildInputs = [
      cargo
      rustc
      rustPlatform.cargoSetupHook
      rustPlatform.cargoBuildHook
      rustPlatform.cargoInstallHook

      tailwindcss_4
    ]
    ++ args.nativeBuildInputs or [ ];

    env = {
      buildAndTestSubdir = "fluxer_admin";
      cargoBuildType = "release";
    }
    // args.meta or { };

    postInstall = ''
      mv $out/bin/fluxer_admin $out/bin/fluxer-admin
      ${args.postInstall or ""}
    '';

    meta = {
      description = "A free and open source instant messaging and VoIP chat app";
      license = lib.licenses.agpl3Plus;
      homepage = "https://github.com/fluxerapp/fluxer";
      maintainers = with lib.maintainers; [ sodiboo ];
      mainProgram = "fluxer-admin";
    }
    // args.meta or { };
  };
}
