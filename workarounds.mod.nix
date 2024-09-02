{nixpkgs-stable, ...}: {
  universal.modules = [
    ({pkgs, ...}: {
      nixpkgs.overlays = [
        (
          final: prev: {
            inherit (nixpkgs-stable.legacyPackages.${pkgs.stdenv.system}) glfw-wayland-minecraft;
          }
        )
      ];
    })
  ];
}
