{
  oxygen.modules = [
    {
      nixpkgs.overlays = [
        (final: prev: {
          sharkey = final.callPackage ./package.nix {};
        })
      ];
    }
    (import ./module.nix)
  ];
}
