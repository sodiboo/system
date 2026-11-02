{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-unfurl ? callPackage ../server/fluxer-unfurl.nix { },
}:
make-fluxer-unfurl (finalAttrs: {
  version = "2026.1102.32750";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-goNmjNPYxvLsRoO+O/+FOTfN+RBiplQvPmAaBQS7ziM=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  cargoHash = "sha256-KBKwdYW3tpZmjoqlA5Lx4b0FTlPcHKrDsXXtazuQO0g=";
})
