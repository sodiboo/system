{
  oxygen = {
    imports = [
      ./continuwuity/module.nix
      ./sharkey/module.nix
    ];
    config.nixpkgs.overlays = [
      (final: prev: {
        sharkey = final.callPackage ./sharkey/package.nix { };
      })
    ];
  };
}
