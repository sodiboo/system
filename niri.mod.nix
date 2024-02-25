{niri, ...}: let
  niri_config = {wide}: {
    config,
    lib,
    ...
  }:
    with lib; let
      only = cond:
        if cond
        then id
        else const null;
      binds = {
        suffixes,
        prefixes,
        substitutions ? {},
      }: let
        replacer = replaceStrings (attrNames substitutions) (attrValues substitutions);
        format = prefix: suffix:
          niri.kdl.plain "${prefix.key}+${suffix.key}" [
            (let
              actual-suffix =
                if isList suffix.action
                then {
                  action = head suffix.action;
                  args = tail suffix.action;
                }
                else {
                  inherit (suffix) action;
                  args = [];
                };
            in
              niri.kdl.leaf (replacer "${prefix.action}-${actual-suffix.action}") actual-suffix.args)
          ];
        pairs = attrs: fn:
          concatMap (key:
            fn {
              inherit key;
              action = attrs.${key};
            }) (attrNames attrs);
      in
        pairs prefixes (prefix: pairs suffixes (suffix: [(format prefix suffix)]));

      colors = pipe (range 0 15) [
        (map (i: "base0${toHexString i}"))
        (map (name: {
          inherit name;
          value = forEach ["r" "g" "b"] (c: toInt config.lib.stylix.colors."${name}-rgb-${c}");
        }))
        listToAttrs
      ];
    in {
      programs.niri.config = with niri.kdl;
        serialize.nodes [
          (plain "input" [
            (plain "keyboard" [
              (plain "xkb" [
                (leaf "layout" ["no"])
              ])
            ])
            (plain "mouse" [
              (leaf "accel-speed" [1.0])
            ])
            (plain "touchpad" [
              (plain-leaf "tap")
              (plain-leaf "dwt")
              (plain-leaf "natural-scroll")
            ])
          ])
          (plain "cursor" [
            (leaf "xcursor-size" [config.stylix.cursor.size])
            (leaf "xcursor-theme" [config.stylix.cursor.name])
          ])
          (node "output" ["eDP-1"] [
            (leaf "scale" [2.0])
          ])
          (leaf "screenshot-path" ["~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"])
          # (plain-leaf "prefer-no-csd")
          (plain "layout" [
            (leaf "gaps" [4])
            (plain "focus-ring" [
              (plain-leaf "off")
            ])
            (plain "border" [
              (leaf "width" [4])
              (leaf "active-color" (colors.base0A ++ [255]))
              (leaf "inactive-color" (colors.base03 ++ [255]))
            ])
            (plain "preset-column-widths" [
              (only wide (leaf "proportion" [0.166667]))
              (only wide (leaf "proportion" [0.25]))
              (leaf "proportion" [0.333333])
              (leaf "proportion" [0.5])
              (leaf "proportion" [0.666667])
              (only wide (leaf "proportion" [0.75]))
              (only wide (leaf "proportion" [0.833333]))
            ])
            (plain "default-column-width" [
              (leaf "proportion" [0.333333])
            ])
          ])
          (plain "hotkey-overlay" [
            (plain-leaf "skip-at-startup")
          ])
          (let
            bind = keys: action: args:
              plain keys [
                (leaf action args)
              ];
            spawn = flip bind "spawn";
            simple = keys: action: bind keys action [];
          in
            plain "binds" [
              (spawn "Mod+T" ["foot"])
              (spawn "Mod+D" ["fuzzel"])
              (spawn "Mod+W" ["systemctl" "--user" "restart" "waybar.service"])
              (spawn "Mod+L" ["blurred-locker"])

              (spawn "XF86AudioRaiseVolume" ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"])
              (spawn "XF86AudioLowerVolume" ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"])
              (spawn "XF86AudioMute" ["wpctl" "toggle-mute" "@DEFAULT_AUDIO_SINK@"])

              (spawn "XF86MonBrightnessUp" ["brightnessctl" "set" "10%+"])
              (spawn "XF86MonBrightnessDown" ["brightnessctl" "set" "10%-"])

              (spawn "Mod+Q" ["close-window"])

              (binds {
                suffixes."Left" = "column-left";
                suffixes."Down" = "window-down";
                suffixes."Up" = "window-up";
                suffixes."Right" = "column-right";
                prefixes."Mod" = "focus";
                prefixes."Mod+Ctrl" = "move";
                prefixes."Mod+Shift" = "focus-monitor";
                prefixes."Mod+Shift+Ctrl" = "move-window-to-monitor";
                substitutions."monitor-column" = "monitor";
                substitutions."monitor-window" = "monitor";
              })

              (binds {
                suffixes."U" = "workspace-down";
                suffixes."I" = "workspace-up";
                prefixes."Mod" = "focus";
                prefixes."Mod+Ctrl" = "move-window-to";
                prefixes."Mod+Shift" = "move";
              })

              (binds {
                suffixes = builtins.listToAttrs (map (n: {
                  name = toString n;
                  value = ["workspace" n];
                }) (range 1 9));
                prefixes."Mod" = "focus";
                prefixes."Mod+Ctrl" = "move-window-to";
              })

              (simple "Mod+Comma" "consume-window-into-column")
              (simple "Mod+Period" "expel-window-from-column")

              (simple "Mod+R" "switch-preset-column-width")
              (simple "Mod+F" "maximize-column")
              (simple "Mod+Shift+F" "fullscreen-window")
              (simple "Mod+C" "center-column")

              (bind "Mod+Minus" "set-column-width" ["-10%"])
              (bind "Mod+Plus" "set-column-width" ["+10%"])

              (bind "Mod+Shift+Minus" "set-window-height" ["-10%"])
              (bind "Mod+Shift+Plus" "set-window-height" ["+10%"])

              (simple "Mod+Shift+S" "screenshot")

              (simple "Mod+Shift+E" "quit")
              (simple "Mod+Shift+P" "power-off-monitors")

              (simple "Mod+Shift+Ctrl+T" "toggle-debug-tint")
            ])
        ];
    };
in {
  shared.modules = [
    niri.nixosModules.niri
    ({pkgs, ...}: {
      programs.niri.enable = true;
      nixpkgs.overlays = [niri.overlays.niri];
      programs.niri.package = pkgs.niri-unstable;
      environment.variables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = with pkgs; [
        wl-clipboard
        wayland-utils
        libsecret
        cage
        gamescope
      ];
      # qt.enable = true;
      # qt.style = "adwaita-dark";
      # qt.platformTheme = "gnome";
    })
  ];

  shared.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        mako
        libnotify
      ];
      programs.foot = {
        enable = true;
        settings.csd.preferred = "none";
      };

      programs.fuzzel = {
        enable = true;
        settings.main.terminal = "foot";
      };
    })
  ];

  sodium.home_modules = [
    (niri_config {wide = true;})
  ];

  lithium.home_modules = [
    (niri_config {wide = false;})
  ];
}
