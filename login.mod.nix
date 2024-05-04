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
        services.greetd = {
          enable = true;
          settings = {
            default_session = let
              niri = lib.getExe config.programs.niri.package;
              niri-session = "${config.programs.niri.package}/bin/niri-session";
              foot = lib.getExe pkgs.foot;
              tuigreet = lib.getExe pkgs.greetd.tuigreet;
              systemctl = home-config.systemd.user.systemctlPath;
            in {
              command = builtins.concatStringsSep " " [
                niri
                "-c"
                niri-config
                "--"
                foot
                "-c"
                foot-config
                # absolutely disgusting nested script hack
                (pkgs.writeScript "greet-cmd" ''
                  # note: this part runs as greeter
                  ${tuigreet} --remember --cmd ${pkgs.writeScript "init-session" ''
                    # but this part is run as logged in user
                    # so here we're trying to stop a previous niri session
                    ${systemctl} --user is-active niri.service && ${systemctl} --user stop niri.service
                    # and then we start a new one
                    ${niri-session}
                  ''}
                  # this exits the greeter's niri (otherwise it hangs around for some seconds until greetd kills it)
                  ${niri} msg action quit --skip-confirmation
                  # only after this point does init-session run
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
