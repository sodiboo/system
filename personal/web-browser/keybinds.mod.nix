{
  personal.home-shortcut =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    let
      cfg = config.programs.librewolf;
      profile = cfg.profiles.sodiboo;
      profile-path = "${cfg.profilesPath}/${profile.path}";

      keybinds-json = builtins.toFile "keybinds.json" (builtins.toJSON config.browser.extension-keybinds);
    in
    {
      options.browser.extension-keybinds = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              addon = lib.mkOption { type = lib.types.str; };
              key = lib.mkOption { type = lib.types.str; };
            };
          }
        );
      };

      config.home.activation.librewolf-extensions-shortcuts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        EXTENSION_JSON="$HOME/${profile-path}/extension-settings.json"
        PARENT="$(dirname $EXTENSION_JSON)"
        if [ ! -e "$EXTENSION_JSON" ]; then
          if [ ! -e "$PARENT" ]; then
            run mkdir -p $PARENT
          fi

          if [[ -v DRY_RUN ]]; then
            verboseEcho "would create $EXTENSION_JSON"
          else
            echo '{"version":3}' > "$EXTENSION_JSON"
          fi
        fi

        if [[ ! -v DRY_RUN ]]; then
          if [[ "$(cat "$EXTENSION_JSON" | jq .version)" -ne "3" ]]; then
            echo "extension-settings.json is not at version 3"
            exit 1
          fi
          cat "$EXTENSION_JSON" | ${lib.getExe pkgs.jq} \
            --argjson declared "$(cat ${keybinds-json})" \
            --from-file ${./keybinds.jq} | ${lib.getExe' pkgs.moreutils "sponge"} "$EXTENSION_JSON"
        fi
      '';
    };
}
