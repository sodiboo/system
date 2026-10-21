{
  personal = {
    nixpkgs.overlays = [
      (
        final: prev:
        let
          fluxer = final.callPackage ./fluxer { };
        in
        {
          inherit (fluxer.fluxer-components)
            fluxer-desktop-stable
            fluxer-desktop-canary
            ;
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
