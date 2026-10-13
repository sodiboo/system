{ firefox-addons, ... }: {
  personal = {
    nixpkgs.overlays = [
      (final: prev: {
        firefox-addons = firefox-addons.packages.${final.stdenv.hostPlatform.system};
      })
    ];

    home-shortcut =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        options.browser.web-extensions = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                package = lib.mkOption { type = lib.types.package; };
                installation_mode = lib.mkOption {
                  type = lib.types.str;
                  default = "force_installed";
                };
                private_browsing = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
                blocked_permissions = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                allowed_permissions = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
              };
            }
          );
        };

        config.programs.librewolf.policies = lib.mkMerge (
          config.browser.web-extensions
          |> map (cfg: {
            ExtensionSettings.${cfg.package.addonId} = {
              install_url = "file://${cfg.package}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${cfg.package.addonId}.xpi";
              inherit (cfg)
                installation_mode
                private_browsing
                blocked_permissions
                allowed_permissions
                ;
            };
          })
        );

        config.browser.web-extensions = [
          {
            package = pkgs.firefox-addons.ublock-origin;
            private_browsing = true;
            #   permissions = [
            #     "alarms"
            #     "dns"
            #     "menus"
            #     "privacy"
            #     "storage"
            #     "tabs"
            #     "unlimitedStorage"
            #     "webNavigation"
            #     "webRequest"
            #     "webRequestBlocking"
            #     "<all_urls>"
            #     "http://*/*"
            #     "https://*/*"
            #     "file://*/*"
            #     "https://easylist.to/*"
            #     "https://*.fanboy.co.nz/*"
            #     "https://filterlists.com/*"
            #     "https://forums.lanik.us/*"
            #     "https://github.com/*"
            #     "https://*.github.io/*"
            #     "https://github.com/uBlockOrigin/*"
            #     "https://ublockorigin.github.io/*"
            #     "https://*.reddit.com/r/uBlockOrigin/*"
            #   ];
          }

          {
            package = pkgs.firefox-addons.bitwarden;
            blocked_permissions = [ "*" ];
            # allowed_permissions =["tans"];
            # permissions = [
            #   "<all_urls>"
            #   "*://*/*"
            #   "alarms"
            #   "clipboardRead"
            #   "clipboardWrite"
            #   "contextMenus"
            #   "idle"
            #   "storage"
            #   "tabs"
            #   "unlimitedStorage"
            #   "webNavigation"
            #   "webRequest"
            #   "webRequestBlocking"
            #   "notifications"
            #   "file:///*"
            # ];
          }

          {
            package = pkgs.firefox-addons.darkreader;
            # permissions = [
            #   "alarms"
            #   "contextMenus"
            #   "storage"
            #   "tabs"
            #   "theme"
            #   "<all_urls>"
            # ];
          }
          {
            package = pkgs.firefox-addons.libredirect;
            # permissions = [
            #   "webRequest"
            #   "webRequestBlocking"
            #   "storage"
            #   "clipboardWrite"
            #   "contextMenus"
            #   "<all_urls>"
            # ];
          }
          {
            package = pkgs.firefox-addons.sponsorblock;
            # permissions = [
            #   "storage"
            #   "scripting"
            #   "unlimitedStorage"
            #   "https://sponsor.ajay.app/*"
            #   "https://*.youtube.com/*"
            #   "https://www.youtube-nocookie.com/embed/*"
            # ];
          }
          {
            package = pkgs.firefox-addons.return-youtube-dislikes;
            # permissions = [
            #   "activeTab"
            #   "*://*.youtube.com/*"
            #   "storage"
            #   "*://returnyoutubedislikeapi.com/*"
            #   "identity"
            # ];
          }
          {
            package = pkgs.firefox-addons.dearrow;
            # permissions = [
            #   "storage"
            #   "unlimitedStorage"
            #   "alarms"
            #   "https://sponsor.ajay.app/*"
            #   "https://dearrow-thumb.ajay.app/*"
            #   "https://*.googlevideo.com/*"
            #   "https://*.youtube.com/*"
            #   "https://www.youtube-nocookie.com/embed/*"
            #   "scripting"
            #   "https://dearrow.ajay.app/*"
            # ];
          }

          {
            package = pkgs.firefox-addons.consent-o-matic;
            # permissions = [
            #   "activeTab"
            #   "tabs"
            #   "storage"
            #   "<all_urls>"
            # ];
          }

          {
            package = pkgs.firefox-addons.fastforwardteam;
            # permissions = [
            #   "alarms"
            #   "storage"
            #   "webNavigation"
            #   "tabs"
            #   "declarativeNetRequestWithHostAccess"
            #   "<all_urls>"
            # ];
          }

          {
            package = pkgs.firefox-addons.indie-wiki-buddy;
            # permissions = [
            #   "alarms"
            #   "storage"
            #   "webRequest"
            #   "notifications"
            #   "scripting"
            #   "https://*.fandom.com/*"
            #   "https://*.fextralife.com/*"
            #   "https://*.neoseeker.com/*"
            #   "https://breezewiki.com/*"
            #   "https://www.google.com/search*"
            # ];
          }
        ];
      };
  };
}
