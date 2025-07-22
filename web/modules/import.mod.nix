{
  universal = {
    imports = [
      ./continuwuity/continuwuity.nix
      ./sharkey/sharkey.nix
      ./systemd-socket-proxyd/systemd-socket-proxyd.nix
    ];
    config.nixpkgs.overlays = [
      (final: prev: {
        sharkey = final.callPackage ./sharkey/package.nix { };
      })
    ];
  };
}
