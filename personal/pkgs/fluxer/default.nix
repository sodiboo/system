{
  lib,
  pkgs,
  ...
}:
rec {
  invoke = builtins.mapAttrs (_: f: callPackage f { });

  fluxer-lib =
    invoke {
      fetch-fluxer-source = ./lib/fetch-fluxer-source.nix;
      make-fluxer-derivation = ./lib/make-fluxer-derivation.nix;
      fluxer-update-script = ./lib/fluxer-update-script.nix;
    }
    // {
      inherit callPackage;
    };

  fluxer-components = invoke {
    fluxer-desktop-stable = ./app/desktop/fluxer-desktop-stable.nix;
    fluxer-desktop-canary = ./app/desktop/fluxer-desktop-canary.nix;
    fluxer-app-proxy = ./app/web/fluxer-app-proxy-wrapper.nix;
  };

  callPackage = lib.callPackageWith (pkgs // fluxer-lib // fluxer-components);
}
