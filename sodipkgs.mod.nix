let
  by-name = name: "/by-name/${builtins.substring 0 2 name}/${name}/package.nix";
in
  inputs: {
    personal.modules = [
      {
        nixpkgs.overlays = [
          (
            final: prev:
              builtins.mapAttrs (
                name: path:
                  prev.callPackage "${inputs."sodipkgs-${name}"}/pkgs/${path}" {}
              ) {
                simutrans = "/games/simutrans";
                stackblur-go = by-name "stackblur-go";
                itch = by-name "itch";
              }
          )
        ];
      }
    ];
  }
