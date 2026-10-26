{
  lib,
  callPackage,
  makeWrapper,

  fetchPnpmDeps,

  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-derivation,

  make-fluxer-app-proxy ? callPackage ./fluxer-app-proxy.nix { },
  make-fluxer-app-web ? callPackage ./fluxer-app-web.nix { },
}:
make-fluxer-derivation (finalAttrs: {
  version = "2026.1026.2930";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-qGeyZHvhdDd0d0bs/qCPmOG4N4a+ixhItTb7w5m1aHc=";
  };

  fluxer-ci = null;
  cargoHash = "sha256-mC7Y84XD1GkEPvrQi2sTit3HMRObsDIryfSPmwhf69A=";

  unwrapped = make-fluxer-app-proxy { inherit (finalAttrs) version src cargoDeps; };

  custom-deps = [
    finalAttrs.dist.pnpmDeps
    finalAttrs.dist.libfluxcore.cargoDeps.vendorStaging
    finalAttrs.dist.libfluxwebp.cargoDeps.vendorStaging
  ];

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  inherit (finalAttrs.unwrapped) fluxer-component;
  pname = "${finalAttrs.fluxer-component}-wrapper";

  build-channel = "stable";

  dist = make-fluxer-app-web {
    inherit (finalAttrs) version src cargoDeps;

    pnpmDeps = fetchPnpmDeps {
      pname = "fluxer";
      inherit (finalAttrs) src;
      fetcherVersion = 4;
      hash = "sha256-cYy7MO3aRBSUqY8yMGjZ5Oo1/ys0IMfh3LPzNdUlUBY=";
    };

    libfluxcore.cargoHash = "sha256-n9hA0WaUyYpXV9ply8QwUgq4NvmBERIebrfzz2lCd/A=";
    libfluxwebp.cargoHash = "sha256-zz5JD3jiNCx8FOReZmCm4O2F20s7UbMsfZIM2sIcSS0=";
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${lib.getExe finalAttrs.unwrapped} $out/bin/fluxer-app-proxy \
      --set-default FLUXER_STATIC_DIR ${finalAttrs.dist.compressed} \
      --set-default RELEASE_CHANNEL ${lib.escapeShellArg finalAttrs.build-channel}
  '';

  inherit (finalAttrs.unwrapped) meta;
})
