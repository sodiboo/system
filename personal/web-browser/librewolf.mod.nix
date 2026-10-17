{
  personal.home-shortcut =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.browser = {
        omni-patches = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
        };

        preferences = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.oneOf [
              lib.types.bool
              lib.types.int
              lib.types.str
            ]
          );
          default = { };
        };
      };

      imports = [
        (lib.mkAliasOptionModule [ "browser" "policies" ] [ "programs" "librewolf" "policies" ])
      ];

      config = {
        stylix.targets.librewolf.enable = false;

        programs.librewolf = {
          enable = true;

          package =
            (pkgs.librewolf.overrideAttrs (
              attrs: prevAttrs: {
                passthru = prevAttrs.passthru // {
                  omni-ja = pkgs.stdenvNoCC.mkDerivation {
                    name = "omni.ja";

                    src = "${attrs.passthru.unwrapped}/lib/librewolf/browser/omni.ja";
                    nativeBuildInputs = [
                      pkgs.unzip
                      pkgs.zip
                    ];
                    unpackCmd = ''unzip -qq "$curSrc" -d omni || true'';
                    patches = config.browser.omni-patches;

                    installPhase = ''
                      zip -rq $out *
                    '';
                  };
                };
                buildCommand = ''
                  ${prevAttrs.buildCommand}

                  ln -sf "${attrs.passthru.omni-ja}" "$libDir/browser/omni.ja"
                '';
              }
            )).override
              (prev: {
                extraPrefs = ''
                  ${prev.extraPrefs or ""}
                  ${builtins.concatStringsSep "\n" (
                    lib.mapAttrsToList (name: value: ''
                      lockPref("${name}", ${builtins.toJSON value});
                    '') config.browser.preferences
                  )}
                '';
              });
          profiles.sodiboo = { };
        };

      };
    };
}
