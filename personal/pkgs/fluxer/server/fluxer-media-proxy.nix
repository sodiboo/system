{
  lib,

  cargo,
  rustc,
  rustPlatform,

  pkg-config,

  vips,
  libheif,
  ffmpeg-headless,
  lcms2,
  libwebp,
  libyuv,

  make-fluxer-derivation,
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  extendDrvArgs = finalAttrs: args: {
    fluxer-component = "fluxer-media-proxy";

    fluxer-ci = null;

    nativeBuildInputs = [
      cargo
      rustc
      rustPlatform.cargoSetupHook
      rustPlatform.cargoBuildHook
      rustPlatform.cargoInstallHook

      pkg-config
    ]
    ++ args.nativeBuildInputs or [ ];

    buildInputs = [
      vips
      libheif
      ffmpeg-headless
      lcms2
      libwebp
      libyuv
    ]
    ++ args.buildInputs or [ ];

    env = {
      buildAndTestSubdir = "fluxer_media_proxy";
      cargoBuildType = "release";
    }
    // args.env or { };

    meta = {
      description = "A free and open source instant messaging and VoIP chat app";
      license = lib.licenses.agpl3Plus;
      homepage = "https://github.com/fluxerapp/fluxer";
      maintainers = with lib.maintainers; [ sodiboo ];
      mainProgram = "fluxer-media-proxy";
    }
    // args.meta or { };
  };
}
