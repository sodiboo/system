{
  oxygen = {
    imports = [ ./module.nix ];
    config.nixpkgs.overlays = [
      (final: prev: {
        sharkey = final.callPackage ./package.nix { };
      })
    ];
  };
}
