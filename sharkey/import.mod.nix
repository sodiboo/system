{nixpkgs-with-meilisearch-at-1-8-3, ...}: {
  oxygen.modules = [
    {
      nixpkgs.overlays = [
        (final: prev: {
          sharkey = final.callPackage ./package.nix {};
          meilisearch = final.callPackage "${nixpkgs-with-meilisearch-at-1-8-3}/pkgs/servers/search/meilisearch" {
            # macOS frameworks that aren't used on Linux, but part of the closure
            Security = abort "unreachable";
            SystemConfiguration = abort "unreachable";
          };
        })
      ];
    }
    (import ./module.nix)
  ];
}
