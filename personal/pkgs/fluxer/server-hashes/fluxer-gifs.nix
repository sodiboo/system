{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-gifs ? callPackage ../server/fluxer-gifs.nix { },
}:
make-fluxer-gifs (finalAttrs: {
  version = "2026.1026.202726";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-NzgBQwvJSHCwnF2bG/+vywp8mgPpAhUzTP/irrvCQjM=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  cargoHash = "sha256-3PnAeK3MaRDELl/iBCLx3aD05k/6jVoxT7biSfUTdQU=";
})
