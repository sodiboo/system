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

  desktop-components = invoke {
    fluxer-desktop-stable = ./app/desktop/fluxer-desktop-stable.nix;
    fluxer-desktop-canary = ./app/desktop/fluxer-desktop-canary.nix;
  };

  server-components = invoke {
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

  fluxer-component-sets =
    builtins.mapAttrs
      (
        name: components:
        (pkgs.linkFarm name components).overrideAttrs (
          finalAttrs: prevAttrs: {
            # note that this update script is very specific to this repo's root. in particular, all entries of `fluxer-components` are exported in `packages.<system>` and can be referred to by e.g. `.#fluxer-desktop-canary`
            # then, you can update it all like `nix-update --flake -u fluxer-full`
            passthru = prevAttrs.passthru // {
              updateScript = [
                (pkgs.writeShellScript "update-many-packages" ''
                  for p in "$@"; do
                    ${lib.getExe pkgs.nix-update} --flake -u $p
                  done
                '')
              ]
              ++ (builtins.attrNames components);
            };

            # hacks to get nix-update to not complain when invoking the above update script
            version = null;
            pos = builtins.unsafeGetAttrPos "x" { x = null; };
          }
        )
      )
      {
        fluxer-both-desktops = desktop-components;
        fluxer-server-full = server-components;
        fluxer-full = desktop-components // server-components;
      };

  fluxer-components = desktop-components // server-components // fluxer-component-sets;

  callPackage = lib.callPackageWith (pkgs // fluxer-lib // fluxer-components);
}
