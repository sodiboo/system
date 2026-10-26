{
  lib,
  callPackage,
  makeWrapper,

  fetchPnpmDeps,

  cargo,
  rustc,
  rustPlatform,

  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-derivation,
}:
make-fluxer-derivation (finalAttrs: {
  fluxer-component = "fluxer-app-proxy";
  version = "2026.1026.2930";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-qGeyZHvhdDd0d0bs/qCPmOG4N4a+ixhItTb7w5m1aHc=";
  };

  fluxer-ci = null;
  cargoHash = "sha256-mC7Y84XD1GkEPvrQi2sTit3HMRObsDIryfSPmwhf69A=";

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  custom-deps = [
    finalAttrs.dist.pnpmDeps
    finalAttrs.dist.libfluxcore.cargoDeps.vendorStaging
    finalAttrs.dist.libfluxwebp.cargoDeps.vendorStaging
  ];

  unwrapped = make-fluxer-derivation {
    inherit (finalAttrs)
      fluxer-component
      version
      src
      cargoDeps
      ;

    fluxer-ci = null;
    update-script = null;

    nativeBuildInputs = [
      makeWrapper
      rustc
      cargo
      rustPlatform.cargoSetupHook
      rustPlatform.cargoBuildHook
      rustPlatform.cargoInstallHook
    ];

    env = {
      buildAndTestSubdir = "fluxer_app_proxy";
      cargoBuildType = "release";
    };

    postInstall = ''
      mv $out/bin/fluxer_app_proxy $out/bin/fluxer-app-proxy
    '';

    meta = {
      description = "A free and open source instant messaging and VoIP chat app";
      license = lib.licenses.agpl3Plus;
      homepage = "https://github.com/fluxerapp/fluxer";
      maintainers = with lib.maintainers; [ sodiboo ];
      mainProgram = "fluxer-app-proxy";
    };
  };

  dist = callPackage ./fluxer-app-web.nix { } {
    inherit (finalAttrs)
      version
      src
      cargoDeps
      ;

    pnpmDeps = fetchPnpmDeps {
      pname = "fluxer";
      inherit (finalAttrs) src;
      fetcherVersion = 4;
      hash = "sha256-cYy7MO3aRBSUqY8yMGjZ5Oo1/ys0IMfh3LPzNdUlUBY=";
    };

    build-channel = "stable";

    libfluxcore.cargoHash = "sha256-n9hA0WaUyYpXV9ply8QwUgq4NvmBERIebrfzz2lCd/A=";
    libfluxwebp.cargoHash = "sha256-zz5JD3jiNCx8FOReZmCm4O2F20s7UbMsfZIM2sIcSS0=";
  };

  pname = "${finalAttrs.fluxer-component}-wrapper";

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe finalAttrs.unwrapped} $out/bin/fluxer-app-proxy \
      --set-default FLUXER_STATIC_DIR ${finalAttrs.dist.compressed}
  '';

  inherit (finalAttrs.unwrapped) meta;
})
