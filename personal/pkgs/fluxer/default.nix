{
  lib,
  pkgs,
  ...
}:
rec {
  invoke = builtins.mapAttrs (_: f: callPackage f { });

  fluxer-utils =
    invoke {
      fetch-fluxer-source = ./fetch-fluxer-source.nix;
      make-fluxer-derivation = ./make-fluxer-derivation.nix;
      fluxer-update-script = ./fluxer-update-script.nix;
    }
    // {
      inherit callPackage;
    };
  fluxer-pkgs = invoke {
    make-fluxer-desktop = ./fluxer-desktop.nix;
    make-fluxer-desktop-electron-bin = ./fluxer-desktop-electron-bin.nix;
  };

  fluxer-components = invoke {
    fluxer-desktop-stable = ./fluxer-desktop-stable.nix;
    fluxer-desktop-canary = ./fluxer-desktop-canary.nix;
    fluxer-app-proxy = ./fluxer-app-proxy.nix;
  };

  callPackage = lib.callPackageWith (pkgs // fluxer-utils // fluxer-pkgs // fluxer-components);
}
