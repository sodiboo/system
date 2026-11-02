{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-api ? callPackage ../server/fluxer-api.nix { },
}:
make-fluxer-api (finalAttrs: {
  version = "2026.1102.32727";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-goNmjNPYxvLsRoO+O/+FOTfN+RBiplQvPmAaBQS7ziM=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  pnpmHash = "sha256-5AFBfz2tzIHayDWpkq6uheyH0j86glVIn5UpseCzw+g=";
})
