{
  personal.home-shortcut =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.browser.userchrome = {
        js = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
        };
        omni-patches = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
        };
        # css = lib.mkOption {
        #   type = lib.types.listOf lib.types.path;
        #   default = [];
        # };
      };
      config =
        let

          userchrome-js-root = lib.fileset.toSource {
            root = ./.;
            fileset =
              lib.filesystem.listFilesRecursive ./.
              |> lib.filter (lib.strings.hasSuffix ".js")
              |> lib.fileset.unions;
          };
        in
        {
          assertions = builtins.map (f: {
            assertion = lib.path.hasPrefix ./. f;
            message = "userchrome.js entry ${toString f} is not rooted in ${toString ./.}";
          }) config.browser.userchrome.js;

          home.file =
            let
              cfg = config.programs.librewolf;
              profile = cfg.profiles.sodiboo;
              profile-path = "${cfg.profilesPath}/${profile.path}";
            in
            {
              # "${profile-path}/chrome/utils/chrome.manifest".text = ''
              #   content userchromejs ${userchrome-js-root}
              # '';
            };

          programs.librewolf = {
            # policies.Preferences."general.config.sandbox_enabled" = {
            #   Value = false;
            #   Locked = true;
            # };

            package =
              pkgs.librewolf.overrideAttrs
                (attrs: prevAttrs: {
                  passthru = prevAttrs.passthru // {
                    omni-ja = pkgs.stdenvNoCC.mkDerivation {
                      name = "omni.ja";
                      
                      src = "${attrs.passthru.unwrapped}/lib/librewolf/browser/omni.ja";
                  nativeBuildInputs = [pkgs.unzip pkgs.zip];
                  unpackCmd =  ''unzip -qq "$curSrc" -d omni || true'';
                  patches = config.browser.userchrome.omni-patches;

                  installPhase = ''
                    zip -rq $out *
                  '';
                    };
                  };
                  buildCommand = ''
                    ${prevAttrs.buildCommand}

                    # this file is genuinely just present twice ???
                    ln -sf "${attrs.passthru.omni-ja}" "$libDir/browser/omni.ja"
                    ln -sf "${attrs.passthru.omni-ja}" "$libDir/omni.ja"
                  '';
                });
          };
        };
    };
}
