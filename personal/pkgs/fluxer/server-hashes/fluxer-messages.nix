{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-messages ? callPackage ../server/fluxer-messages.nix { },
}:
make-fluxer-messages (finalAttrs: {
  version = "2026.1102.30915";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-H5+DaHvJvkX3BJ68ZenGOT2HnxXYUOza9yiNVHsUxTI=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  cargoHash = "sha256-KBKwdYW3tpZmjoqlA5Lx4b0FTlPcHKrDsXXtazuQO0g=";
})
