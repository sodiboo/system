{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-admin ? callPackage ../server/fluxer-admin.nix { },
}:
make-fluxer-admin (finalAttrs: {
  version = "2026.1026.150423";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-+wgDWFzAafPt3LPUASGkE0FppQS65zHKqvlc3AQ6Qzk=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  cargoHash = "sha256-3PnAeK3MaRDELl/iBCLx3aD05k/6jVoxT7biSfUTdQU=";
})
