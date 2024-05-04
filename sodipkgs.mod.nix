{
  sodipkgs-simutrans,
  sodipkgs-stackblur,
  ...
}: {
  shared.modules = [
    {
      nixpkgs.overlays = [
        (final: prev: {
          simutrans = prev.callPackage "${sodipkgs-simutrans}/pkgs/games/simutrans" {};
          stackblur-go = prev.callPackage "${sodipkgs-stackblur}/pkgs/by-name/st/stackblur-go/package.nix" {};
        })
      ];
    }
  ];
}
