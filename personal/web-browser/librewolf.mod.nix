{
  personal.home-shortcut =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      pref-scalar = lib.types.oneOf [
        lib.types.bool
        lib.types.int
        lib.types.str
      ];

      pref = lib.mkOptionType {
        name = "mozilla-preference";
        description = "mozilla preference";
        descriptionClass = "noun";

        check = _: true;
        merge =
          loc: defs:
          let
            defs' =
              defs
              |> map (
                def:
                if builtins.isAttrs def.value then
                  def
                else
                  def
                  // {
                    value.locked = def.value;
                  }
              );
            merged =
              (lib.types.attrTag {
                locked = lib.mkOption { type = pref-scalar; };
                default = lib.mkOption { type = pref-scalar; };
                mutable = lib.mkOption { type = pref-scalar; };
              }).merge
                loc
                defs';
            kind =
              assert builtins.length (builtins.attrNames merged) == 1;
              builtins.head (builtins.attrNames merged);
          in
          {
            inherit kind;
            value = merged.${kind};
          };
      };
    in
    {
      options.browser = {
        omni-patches = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
        };

        preferences = lib.mkOption {
          type = lib.types.attrsOf pref;
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
                    lib.mapAttrsToList (name: { kind, value }: ''
                      ${
                        {
                          locked = "lockPref";
                          default = "defaultPref";
                          mutable = "pref";
                        }
                        .${kind}
                      }("${name}", ${builtins.toJSON value});
                    '') config.browser.preferences
                  )}
                '';
              });
          profiles.sodiboo = { };
        };

      };
    };
}
