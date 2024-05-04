{niri, ...}: {
  shared.modules = [
    {
      boot.loader.systemd-boot = {
        enable = true;
        # netbootxyz.enable = true;
        consoleMode = "auto";
      };
      boot.loader.efi.canTouchEfiVariables = true;
    }
    ({
      lib,
      pkgs,
      config,
      ...
    }: {
      options.login.tuigreet-width.proportion = lib.mkOption {
        type = lib.types.float;
      };

      config = let
        home-config = config.home-manager.users.sodiboo;
        niri-cfg-modules = lib.evalModules {
          modules = [
            niri.lib.internal.settings-module
            (let
              cfg = home-config.programs.niri.settings;
            in {
              programs.niri.settings = {
                hotkey-overlay.skip-at-startup = true;

                input = cfg.input;
                cursor = cfg.cursor;
                outputs = cfg.outputs;

                layout =
                  cfg.layout
                  // {
                    center-focused-column = "always";
                    default-column-width.proportion = config.login.tuigreet-width.proportion;
                  };

                spawn-at-startup = [
                  {command = [(lib.getExe pkgs.swaybg) "-i" config.stylix.image];}
                  {command = [(lib.getExe pkgs.waybar) "-c" waybar-config "-s" waybar-style];}
                ];

                window-rules = [
                  {
                    # open-maximized = true;
                    draw-border-with-background = false;
                    clip-to-geometry = true;
                    geometry-corner-radius = {
                      top-left = 8.0;
                      top-right = 8.0;
                      bottom-left = 8.0;
                      bottom-right = 8.0;
                    };
                  }
                ];
              };
            })
          ];
        };

        niri-config = niri.lib.internal.validated-config-for pkgs config.programs.niri.package niri-cfg-modules.config.programs.niri.finalConfig;

        foot-config = toString home-config.xdg.configFile."foot/foot.ini".source;
        waybar-config = toString home-config.xdg.configFile."waybar/config".source;
        waybar-style = toString home-config.xdg.configFile."waybar/style.css".source;
      in {
        environment.systemPackages = [
          pkgs.greetd.tuigreet
        ];

        services.greetd = {
          enable = true;
          settings = {
            default_session = let
              niri = lib.getExe config.programs.niri.package;
              foot = lib.getExe pkgs.foot;
              tuigreet = lib.getExe pkgs.greetd.tuigreet;
            in {
              command = builtins.concatStringsSep " " [
                niri
                "-c"
                niri-config
                "--"
                foot
                "-c"
                foot-config
                (pkgs.writeScript "greet-cmd" ''
                  ${tuigreet} --remember --cmd niri-session
                  ${niri} msg action quit --skip-confirmation
                '')
              ];
              user = "greeter";
            };
          };
        };
        security.pam.services.greetd.enableGnomeKeyring = true;
      };
    })
  ];

  sodium.modules = [
    {
      login.tuigreet-width.proportion = 0.5;
    }
  ];

  lithium.modules = [
    {
      login.tuigreet-width.proportion = 1.0;
    }
  ];
}
