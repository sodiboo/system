{
  lib,

  cargo,
  rustc,
  rustPlatform,

  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-derivation,
}:
make-fluxer-derivation (finalAttrs: {
  fluxer-component = "fluxer-messages";
  version = "2026.1026.202726";

  fluxer-ci = null;

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-NzgBQwvJSHCwnF2bG/+vywp8mgPpAhUzTP/irrvCQjM=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  nativeBuildInputs = [
    cargo
    rustc
    rustPlatform.cargoSetupHook
    rustPlatform.cargoBuildHook
    rustPlatform.cargoInstallHook
  ];

  env = {
    buildAndTestSubdir = "fluxer_messages";
    cargoBuildType = "release";
  };

  cargoHash = "sha256-3PnAeK3MaRDELl/iBCLx3aD05k/6jVoxT7biSfUTdQU=";

  meta = {
    description = "A free and open source instant messaging and VoIP chat app";
    license = lib.licenses.agpl3Plus;
    homepage = "https://github.com/fluxerapp/fluxer";
    maintainers = with lib.maintainers; [ sodiboo ];
    mainProgram = "fluxer-messages";
  };
})
