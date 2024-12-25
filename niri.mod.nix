{
  niri,
  niri-working-tree,
  niri-floating,
  ...
}: {
  # enable the binary cache on all systems; useful for remote build
  universal.modules = [niri.nixosModules.niri];
  personal.modules = [
    ({pkgs, ...}: {
      programs.niri.enable = true;
      nixpkgs.overlays = [niri.overlays.niri];
      # programs.niri.package = pkgs.niri-unstable;
      programs.niri.package = let
        niri-sodi = pkgs.niri-unstable.override {src = niri-working-tree;};
        niri-float = pkgs.niri-unstable.override {src = niri-floating;};
      in
        # my niri amalgam package mess.
        # i have a branch with some additions that i use.
        # but i also wanna use the floating branch.
        # but i don't have time to merge them.
        # so, i'm installing both.
        # `niri-floating` binary will be the floating branch; and it will be the default session.
        # but the `niri` binary will be my branch.
        pkgs.runCommand "niri-amalgam" {
          passthru = {
            inherit (niri-sodi) src cargoBuildNoDefaultFeatures cargoBuildFeatures providedSessions;
          };
        } ''
          cp -R ${niri-sodi} $out
          chmod -R +w $out

          ln -s ${niri-float}/bin/niri $out/bin/niri-floating

          substituteInPlace $out/lib/systemd/user/niri.service --replace-fail ${niri-sodi}/bin/niri $out/bin/niri-floating
        '';
      environment.variables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = with pkgs; [
        wl-clipboard
        wayland-utils
        libsecret
        cage
        gamescope
        xwayland-satellite-unstable
        swaybg
      ];
    })
  ];

  personal.home_modules = [
    ({
      lib,
      nixosConfig,
      config,
      pkgs,
      ...
    }:
      with lib; let
        binds = {
          suffixes,
          prefixes,
          substitutions ? {},
        }: let
          replacer = replaceStrings (attrNames substitutions) (attrValues substitutions);
          format = prefix: suffix: let
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

            action = replacer "${prefix.action}-${actual-suffix.action}";
          in {
            name = "${prefix.key}+${suffix.key}";
            value.action.${action} = actual-suffix.args;
          };
          pairs = attrs: fn:
            concatMap (key:
              fn {
                inherit key;
                action = attrs.${key};
              }) (attrNames attrs);
        in
          listToAttrs (pairs prefixes (prefix: pairs suffixes (suffix: [(format prefix suffix)])));
      in {
        programs.niri.settings = {
          input.keyboard.xkb.layout = "no";
          input.mouse.accel-speed = 1.0;
          input.touchpad = {
            tap = true;
            dwt = true;
            natural-scroll = true;
            click-method = "clickfinger";
          };

          input.tablet.map-to-output = "eDP-1";
          input.touch.map-to-output = "eDP-1";

          # input.warp-mouse-to-focus = true;

          prefer-no-csd = true;

          layout = {
            gaps = 16;
            struts.left = 64;
            struts.right = 64;
            border.width = 4;
            always-center-single-column = true;

            # fog of war
            focus-ring = {
              # enable = true;
              width = 10000;
              active.color = "#00000055";
            };
            # border.active.gradient = {
            #   from = "red";
            #   to = "blue";
            #   in' = "oklch shorter hue";
            # };
          };

          hotkey-overlay.skip-at-startup = !nixosConfig.is-virtual-machine;

          screenshot-path = "~/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S.png";

          switch-events = with config.lib.niri.actions; let
            sh = spawn "sh" "-c";
          in {
            tablet-mode-on.action = sh "notify-send tablet-mode-on";
            tablet-mode-off.action = sh "notify-send tablet-mode-off";
            lid-open.action = sh "notify-send lid-open";
            lid-close.action = sh "notify-send lid-close";
          };

          binds = with config.lib.niri.actions; let
            sh = spawn "sh" "-c";
            # screenshot-area-script = pkgs.writeShellScript "screenshot-area" ''
            #   grim -o $(niri msg --json focused-output | jq -r .name) - | swayimg --config=info.mode=off --fullscreen - &
            #   SWAYIMG=$!
            #   niri msg action do-screen-transition -d 1200
            #   sleep 1.2
            #   grim -g "$(slurp)" - | wl-copy -t image/png
            #   niri msg action do-screen-transition
            #   kill $SWAYIMG
            # '';
            # screenshot-area = spawn "${screenshot-area-script}";

            # a VM is semantically a nested session; so use the Alt key.
            # but on a physical machine, use Mod which is Super unless nested.
            Mod =
              # NOTE: Are you here just to reference my niri config?
              # This isn't a standard option, see `./vm.mod.nix` for the definition.
              # If you want to just copy my binds, you likely want "Mod" instead of "${Mod}"
              if nixosConfig.is-virtual-machine
              then "Alt"
              else "Mod";
          in
            lib.attrsets.mergeAttrsList [
              {
                "${Mod}+T".action = spawn "kitty";
                "${Mod}+D".action = spawn "fuzzel";
                "${Mod}+W".action = sh (builtins.concatStringsSep "; " [
                  "systemctl --user restart waybar.service"
                  "systemctl --user restart swaybg.service"
                ]);

                "${Mod}+L".action = spawn "blurred-locker";

                "${Mod}+Shift+S".action = screenshot;
                "Print".action = screenshot-screen;
                "${Mod}+Print".action = screenshot-window;

                "XF86AudioRaiseVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
                "XF86AudioLowerVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
                "XF86AudioMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

                "XF86MonBrightnessUp".action = sh "brightnessctl set 10%+";
                "XF86MonBrightnessDown".action = sh "brightnessctl set 10%-";

                "${Mod}+Q".action = close-window;

                "XF86AudioNext".action = focus-column-right;
                "XF86AudioPrev".action = focus-column-left;

                "${Mod}+Tab".action = focus-window-down-or-column-right;
                "${Mod}+Shift+Tab".action = focus-window-up-or-column-left;
              }
              (binds {
                suffixes."Left" = "column-left";
                suffixes."Down" = "window-down";
                suffixes."Up" = "window-up";
                suffixes."Right" = "column-right";
                prefixes."${Mod}" = "focus";
                prefixes."${Mod}+Ctrl" = "move";
                prefixes."${Mod}+Shift" = "focus-monitor";
                prefixes."${Mod}+Shift+Ctrl" = "move-window-to-monitor";
                substitutions."monitor-column" = "monitor";
                substitutions."monitor-window" = "monitor";
              })
              (binds {
                suffixes."Home" = "first";
                suffixes."End" = "last";
                prefixes."${Mod}" = "focus-column";
                prefixes."${Mod}+Ctrl" = "move-column-to";
              })
              (binds {
                suffixes."U" = "workspace-down";
                suffixes."I" = "workspace-up";
                prefixes."${Mod}" = "focus";
                prefixes."${Mod}+Ctrl" = "move-window-to";
                prefixes."${Mod}+Shift" = "move";
              })
              (binds {
                suffixes = builtins.listToAttrs (map (n: {
                  name = toString n;
                  value = ["workspace" n];
                }) (range 1 9));
                prefixes."${Mod}" = "focus";
                prefixes."${Mod}+Ctrl" = "move-window-to";
              })
              {
                "${Mod}+Comma".action = consume-window-into-column;
                "${Mod}+Period".action = expel-window-from-column;

                "${Mod}+R".action = switch-preset-column-width;
                "${Mod}+F".action = maximize-column;
                "${Mod}+Shift+F".action = fullscreen-window;
                "${Mod}+C".action = center-column;

                "${Mod}+Minus".action = set-column-width "-10%";
                "${Mod}+Plus".action = set-column-width "+10%";
                "${Mod}+Shift+Minus".action = set-window-height "-10%";
                "${Mod}+Shift+Plus".action = set-window-height "+10%";

                "${Mod}+Shift+E".action = quit;
                "${Mod}+Shift+P".action = power-off-monitors;

                "${Mod}+Shift+Ctrl+T".action = toggle-debug-tint;
              }
            ];

          spawn-at-startup = let
            get-wayland-display = "systemctl --user show-environment | awk -F 'WAYLAND_DISPLAY=' '{print $2}' | awk NF";
            wrapper = name: op:
              pkgs.writeScript "${name}" ''
                if [ "$(${get-wayland-display})" ${op} "$WAYLAND_DISPLAY" ]; then
                  exec "$@"
                fi
              '';

            only-on-session = wrapper "only-on-session" "=";
            only-without-session = wrapper "only-without-session" "!=";

            modulated-wallpaper = pkgs.runCommand "modulated-wallpaper.png" {} ''
              ${lib.getExe pkgs.imagemagick} ${config.stylix.image} -modulate 100,100,14 $out
            '';
          in [
            {
              command = [
                "${only-on-session}"
                "${lib.getExe pkgs.gammastep}"
                "-l"
                "59:11" # lol, doxxed
              ];
            }
            {
              command = [
                "${only-without-session}"
                "${lib.getExe pkgs.waybar}"
              ];
            }
            {
              command = [
                "${only-without-session}"
                "${lib.getExe pkgs.swaybg}"
                "-m"
                "fill"
                "-i"
                "${modulated-wallpaper}"
              ];
            }
            {
              command = let
                units = [
                  "niri"
                  "graphical-session.target"
                  "xdg-desktop-portal"
                  "xdg-desktop-portal-gnome"
                  "waybar"
                ];
                commands = builtins.concatStringsSep ";" (map (unit: "systemctl --user status ${unit}") units);
              in ["${only-on-session}" "kitty" "--" "sh" "-c" "env SYSTEMD_COLORS=1 watch -n 1 -d --color '${commands}'"];
            }
            {
              command = ["${only-without-session}" "kitty" "--" "sh" "-c" "${lib.getExe pkgs.wayvnc} -L=debug"];
            }
          ];

          animations.shaders.window-resize = ''
            vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
                vec3 coords_next_geo = niri_curr_geo_to_next_geo * coords_curr_geo;

                vec3 coords_stretch = niri_geo_to_tex_next * coords_curr_geo;
                vec3 coords_crop = niri_geo_to_tex_next * coords_next_geo;

                // We can crop if the current window size is smaller than the next window
                // size. One way to tell is by comparing to 1.0 the X and Y scaling
                // coefficients in the current-to-next transformation matrix.
                bool can_crop_by_x = niri_curr_geo_to_next_geo[0][0] <= 1.0;
                bool can_crop_by_y = niri_curr_geo_to_next_geo[1][1] <= 1.0;

                vec3 coords = coords_stretch;
                if (can_crop_by_x)
                    coords.x = coords_crop.x;
                if (can_crop_by_y)
                    coords.y = coords_crop.y;

                vec4 color = texture2D(niri_tex_next, coords.st);

                // However, when we crop, we also want to crop out anything outside the
                // current geometry. This is because the area of the shader is unspecified
                // and usually bigger than the current geometry, so if we don't fill pixels
                // outside with transparency, the texture will leak out.
                //
                // When stretching, this is not an issue because the area outside will
                // correspond to client-side decoration shadows, which are already supposed
                // to be outside.
                if (can_crop_by_x && (coords_curr_geo.x < 0.0 || 1.0 < coords_curr_geo.x))
                    color = vec4(0.0);
                if (can_crop_by_y && (coords_curr_geo.y < 0.0 || 1.0 < coords_curr_geo.y))
                    color = vec4(0.0);

                return color;
            }
          '';

          window-rules = let
            colors = config.lib.stylix.colors.withHashtag;
          in [
            {
              draw-border-with-background = false;
              geometry-corner-radius = let
                r = 8.0;
              in {
                top-left = r;
                top-right = r;
                bottom-left = r;
                bottom-right = r;
              };
              clip-to-geometry = true;
            }
            {
              matches = [{is-focused = false;}];
              opacity = 0.95;
            }
            {
              # the terminal is already transparent from stylix
              matches = [{app-id = "^kitty$";}];
              opacity = 1.0;
            }
            {
              matches = [{app-id = "^niri$";}];
              opacity = 1.0;
            }
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
          ];
        };
      })
    ({pkgs, ...}: {
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
    })
  ];

  # i would like to format these as `1. / 3.` but can't
  # because alejandra no likey.
  # https://sodi.boo/blog/nix-formatting
  sodium.home_modules = [
    ({config, ...}: {
      programs.niri.settings = {
        # On sodium, right super says "menu" and is between right alt and fn
        input.keyboard.xkb.options = "compose:rwin";
        layout = {
          preset-column-widths = [
            {proportion = 1.0 / 6.0;}
            {proportion = 1.0 / 4.0;}
            {proportion = 1.0 / 3.0;}
            {proportion = 1.0 / 2.0;}
            {proportion = 2.0 / 3.0;}
            {proportion = 3.0 / 4.0;}
            {proportion = 5.0 / 6.0;}
          ];
          default-column-width = {proportion = 1.0 / 3.0;};
        };

        outputs = let
          cfg = config.programs.niri.settings.outputs;
        in {
          "HDMI-A-1" = {
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
    })
  ];

  nitrogen.home_modules = [
    {
      programs.niri.settings = {
        input.keyboard.xkb.options = "compose:rctrl";
        layout = {
          preset-column-widths = [
            {proportion = 1.0 / 3.0;}
            {proportion = 1.0 / 2.0;}
            {proportion = 2.0 / 3.0;}
          ];
          default-column-width = {proportion = 1.0 / 3.0;};
        };

        # internal laptop display
        outputs."eDP-1".scale = 1.5;
        # a TV i sometimes use to display stuff
        outputs."DP-2".scale = 2.0;
        # nested niri window for development should match
        outputs.winit.scale = 1.5;
      };
    }
  ];
}
