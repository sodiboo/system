{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-app-proxy ? callPackage ../app/web/fluxer-app-proxy-wrapper.nix { },
}:
make-fluxer-app-proxy (finalAttrs: {
  version = "2026.1026.2930";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-qGeyZHvhdDd0d0bs/qCPmOG4N4a+ixhItTb7w5m1aHc=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  cargoHash = "sha256-mC7Y84XD1GkEPvrQi2sTit3HMRObsDIryfSPmwhf69A=";

  pnpmHash = "sha256-cYy7MO3aRBSUqY8yMGjZ5Oo1/ys0IMfh3LPzNdUlUBY=";

  libfluxcore.cargoHash = "sha256-n9hA0WaUyYpXV9ply8QwUgq4NvmBERIebrfzz2lCd/A=";
  libfluxwebp.cargoHash = "sha256-zz5JD3jiNCx8FOReZmCm4O2F20s7UbMsfZIM2sIcSS0=";
})
