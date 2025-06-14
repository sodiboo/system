{nixpkgs-with-meilisearch-at-1-8-3, ...}: {
  oxygen = {
    imports = [./module.nix];
    config.nixpkgs.overlays = [
      (final: prev: {
        sharkey = final.callPackage ./package.nix {};
        meilisearch = nixpkgs-with-meilisearch-at-1-8-3.legacyPackages.x86_64-linux.meilisearch;
        meilisearch_1_11 = final.meilisearch; # <-- it uses this package because of an old stateVersion. i'll upgrade at some point.
      })
    ];
  };
}
