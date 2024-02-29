{niri, ...}: let
  niri_config = {wide}: {
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

        outputs."eDP-1" = {
          scale = 2.0;
        };

        layout = {
          gaps = 4;
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
              "XF86AudioMute".spawn = ["wpctl" "toggle-mute" "@DEFAULT_AUDIO_SINK@"];

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
    niri.homeModules.experimental-settings
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
  sodium.home_modules = [
    (niri_config {wide = true;})
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
    (niri_config {wide = false;})

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
