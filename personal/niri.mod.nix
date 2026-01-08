{ niri-flake, ... }:
{
  # enable the binary cache on all systems; useful for remote builds
  universal.imports = [ "${niri-flake}/modules/binary-cache.nix" ];
  personal =
    { lib, pkgs, ... }:
    {
      imports = [
        {
          options.programs.niri.settings = lib.mkOption {
            type = niri-flake.lib.settings.make-type {
              inherit lib pkgs;
              modules = [ { _module.filename = "base-config.kdl"; } ];
            };
            default = { };
          };
        }
        "${niri-flake}/modules/experimental/stylix.nix"
      ];
      programs.niri.enable = true;
      nixpkgs.overlays = [ niri-flake.overlays.niri ];
      programs.niri.package = pkgs.niri-unstable;
      environment.variables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = with pkgs; [
        wl-clipboard
        wayland-utils
        libsecret
        cage
        gamescope
        xwayland-satellite-unstable
      ];

      security.soteria.enable = true;

      programs.niri.settings = {
        input.keyboard.xkb.layout = "no";
        input.mouse.accel-speed = 1.0;
        input.touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
          click-method = "clickfinger";
        };

        # input.mouse.scroll-factor = 3;

        # config-notification.disable-failed = true;

        clipboard.disable-primary = true;

        prefer-no-csd = true;

        layout = {
          gaps = 16;
          struts.left = 64;
          struts.right = 64;

          always-center-single-column = true;

          empty-workspace-above-first = true;

          # fog of war
          focus-ring = {
            enable = false;
            width = 10000;
            active.color = "#00000055";
          };

          border = {
            enable = true;
            width = 4;
          };

          # border.active.gradient = {
          #   from = "red";
          #   to = "blue";
          #   in' = "oklch shorter hue";
          # };

          shadow.enable = true;

          # default-column-display = "tabbed";

          tab-indicator = {
            position = "top";
            gaps-between-tabs = 10;

            # hide-when-single-tab = true;
            # place-within-column = true;

            # active.color = "red";
          };
        };

        overview.zoom = 0.5;

        animations.window-resize.custom-shader = builtins.readFile ./resize.glsl;

        window-rules = [
          {
            draw-border-with-background = false;
            geometry-corner-radius =
              let
                r = 8.0;
              in
              {
                top-left = r;
                top-right = r;
                bottom-left = r;
                bottom-right = r;
              };
            clip-to-geometry = true;
          }
        ];

        xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite-unstable}";
      };

      home-shortcut.imports = [
        (
          { nixosConfig, ... }:
          {
            imports = [ "${niri-flake}/modules/experimental/home-manager/settings.nix" ];
            programs.niri.enable = true;
            programs.niri.settings-validation-package = nixosConfig.programs.niri.package;
          }
        )
        (
          {
            lib,
            nixosConfig,
            config,
            pkgs,
            ...
          }:
          let
            binds =
              {
                suffixes,
                prefixes,
                substitutions ? { },
              }:
              let
                replacer = lib.replaceStrings (builtins.attrNames substitutions) (
                  builtins.attrValues substitutions
                );
                format =
                  prefix: suffix:
                  let
                    actual-suffix =
                      if lib.isList suffix.action then
                        {
                          action = lib.head suffix.action;
                          args = lib.tail suffix.action;
                        }
                      else
                        {
                          inherit (suffix) action;
                          args = [ ];
                        };

                    action = replacer "${prefix.action}-${actual-suffix.action}";
                  in
                  {
                    name = "${prefix.key}+${suffix.key}";
                    value.action.${action} = actual-suffix.args;
                  };
                pairs =
                  attrs: fn:
                  builtins.concatMap (
                    key:
                    fn {
                      inherit key;
                      action = attrs.${key};
                    }
                  ) (builtins.attrNames attrs);
              in
              builtins.listToAttrs (pairs prefixes (prefix: pairs suffixes (suffix: [ (format prefix suffix) ])));
          in
          {
            programs.niri.settings = {
              includes = [ "${nixosConfig.programs.niri.settings}" ];

              hotkey-overlay.skip-at-startup = !nixosConfig.is-virtual-machine;

              screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";

              switch-events =
                let
                  sh = cmd: {
                    spawn = [
                      "sh"
                      "-c"
                      cmd
                    ];
                  };
                in
                {
                  tablet-mode-on.action = sh "notify-send tablet-mode-on";
                  tablet-mode-off.action = sh "notify-send tablet-mode-off";
                  lid-open.action = sh "notify-send lid-open";
                  lid-close.action = sh "notify-send lid-close";
                };

              binds = lib.attrsets.mergeAttrsList [
                {
                  "Mod+T".action.spawn = "kitty";
                  "Mod+O".action.show-hotkey-overlay = [ ];
                  "Mod+D".action.spawn = "fuzzel";
                  # "Mod+W".action = sh (
                  #   builtins.concatStringsSep "; " [
                  #     "systemctl --user restart waybar.service"
                  #   ]
                  # );

                  "Mod+L".action.spawn = "blurred-locker";

                  "Mod+Shift+S".action.screenshot = [ ];
                  "Print".action.screenshot-screen = [ ];
                  "Mod+Print".action.screenshot-window = [ ];

                  "Mod+Insert".action.set-dynamic-cast-window = [ ];
                  "Mod+Shift+Insert".action.set-dynamic-cast-monitor = [ ];
                  "Mod+Delete".action.clear-dynamic-cast-target = [ ];

                  "XF86AudioRaiseVolume".action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
                  "XF86AudioLowerVolume".action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
                  "XF86AudioMute".action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

                  "XF86MonBrightnessUp".action.spawn-sh = "brightnessctl set 10%+";
                  # "XF86MonBrightnessUp".hotkey-overlay.title = "awawa";
                  "XF86MonBrightnessDown".action.spawn-sh = "brightnessctl set 10%-";
                  # "XF86MonBrightnessDown".hotkey-overlay.hidden = true;

                  "Mod+Q".action.close-window = [ ];

                  "Mod+Space".action.toggle-column-tabbed-display = [ ];

                  "XF86AudioNext".action.focus-column-right = [ ];
                  "XF86AudioPrev".action.focus-column-left = [ ];

                  "Mod+Tab".action.focus-window-down-or-column-right = [ ];
                  "Mod+Shift+Tab".action.focus-window-up-or-column-left = [ ];
                }
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
                {
                  "Mod+V".action.switch-focus-between-floating-and-tiling = [ ];
                  "Mod+Shift+V".action.toggle-window-floating = [ ];
                }
                (binds {
                  suffixes."Home" = "first";
                  suffixes."End" = "last";
                  prefixes."Mod" = "focus-column";
                  prefixes."Mod+Ctrl" = "move-column-to";
                })
                (binds {
                  suffixes."U" = "workspace-down";
                  suffixes."I" = "workspace-up";
                  prefixes."Mod" = "focus";
                  prefixes."Mod+Ctrl" = "move-window-to";
                  prefixes."Mod+Shift" = "move";
                })
                (binds {
                  suffixes = builtins.listToAttrs (
                    map (n: {
                      name = toString n;
                      value = [
                        "workspace"
                        (n + 1)
                      ]; # workspace 1 is empty; workspace 2 is the logical first.
                    }) (lib.range 1 9)
                  );
                  prefixes."Mod" = "focus";
                  prefixes."Mod+Ctrl" = "move-window-to";
                })
                {
                  "Mod+Comma".action.consume-window-into-column = [ ];
                  "Mod+Period".action.expel-window-from-column = [ ];

                  "Mod+R".action.switch-preset-column-width = [ ];
                  "Mod+F".action.maximize-column = [ ];
                  "Mod+Shift+F".action.fullscreen-window = [ ];
                  "Mod+C".action.center-column = [ ];

                  "Mod+Minus".action.set-column-width = "-10%";
                  "Mod+Plus".action.set-column-width = "+10%";
                  "Mod+Shift+Minus".action.set-window-height = "-10%";
                  "Mod+Shift+Plus".action.set-window-height = "+10%";

                  "Mod+Shift+Escape".action.toggle-keyboard-shortcuts-inhibit = [ ];
                  "Mod+Shift+E".action.quit = [ ];
                  "Mod+Shift+P".action.power-off-monitors = [ ];

                  "Mod+Shift+Ctrl+T".action.toggle-debug-tint = [ ];
                }
              ];

              window-rules =
                let
                  colors = config.lib.stylix.colors.withHashtag;
                in
                [
                  {
                    matches = [
                      {
                        app-id = "^kitty$";
                        title = ''^\[oxygen\]'';
                      }
                    ];
                    border.active.color = colors.base0B;
                  }
                  {
                    matches = [
                      {
                        app-id = "^firefox$";
                        title = "Private Browsing";
                      }
                    ];
                    border.active.color = colors.base0E;
                  }
                  {
                    matches = [
                      {
                        app-id = "^signal$";
                      }
                    ];
                    block-out-from = "screencast";
                  }
                  {
                    matches = [
                      {
                        app-id = "^signal$";
                        title = "^Sharing screen$";
                        # their window isn't floating when it's created? ugh
                        # is-floating = true;
                      }
                    ];

                    border.inactive.color = "red";

                    open-focused = false;
                    open-floating = true;
                    default-floating-position = {
                      relative-to = "bottom";
                      x = 0;
                      y = -60;
                    };
                  }
                ];

              gestures.dnd-edge-view-scroll = {
                trigger-width = 64;
                delay-ms = 250;
                max-speed = 12000;
              };

              layer-rules = [
                {
                  matches = [ { namespace = "^swaync-notification-window$"; } ];

                  block-out-from = "screencast";
                }
                {
                  matches = [ { namespace = "^swww-daemonoverview$"; } ];

                  place-within-backdrop = true;
                }
              ];
            };
          }
        )
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              libnotify
            ];
            programs.foot = {
              enable = true;
              settings.csd.preferred = "none";
            };

            programs.alacritty = {
              enable = true;
              settings = {
                window.decorations = "None";
              };
            };

            programs.kitty = {
              enable = true;
              settings = {
                window_border_width = "0px";
                tab_bar_edge = "top";
                tab_bar_margin_width = "0.0";
                tab_bar_style = "fade";
                placement_strategy = "top-left";
                hide_window_decorations = true;
              };
            };

            programs.fuzzel = {
              enable = true;
              settings.main.launch-prefix = "niri msg action spawn --";
              settings.main.terminal = "foot";
            };

            # services.mako = {
            #   enable = true;
            #   borderRadius = 8;
            #   format = "%a\n%s\n%b";
            # };

            services.swaync = {
              enable = true;
            };
          }
        )
      ];
    };
  sodium =
    { config, ... }:
    {
      programs.niri.settings = {
        # On sodium, right super says "menu" and is between right alt and fn
        input.keyboard.xkb.options = "compose:rwin";

        outputs =
          let
            cfg = config.programs.niri.settings.outputs;
          in
          {
            "HDMI-A-1" = {
              enable = false;
              mode.width = 3840;
              mode.height = 2160;
              mode.refresh = 60.0;
              position.x = 0;
              position.y = -cfg."HDMI-A-1".mode.height;
            };
            "DP-1" = {
              mode.width = 5120;
              mode.height = 1440;
              position.x = 0;
              position.y = 0;
            };
          };
      };

      home-shortcut =
        {
          nixosConfig,
          config,
          pkgs,
          lib,
          ...
        }:
        {
          programs.niri.settings = {
            layout = {
              preset-column-widths = [

                # i would like to format these as `1. / 3.` but can't
                # because alejandra no likey.
                # https://sodi.boo/blog/nix-formatting
                { proportion = 1.0 / 6.0; }
                { proportion = 1.0 / 4.0; }
                { proportion = 1.0 / 3.0; }
                { proportion = 1.0 / 2.0; }
                { proportion = 2.0 / 3.0; }
                { proportion = 3.0 / 4.0; }
                { proportion = 5.0 / 6.0; }
              ];
              default-column-width = {
                proportion = 1.0 / 3.0;
              };
            };

            binds = lib.optionalAttrs (!nixosConfig.is-virtual-machine) {
              "Mod+Pause".action.spawn = "${pkgs.writeShellScript "toggle-hdmi-output" ''
                if [ "$(niri msg --json outputs | jq '."HDMI-A-1".logical == null')" = "true" ]; then
                  niri msg output HDMI-A-1 on
                else
                  niri msg output HDMI-A-1 off
                fi
              ''}";
              "Mod+Prior".action.set-dynamic-cast-monitor = "HDMI-A-1"; # page up; monitor is "up"
              "Mod+Next".action.set-dynamic-cast-monitor = "DP-1"; # page down; monitor is "down"
            };
          };
        };
    };

  nitrogen = {
    programs.niri.settings = {
      input.keyboard.xkb.options = "compose:rctrl";

      input.tablet.map-to-output = "eDP-1";
      input.touch.map-to-output = "eDP-1";

      # internal laptop display
      outputs."eDP-1".scale = 1.5;
      # a TV i sometimes use to display stuff
      outputs."DP-2".scale = 2.0;
      # nested niri window for development should match
      outputs.winit.scale = 1.5;
    };

    home-shortcut = {
      programs.niri.settings = {
        layout = {
          preset-column-widths = [
            { proportion = 1.0 / 3.0; }
            { proportion = 1.0 / 2.0; }
            { proportion = 2.0 / 3.0; }
          ];
          default-column-width = {
            proportion = 1.0 / 3.0;
          };
        };
      };
    };
  };
}
