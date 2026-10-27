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

    fluxer-admin = ./server/fluxer-admin.nix;
    fluxer-api = ./server/fluxer-api.nix;
    fluxer-gateway = ./server/fluxer-gateway.nix;
    fluxer-gifs = ./server/fluxer-gifs.nix;
    fluxer-media-proxy = ./server/fluxer-media-proxy.nix;
    fluxer-messages = ./server/fluxer-messages.nix;
    fluxer-push = ./server/fluxer-push.nix;
    fluxer-snowflakes = ./server/fluxer-snowflakes.nix;
    fluxer-unfurl = ./server/fluxer-unfurl.nix;
    fluxer-users = ./server/fluxer-users.nix;
  };

  callPackage = lib.callPackageWith (pkgs // fluxer-lib // fluxer-components);
}
