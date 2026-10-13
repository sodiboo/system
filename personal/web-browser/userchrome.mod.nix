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
              (pkgs.librewolf.override (prev: {
                extraPrefsFiles =
                  let
                    p = drv: drv.name or null == "local-settings.js";
                  in
                  assert builtins.length (builtins.filter p prev.extraPrefsFiles) == 1;
                  builtins.filter (x: !(p x)) prev.extraPrefsFiles;
              })).overrideAttrs
                (prevAttrs: {
                  buildCommand = ''
                    ${prevAttrs.buildCommand}

                    cat > "$libDir/distribution/chrome.manifest" << EOF
                      content userchromejs ./userchromejs/
                    EOF

                    ln -s ${userchrome-js-root} "$libDir/distribution/userchromejs"


                    cat >> "$prefsDir/autoconfig.js" << EOF
                    pref("general.config.filename", "mozilla.cfg");
                    pref("general.config.obscure_value", 0);
                    pref("general.config.sandbox_enabled", false);
                    EOF

                    cat >> "$libDir/mozilla.cfg" << EOF
                    lockPref("general.config.filename", "mozilla.cfg");
                    lockPref("general.config.obscure_value", 0);
                    lockPref("general.config.sandbox_enabled", false);
                    // try {
                      // console.warn("loading userchromejs stuff!");
                      let cmanifest = Cc['@mozilla.org/file/directory_service;1'].getService(Ci.nsIProperties).get("XREAppDist", Ci.nsIFile);
                      cmanifest.append("chrome.manifest");
                      Components.manager.QueryInterface(Ci.nsIComponentRegistrar).autoRegister(cmanifest);

                      ${
                        config.browser.userchrome.js
                        |> map (lib.path.removePrefix ./.)
                        |> map (file: ''

                          // try {
                          ChromeUtils.importESModule("chrome://userchromejs/content/${file}");
                          // } catch {}'')
                        |> builtins.concatStringsSep "\n"
                      }
                    // } catch {}
                    EOF

                  '';
                });
          };
        };
    };
}
