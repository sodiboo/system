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

      make-fluxer-ci = ./lib/fluxer-ci.nix;
    }
    // {
      inherit callPackage;
    };

  fluxer-components = invoke {
    fluxer-desktop-stable = ./app/desktop/fluxer-desktop-stable.nix;
    fluxer-desktop-canary = ./app/desktop/fluxer-desktop-canary.nix;

    fluxer-admin = ./server-hashes/fluxer-admin.nix;
    fluxer-app-proxy = ./server-hashes/fluxer-app-proxy.nix;
    fluxer-api = ./server-hashes/fluxer-api.nix;
    fluxer-gateway = ./server-hashes/fluxer-gateway.nix;
    fluxer-gifs = ./server-hashes/fluxer-gifs.nix;
    fluxer-media-proxy = ./server-hashes/fluxer-media-proxy.nix;
    fluxer-messages = ./server-hashes/fluxer-messages.nix;
    fluxer-push = ./server-hashes/fluxer-push.nix;
    fluxer-snowflakes = ./server-hashes/fluxer-snowflakes.nix;
    fluxer-unfurl = ./server-hashes/fluxer-unfurl.nix;
    fluxer-users = ./server-hashes/fluxer-users.nix;
  };

  callPackage = lib.callPackageWith (pkgs // fluxer-lib // fluxer-components);
}
