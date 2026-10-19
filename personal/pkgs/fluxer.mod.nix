{
  personal = {
    nixpkgs.overlays = [
      (final: prev: {
        fluxer-desktop = final.callPackage ./fluxer.nix { };
        fluxtop = final.callPackage ./fluxtop.nix { };
      })
    ];
    home-shortcut = { pkgs, ... }: {
      home.packages = [
        pkgs.fluxer-desktop
        pkgs.fluxtop
      ];
    };
  };
}
