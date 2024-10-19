{niri, ...}: {
  personal.modules = [
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
                  {command = [(lib.getExe pkgs.swaybg) "-i" config.stylix.blurred-image];}
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
              # These are like that, because we want to use the currently-installed versions.
              # If they are store paths, they might get outdated.
              # This mainly concerns high-uptime usage.
              # That's because greetd doesn't restart when system services are restarted.
              # So you get new versions of mesa, new niri to match, but greetd still uses the old ones.
              # and then you get a black screen when you log out.
              # This is because the greeter owns the session, so restarting the greeter restarts the session.
              niri = "/run/current-system/sw/bin/niri";
              niri-session = "/run/current-system/sw/bin/niri-session";
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
                  ${tuigreet} ${
                    if config.is-virtual-machine
                    # show user menu (because this is a fresh VM without the ability to remember)
                    # password is disabled in this case
                    # and also show the issue which has vm welcome info
                    then "--user-menu --issue"
                    # remember the user and focus the password right away
                    # because only one user exists, and i want to type only my password
                    # but no issue, because it is unnecessary and ugly
                    else "--remember"
                  } --cmd ${pkgs.writeScript "init-session" ''
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

  nitrogen.modules = [
    {
      login.tuigreet-width.proportion = 1.0;
    }
  ];
}
