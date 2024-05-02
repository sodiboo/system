{
  niri,
  # niri-working-tree,
  ...
}: {
  shared.modules = [
    niri.nixosModules.niri
    ({pkgs, ...}: {
      programs.niri.enable = true;
      nixpkgs.overlays = [niri.overlays.niri];
      programs.niri.package = pkgs.niri-unstable;
      # programs.niri.package = pkgs.niri-unstable.override {src = niri-working-tree;};
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
    ({
      config,
      lib,
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
            tap = false;
            dwt = true;
            natural-scroll = true;
            click-method = "clickfinger";
          };

          input.tablet.map-to-output = "eDP-1";
          input.touch.map-to-output = "eDP-1";

          prefer-no-csd = true;

          layout = {
            gaps = 16;
            struts.left = 64;
            struts.right = 64;
            border.width = 4;
          };

          hotkey-overlay.skip-at-startup = true;

          spawn-at-startup = let
            cmds = map (unit: "systemctl --user restart ${unit}.service") config.systemd-fuckery.start-with-niri;
          in
            map (cmd: {command = ["sh" "-c" cmd];}) cmds;

          binds = with config.lib.niri.actions; let
            sh = spawn "sh" "-c";
          in
            lib.attrsets.mergeAttrsList [
              {
                "Mod+T".action = spawn "foot";
                "Mod+D".action = spawn "fuzzel";
                "Mod+W".action = sh (builtins.concatStringsSep "; " [
                  "systemctl --user restart waybar.service"
                  "systemctl --user restart swaybg.service"
                ]);
                "Mod+L".action = spawn "blurred-locker";

                "XF86AudioRaiseVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
                "XF86AudioLowerVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
                "XF86AudioMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

                "XF86MonBrightnessUp".action = sh "brightnessctl set 10%+";
                "XF86MonBrightnessDown".action = sh "brightnessctl set 10%-";

                "Mod+Q".action = close-window;

                "XF86AudioNext".action = focus-column-right;
                "XF86AudioPrev".action = focus-column-left;
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
                suffixes = builtins.listToAttrs (map (n: {
                  name = toString n;
                  value = ["workspace" n];
                }) (range 1 9));
                prefixes."Mod" = "focus";
                prefixes."Mod+Ctrl" = "move-window-to";
              })
              {
                "Mod+Comma".action = consume-window-into-column;
                "Mod+Period".action = expel-window-from-column;

                "Mod+R".action = switch-preset-column-width;
                "Mod+F".action = maximize-column;
                "Mod+Shift+F".action = fullscreen-window;
                "Mod+C".action = center-column;

                "Mod+Minus".action = set-column-width "-10%";
                "Mod+Plus".action = set-column-width "+10%";
                "Mod+Shift+Minus".action = set-window-height "-10%";
                "Mod+Shift+Plus".action = set-window-height "+10%";

                "Mod+Shift+S".action = sh ''grim -g "$(slurp)" - | wl-copy -t image/png'';
                "Mod+Print".action = screenshot-window;

                "Mod+Shift+E".action = quit;
                "Mod+Shift+P".action = power-off-monitors;

                "Mod+Shift+Ctrl+T".action = toggle-debug-tint;
              }
            ];

          # examples:

          # spawn-at-startup = [
          #   {command = ["alacritty"];}
          #   {command = ["waybar"];}
          #   {command = ["swww" "start"];}
          # ];

          animations.window-resize-shader = ''
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

          window-rules = [
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
              matches = [{app-id = "^foot$";}];
              opacity = 1.0;
            }
            {
              matches = [
                {
                  app-id = "^firefox$";
                  title = "Private Browsing";
                }
              ];
              border.active.color = "purple";
            }
          ];
        };
      })
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

  # alejandra gives up formatting these if you remove trailing zeros
  # i.e. can't do `1. / 3.` even though it's valid nix
  # but you know what's kinda messed up?
  # this issue was fixed! (commit 2022-07-29)
  # https://github.com/nix-community/rnix-parser/commit/fd1f0af8a3b0ea71ece5da8743cd14eee92e816b
  # this commit is part of v0.11.0 (released 2022-11-11)
  # the current date as i write this is 2024-03-01.
  # it's been 476 days, which github renders as "2 years ago" (?)
  # and alejandra still uses v0.10.2:
  # https://github.com/kamadorueda/alejandra/blob/e53c2c6c6c103dc3f848dbd9fbd93ee7c69c109f/src/alejandra/Cargo.toml#L2
  # this link is to a tree from the master branch right now (latest commit 2023-09-12)
  # nixpkgs-fmt also uses rnix, and it can format this file just fine.
  # what gives?
  # get this: nixpkgs-fmt **also** uses the outdated, incorrect rnix v0.10.2
  # https://github.com/nix-community/nixpkgs-fmt/blob/7301bc9f2ba29fe693c04cbcaa12110eb9685c71/Cargo.toml#L17
  # but why does it work? how can it format a file that it can't parse?
  # nixpkgs-fmt ignores syntax errors. in this way, it's more robust.
  # you can format files that are like, in the middle of being edited or such.
  # so what is its behaviour here? it treats the expression `1. / 3.` as an opaque span.
  # you can tell there's a difference, if you add newlines
  # ```
  # 1
  # /
  # 3
  # ```
  # will result in the following formatted file:
  # ```
  # 1
  #   /
  # 3
  # ```
  # but if we do it with floating point, like so:
  # ```
  # 1.
  # /
  # 3.
  # ```
  # the output is the same as input.
  #
  # why are both formatters running outdated parsers??
  # this issue was fixed over a year before the latest commit to both!!
  #
  #
  #
  # ... but you know what's REALLY fucked up?
  #
  # nixfmt is a completely separate project, which does not use rnix.
  # it's written in Haskell, with its own parser.
  # and **they too** have the same bug!
  #
  # no nix formatting tooling can format expressions like `1. / 3.`
  #
  # what??? that can't be right!
  #
  # and yeah, it's not!
  #
  # tree-sitter-nix got this correct in **the very first commit**:
  # https://github.com/nix-community/tree-sitter-nix/blob/1324e9e4125e070946d2573f4389634891dcd7e1/grammar.js#L49
  #
  # at least two formatters use this grammar to parse:
  #
  # justinwoo/format-nix:
  # i could not get format-nix to run. i tried. i really did.
  # the nix files included in the repo do not evaluate properly anymore.
  # and i also couldn't get it to run with current tooling
  # - npm hangs; bun misses a dependency(?)
  # but given that tree-sitter-nix was *always* correct,
  # one must imagine format-nix happy with this input
  #
  # hercules-ci/canonix:
  # canonix does not seem to care about formatting of divisions
  # but it is *not* because of floats.
  # `1/3` -> `1/3`, just as `1./3.` -> `1./3.`
  # though it does at least seem to understand them.
  # `[1.[]3.]` -> `[ 1. [] 3. ]`.
  # this preserves semantics, showing it understands how to parse it.
  #
  # both of these are abandoned.
  #
  # i could also find a formatter based on emacs lisp at taktoa/nix-format.
  # it seems to only like, match brackets? it only indents; but does not wrap lines.
  # it's not a very useful formatter, but at least it doesn't crash?
  #
  # how did the ABANDONED formatters get it right?
  # but the ones still in use are incapable of correctly parsing nix??
  sodium.home_modules = [
    {
      programs.niri.settings = {
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
      };
    }
  ];

  lithium.home_modules = [
    {
      programs.niri.settings = {
        layout = {
          preset-column-widths = [
            {proportion = 1.0 / 3.0;}
            {proportion = 1.0 / 2.0;}
            {proportion = 2.0 / 3.0;}
          ];
          default-column-width = {proportion = 1.0 / 3.0;};
        };

        # internal laptop display
        outputs."eDP-1".scale = 2.0;
        # a TV i sometimes use to display stuff
        outputs."DP-2".scale = 2.0;
        # nested niri window for development should match
        outputs.winit.scale = 2.0;
      };
    }
  ];
}
