{nixpkgs-with-meilisearch-at-1-8-3, ...}: {
  oxygen.modules = [
    {
      nixpkgs.overlays = [
        (final: prev: {
          sharkey = final.callPackage ./package.nix {};
          meilisearch = nixpkgs-with-meilisearch-at-1-8-3.legacyPackages.x86_64-linux.meilisearch;
        })
      ];
    }
    (import ./module.nix)
  ];
}
