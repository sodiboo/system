{
  personal = {
    nixpkgs.overlays = [
      (final: prev: {
        fluxer-desktop = final.callPackage ./fluxer.nix { };
      })
    ];
    home-shortcut = { pkgs, ... }: {
      home.packages = [ pkgs.fluxer-desktop ];
    };
  };
}
