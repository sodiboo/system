{
  personal = {
    nixpkgs.overlays = [
      (
        final: prev:
        let
          fluxer = final.callPackage ./fluxer { };
        in
        fluxer.fluxer-components
        // {
          fluxtop = final.callPackage ./fluxtop.nix { };
        }
      )
    ];
    home-shortcut = { pkgs, ... }: {
      home.packages = [
        pkgs.fluxer-desktop-stable
        pkgs.fluxer-desktop-canary
        pkgs.fluxtop
      ];
    };
  };
}
