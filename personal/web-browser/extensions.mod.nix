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
        options.browser.extensions = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, options, ... }: {
                options = {
                  package = lib.mkOption {
                    type = lib.types.package;
                    default =
                      pkgs.firefox-addons.${name}
                        or "unknown browser extension ${name}; please set ${lib.showOption options.package}";
                  };
                  installation_mode = lib.mkOption {
                    type = lib.types.str;
                    default = "force_installed";
                  };
                  default_area = lib.mkOption {
                    type = lib.types.str;
                    default = "menupanel";
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
                  managed = lib.mkOption {
                    type = (pkgs.formats.json { }).type;
                    default = null;
                  };
                  keybindings = lib.mkOption {
                    type = lib.types.attrsOf lib.types.str;
                    default = { };
                  };
                };
              }
            )
          );
        };

        config.browser.extension-keybinds = lib.mkMerge (
          config.browser.extensions
          |> lib.mapAttrsToList (
            _: cfg:
            cfg.keybindings
            |> lib.mapAttrs (
              _: key: {
                addon = cfg.package.addonId;
                inherit key;
              }
            )
          )
        );

        config.browser.policies = lib.mkMerge (
          [
            {
              # let me install my own patched/unsigned shit !!!!
              Preferences = {
                "xpinstall.signatures.required" = {
                  Value = false;
                  Locked = true;
                };
              };

              # but make sure that can't be done easily at runtime. only through config.
              ExtensionSettings."*" = {
                installation_mode = "blocked";
              };
            }
          ]
          ++ (
            config.browser.extensions
            |> lib.mapAttrsToList (
              _: cfg: {
                ExtensionSettings.${cfg.package.addonId} = {
                  install_url = "file://${cfg.package}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${cfg.package.addonId}.xpi";
                  inherit (cfg)
                    installation_mode
                    private_browsing
                    blocked_permissions
                    allowed_permissions
                    default_area
                    ;
                  updates_disabled = true; # only update with the rest of my system thank u
                };
                "3rdparty".Extensions.${cfg.package.addonId} = lib.mkIf (cfg.managed != null) cfg.managed;
              }
            )
          )
        );
      };
  };
}
