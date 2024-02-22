{
  niri,
  nixpkgs,
  ...
}: let
  niri_config = {wide}: {
    config,
    lib,
    ...
  }: let
    only = cond: text:
      if cond
      then text
      else "/* ${text} */";
    binds = with lib;
      {
        suffixes,
        prefixes,
        substitutions ? {},
      }: let
        format = prefix: suffix: "${prefix.key}+${suffix.key} { ${prefix.action}-${suffix.action}; }";
        pairs = attrs: fn:
          concatMap (key:
            fn {
              inherit key;
              action = attrs.${key};
            }) (attrNames attrs);
        list = pairs prefixes (prefix: pairs suffixes (suffix: [(format prefix suffix)]));
        string = concatStringsSep "\n" list;
      in
        replaceStrings (attrNames substitutions) (attrValues substitutions) string;
  in {
    programs.niri.config = ''
      input {
          keyboard { xkb { layout "${config.locale.keyboard_layout}"; }; }
          mouse { accel-speed 1.0; }
          touchpad { tap; natural-scroll; }
      }
      cursor { xcursor-size 24; }
      output "eDP-1" { scale 2.0; }

      screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"
      // Fucking vscode breaks with this enabled.
      // prefer-no-csd

      layout {
          gaps 16
          focus-ring {
              width 4
              active-color 127 200 255 255
              inactive-color 80 80 80 255
          }

          preset-column-widths {
              ${only wide "proportion 0.1667"}
              ${only wide "proportion 0.25"}
              proportion 0.3333
              proportion 0.5
              proportion 0.6667
              ${only wide "proportion 0.75"}
              ${only wide "proportion 0.8333"}
          }
          default-column-width { proportion 0.3333; }
      }

      hotkey-overlay {
        skip-at-startup
      }

      binds {
          Mod+T { spawn "foot"; }
          Mod+D { spawn "fuzzel"; }
          Mod+Alt+W { spawn "systemctl" "--user" "restart" "waybar.service"; }
          Mod+Alt+L { spawn "blurred-locker"; }

          XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
          XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
          XF86AudioMute { spawn "wpctl" "toggle-mute" "@DEFAULT_AUDIO_SINK@"; }

          XF86MonBrightnessUp { spawn "brightnessctl" "set" "10%+"; }
          XF86MonBrightnessDown { spawn "brightnessctl" "set" "10%-"; }

          Mod+Q { close-window; }

      ${binds {
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
      }}


      ${binds {
        suffixes."U" = "workspace-down";
        suffixes."I" = "workspace-up";
        prefixes."Mod" = "focus";
        prefixes."Mod+Ctrl" = "move-window-to";
        prefixes."Mod+Shift" = "move";
      }}


      ${binds {
        suffixes = builtins.listToAttrs (map (n: {
          name = n;
          value = "workspace ${n}";
        }) (map toString (nixpkgs.lib.range 1 9)));
        prefixes."Mod" = "focus";
        prefixes."Mod+Ctrl" = "move-window-to";
      }}

          Mod+Comma  { consume-window-into-column; }
          Mod+Period { expel-window-from-column; }

          Mod+R { switch-preset-column-width; }
          Mod+F { maximize-column; }
          Mod+Shift+F { fullscreen-window; }
          Mod+C { center-column; }

          Mod+Minus { set-column-width "-10%"; }
          Mod+Plus { set-column-width "+10%"; }

          Mod+Shift+Minus { set-window-height "-10%"; }
          Mod+Shift+Plus { set-window-height "+10%"; }

          Mod+Shift+S { screenshot; }

          Mod+Shift+E { quit; }
          Mod+Shift+P { power-off-monitors; }

          Mod+Shift+Ctrl+T { toggle-debug-tint; }
      }
    '';
  };
in {
  shared.modules = [
    niri.nixosModules.niri
    ({pkgs, ...}: {
      programs.niri.enable = true;
      programs.niri.package = niri.packages.${pkgs.stdenv.system}.niri-unstable;
      programs.niri.acknowledge-warning.will-use-nixpkgs = true;
      environment.variables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = with pkgs; [
        wl-clipboard
        wayland-utils
        libsecret
        cage
        gamescope
      ];
      qt.enable = true;
      qt.style = "adwaita-dark";
      qt.platformTheme = "gnome";
    })
  ];

  shared.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        foot
        mako
        libnotify
        fuzzel
      ];
      # dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    })
  ];

  sodium.home_modules = [
    (niri_config {wide = true;})
  ];

  lithium.home_modules = [
    (niri_config {wide = false;})
  ];
}
