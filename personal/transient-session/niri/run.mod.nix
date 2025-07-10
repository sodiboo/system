{
  personal.home-shortcut =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.transient-session;

      activate-transient-niri-session = pkgs.callPackage ./activate.nix { };

      run-transient-niri-session = pkgs.writeShellScriptBin "run-transient-niri-session" ''
        exec systemd-run --user ${
          let
            # assumes that $WAYLAND_DISPLAY is well-formed as a valid systemd unit instance name.
            # niri always sets it as `wayland-0`, `wayland-1`, etc, which is fine here.
            # if you're using this in a different context, it's mostly just important
            # that this is a *unique* instance name which is valid. it doesn't matter if it matches $WAYLAND_DISPLAY.
            instance = "$WAYLAND_DISPLAY";

            unit = "transient-niri-session@${instance}";

            env = [
              "WAYLAND_DISPLAY"
              "DISPLAY"
              "XDG_CURRENT_DESKTOP"
              "XDG_SESSION_TYPE"
              "NIRI_SOCKET"
              "XCURSOR_SIZE"
              "XCURSOR_THEME"
            ];

            target = "${cfg.target-stem}@${instance}.target";

            properties = [
              "BindsTo=${target}"
              "Before=${target}"
              "PropagatesStopTo=${target}"
            ];

            environment-file = "$XDG_RUNTIME_DIR/transient-session/${instance}.env";
          in
          builtins.concatStringsSep " " (
            [
              "--unit=${unit}"
              "--service-type=notify"
              "--setenv=FILL_ENVIRONMENT_FILE=${environment-file}"
            ]
            ++ builtins.map (var: "--setenv=${var}") env
            ++ builtins.map (prop: "--property=${prop}") properties
            ++ [ "--" ]
            ++ [ (lib.getExe activate-transient-niri-session) ]
            ++ env
          )
        }
      '';

    in
    {
      home.packages = [ run-transient-niri-session ];
      programs.niri.settings.spawn-at-startup = [
        { command = [ (lib.getExe run-transient-niri-session) ]; }
      ];
    };
}
