{
  personal.home-shortcut =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.browser.omni-patches = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
      };
      config.programs.librewolf.package = pkgs.librewolf.overrideAttrs (
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
              patches = config.browser.userchrome.omni-patches;

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
      );
    };
}
