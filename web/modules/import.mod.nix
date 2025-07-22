{
  oxygen = {
    imports = [
      ./continuwuity/continuwuity.nix
      ./sharkey/sharkey.nix
    ];
    config.nixpkgs.overlays = [
      (final: prev: {
        sharkey = final.callPackage ./sharkey/package.nix { };
      })
    ];
  };
}
