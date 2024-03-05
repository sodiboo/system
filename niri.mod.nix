{
  niri,
  ...
}: {
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
    niri.homeModules.experimental-settings
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
            value.${action} = actual-suffix.args;
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
        programs.niri.settings = let
          colors = config.lib.stylix.colors.withHashtag;
        in {
          input.keyboard.xkb.layout = "no";
          input.mouse.accel-speed = 1.0;
          input.touchpad = {
            tap = true;
            dwt = true;
            natural-scroll = true;
          };
          input.tablet.map-to-output = "eDP-1";
          input.touch.map-to-output = "eDP-1";
          cursor.size = config.stylix.cursor.size;
          cursor.theme = config.stylix.cursor.name;

          outputs."eDP-1".scale = 2.0;
          outputs.winit.scale = 2.0;

          layout = {
            gaps = 4;
            struts.left = 64;
            struts.right = 64;
            focus-ring.enable = false;
            border = {
              enable = true;
              width = 4;
              active-color = colors.base0A;
              inactive-color = colors.base03;
            };
          };

          hotkey-overlay.skip-at-startup = true;

          binds = with niri.kdl;
            lib.attrsets.mergeAttrsList [
              {
                "Mod+T".spawn = "foot";
                "Mod+D".spawn = "fuzzel";
                "Mod+W".spawn = ["systemctl" "--user" "restart" "waybar.service"];
                "Mod+L".spawn = "blurred-locker";

                "XF86AudioRaiseVolume".spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"];
                "XF86AudioLowerVolume".spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"];
                "XF86AudioMute".spawn = ["wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"];

                "XF86MonBrightnessUp".spawn = ["brightnessctl" "set" "10%+"];
                "XF86MonBrightnessDown".spawn = ["brightnessctl" "set" "10%-"];

                "Mod+Q".close-window = [];
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
                "Mod+Comma".consume-window-into-column = [];
                "Mod+Period".expel-window-from-column = [];

                "Mod+R".switch-preset-column-width = [];
                "Mod+F".maximize-column = [];
                "Mod+Shift+F".fullscreen-window = [];
                "Mod+C".center-column = [];

                "Mod+Minus".set-column-width = "-10%";
                "Mod+Plus".set-column-width = "+10%";
                "Mod+Shift+Minus".set-window-height = "-10%";
                "Mod+Shift+Plus".set-window-height = "+10%";

                "Mod+Shift+S".screenshot = [];

                "Mod+Shift+E".quit = [];
                "Mod+Shift+P".power-off-monitors = [];

                "Mod+Shift+Ctrl+T".toggle-debug-tint = [];
              }
            ];

          # examples:

          # spawn-at-startup = [
          #   {command = ["alacritty"];}
          #   {command = ["waybar"];}
          #   {command = ["swww" "start"];}
          # ];

          # window-rules = [
          #   {
          #     matches = [{app-id = ''^org\.wezfurlong\.wezterm$'';}];
          #     default-column-width = {};
          #     open-fullscreen = true;
          #     open-on-output = "eDP-1";
          #   }
          # ];
        };

        programs.niri.config = config.programs.niri.generated-kdl-config;
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
      programs.niri.settings.layout = {
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
    }
  ];

  lithium.home_modules = [
    {
      programs.niri.settings.layout = {
        preset-column-widths = [
          {proportion = 1.0 / 3.0;}
          {proportion = 1.0 / 2.0;}
          {proportion = 2.0 / 3.0;}
        ];
        default-column-width = {proportion = 1.0 / 3.0;};
      };
    }
  ];
}
