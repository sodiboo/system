{
  lib,

  tailwindcss_4,

  cargo,
  rustc,
  rustPlatform,

  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-derivation,
}:
make-fluxer-derivation (finalAttrs: {
  fluxer-component = "fluxer-admin";
  version = "2026.1026.150423";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-+wgDWFzAafPt3LPUASGkE0FppQS65zHKqvlc3AQ6Qzk=";
  };

  fluxer-ci = null;

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  nativeBuildInputs = [
    cargo
    rustc
    rustPlatform.cargoSetupHook
    rustPlatform.cargoBuildHook
    rustPlatform.cargoInstallHook

    tailwindcss_4
  ];

  env = {
    buildAndTestSubdir = "fluxer_admin";
    cargoBuildType = "release";
  };

  cargoHash = "sha256-3PnAeK3MaRDELl/iBCLx3aD05k/6jVoxT7biSfUTdQU=";

  postInstall = ''
    mv $out/bin/fluxer_admin $out/bin/fluxer-admin
  '';

  meta = {
    description = "A free and open source instant messaging and VoIP chat app";
    license = lib.licenses.agpl3Plus;
    homepage = "https://github.com/fluxerapp/fluxer";
    maintainers = with lib.maintainers; [ sodiboo ];
    mainProgram = "fluxer-admin";
  };
})
