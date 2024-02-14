{
  description = "sodi flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";

    niri.url = "github:sodiboo/niri-flake";
    niri.inputs.niri-src.url = "github:YaLTeR/niri";

    # this is my best solution to use .gitignore'd files without scary git fuckery
    # (because they are normally excluded from `self` passed to a flake)
    # it creates a sort of "blockchain" because it depends on the lockfile, which updates every time.
    # theoretically, you can go to the path of the etc-nixos input, and this is the prev revision
    # and as long as they haven't been gc'd, keep going forever. lmao.
    etc-nixos.url = "/etc/nixos/";
    etc-nixos.flake = false;
    # nari.url = "path:/home/sodiboo/nixos-razer-nari";
  };

  outputs = {
    nixpkgs,
    home-manager,
    stylix,
    niri,
    etc-nixos,
    # nari,
    ...
  } @ inputs: let
    keyboard_layout = "no";
    shared.modules = [
      {
        time.timeZone = "Europe/Stockholm";
        console.keyMap = keyboard_layout;

        i18n.defaultLocale = "en_US.UTF-8";
        i18n.extraLocaleSettings = {
          LC_ADDRESS = "C.UTF-8";
          LC_IDENTIFICATION = "C.UTF-8";
          LC_MEASUREMENT = "C.UTF-8";
          LC_MONETARY = "C.UTF-8";
          LC_NAME = "C.UTF-8";
          LC_NUMERIC = "C.UTF-8";
          LC_PAPER = "C.UTF-8";
          LC_TELEPHONE = "C.UTF-8";
          LC_TIME = "C.UTF-8";
        };
      }
      ({pkgs, ...}:
        with pkgs; {
          environment.systemPackages = [
            libsecret

            wl-clipboard
            wayland-utils

            gnome.gnome-tweaks
            gnomeExtensions.paperwm

            cage
            gamescope

            foot
            greetd.tuigreet
            micro
            tldr
            eza
            bat
            fd
            ripgrep
            bottom
            difftastic
            socat
            jq
            tree
            file
            bc
            git

            kakoune
          ];
        })
      {
        boot.loader.systemd-boot = {
          enable = true;
          netbootxyz.enable = true;
          consoleMode = "auto";
        };
        boot.loader.efi.canTouchEfiVariables = true;
      }
      {
        networking.networkmanager.enable = true;
        users.users.sodiboo.extraGroups = ["networkmanager"];
      }
      ({pkgs, ...}: {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = ''${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format="%F %T" --remember --cmd "niri-session" '';
              user = "greeter";
            };
          };
        };
        security.pam.services.greetd.enableGnomeKeyring = true;
        # environment.extraInit = ''
        #   LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.libsecret}/lib"
        # '';
      })
      ({config, ...}: {
        services.xserver = {
          enable = true;
          xkb.layout = keyboard_layout;
          displayManager.gdm.enable = !config.services.greetd.enable;
          desktopManager.gnome.enable = true;
        };
      })
      {
        sound.enable = true;
        hardware.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
          #media-session.enable = true;
        };
      }
      ({pkgs, ...}: {
        fonts = {
          enableDefaultPackages = true;
          fontconfig.defaultFonts.monospace = ["FiraCode Nerd Font"];
          packages = [
            (pkgs.nerdfonts.override {fonts = ["FiraCode"];})
          ];
        };
      })
      {
        users.users.sodiboo = {
          isNormalUser = true;
          description = "sodiboo";
          extraGroups = ["wheel"];
        };
      }
      ({pkgs, ...}: {
        programs.fish.enable = true;
        users.defaultUserShell = pkgs.fish;
        environment.shells = [pkgs.fish];
      })
      {
        qt.enable = true;
        qt.style = "adwaita-dark";
        qt.platformTheme = "gnome";
      }
      ({config, ...}: {
        environment.variables = {
          XKB_DEFAULT_LAYOUT = keyboard_layout;
          NIXOS_OZONE_WL = "1";
        };
      })
      {
        users.users.sodiboo.extraGroups = ["adbusers"];
        programs.adb.enable = true;
      }
      niri.nixosModules.niri
      {programs.niri.enable = true;}
    ];

    shared.home_modules = [
      (
        {
          config,
          pkgs,
          lib,
          ...
        }: {
          home.packages = with pkgs; [
            appimage-run
            eww-wayland
            dolphin
            mako
            # dunst
            # avizo
            libnotify
            firefox
            thunderbird
            hyprpicker
            gnome.seahorse
            swww
            spotifyd
            spotify-tui
            sptlrx
            obs-studio
            rustup
            clang
            grim
            slurp
            glib
            gsettings-desktop-schemas
            playerctl
            python311
            ffmpeg_6-full
            vlc
            audacity
            # nur.repos.mikilio.xwaylandvideobridge-hypr
            # hyprland-contrib.grimblast
            fuzzel
            git
            gh
            vesktop
            openrgb-with-all-plugins
            pairdrop
            graphite-cursors
            element-desktop
            entr
            nix-index
          ];

          # xdg.systemDirs.data = ["${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"];

          home.file = {
            # # Building this configuration will create a copy of 'dotfiles/screenrc' in
            # # the Nix store. Activating the configuration will then make '~/.screenrc' a
            # # symlink to the Nix store copy.
            # ".screenrc".source = dotfiles/screenrc;

            # # You can also set the file content immediately.
            # ".gradle/gradle.properties".text = ''
            #   org.gradle.console=verbose
            #   org.gradle.daemon.idletimeout=3600000
            # '';
          };

          # You can also manage environment variables but you will have to manually
          # source
          #
          #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
          #
          # or
          #
          #  /etc/profiles/per-user/sodiboo/etc/profile.d/hm-session-vars.sh
          #
          # if you don't want to manage your shell through Home Manager.
          home.sessionVariables = {
            EDITOR = "kak";
          };

          programs = {
            waybar = {
              enable = true;
              systemd.enable = true;
              settings.mainBar = {
                layer = "top";
                modules-center = ["clock"];
                modules-right = ["network" "bluetooth" "battery"];

                clock = {
                  interval = 1;
                  format = "  {:%H:%M:%S}";
                  tooltip-format = "<tt>{calendar}</tt>";

                  # this doesn't actually look right. i copied from the wiki. sucks on 16:9 and 32:9
                  calendar = {
                    mode = "year";
                    mode-mon-col = 3;
                    weeks-pos = "left";
                    format = {
                      months = "<span color='#ffead3'><b>{}</b></span>";
                      days = "<span color='#ecc6d9'><b>{}</b></span>";
                      weeks = "<span color='#99ffdd'><b>W{}</b></span>";
                      weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                      today = "<span color='#ff6699'><b><u>{}</u></b></span>";
                    };
                  };
                };
              };
            };

            foot = {
              enable = true;
              settings.csd.preferred = "none";
            };

            # Shell prompt
            # starship.enable = true;
            # starship.settings = import ./starship.nix;
            powerline-go.enable = true;
            powerline-go.modules = [
              "ssh"
              "cwd"
              "perms"
              "git"
              "hg"
              "nix-shell"
              "jobs"
              # "duration" # not working
              "exit"
              "root"
            ];

            direnv = {
              enable = true;
              # enableFishIntegration = true;
              enableBashIntegration = true;
              nix-direnv.enable = true;
            };

            # I use fish
            fish = {
              enable = true;
              interactiveShellInit = "set fish_greeting";
              # gnome fucks EDITOR variable?
              # shellInit = '' set EDITOR "kak" '';
              shellAbbrs = {
                ls = "eza";
                exa = "eza";
                tree = "eza --tree";
                cat = "bat";
                find = "fd";
                grep = "rg";
                diff = "difft";
              };
              shellAliases = {
                eza = "eza --long --all --icons --time-style long-iso";
                sptlrx = "sptlrx --before faint";

                nix-shell = "nix-shell --run fish";
                nix-switch = ''sudo sh -c "cd /etc/nixos; nix fmt; nix flake update; nixos-rebuild switch"'';
              };
            };

            # But even so, sudo -i and nix-shell will create a bash shell. So it must also be enabled or i don't get my prompt
            bash.enable = true;

            helix.enable = true;
            micro.enable = true;
            vscode.enable = true;

            # eww.enable = true;
            # eww.package = pkgs.eww-wayland;
            # eww.configDir = ~/.eww;

            # Let Home Manager install and manage itself.
            home-manager.enable = true;
          };

          services.spotifyd.enable = true;
          services.spotifyd.settings.global = {
            username = lib.strings.fileContents "${etc-nixos}/.spotify_username";
            password = lib.strings.fileContents "${etc-nixos}/.spotify_password";
          };

          xsession = {
            enable = true;
          };
        }
      )
      {
        programs.swaylock.enable = true;
      }
      ({
        pkgs,
        config,
        ...
      }: {
        home.packages = [
          (let
            wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
            wl-paste = "${pkgs.wl-clipboard}/bin/wl-paste";
            convert = "${pkgs.imagemagick}/bin/convert";
            makoctl = "${pkgs.mako}/bin/makoctl";
            jq = "${pkgs.jq}/bin/jq";
            swaylock = "${config.programs.swaylock.package}/bin/swaylock";
            niri = "${config.programs.niri.package}/bin/niri";
            notifs = builtins.concatStringsSep " | " [
              "${makoctl} list"
              "${jq} '${
                builtins.concatStringsSep " |" [
                  ''.data[0][]''
                  ''select(.["app-name"].data == "niri" and .summary.data == "Screenshot captured")''
                  ''.id.data''
                ]
              }'"
              "sort"
            ];
            # for quick iteration
            magick_args = [
              "-filter Gaussian"
              "-resize 2%"
              "-resize 5000%"
            ];
          in
            pkgs.writeScriptBin "blurred-locker" ''
              dir=/tmp/blurred-locker

              mkdir -p $dir

              ${wl-paste} --no-newline > $dir/clip

              ${notifs} > $dir/existing-notifs
              ${niri} msg action screenshot-screen
              while
                new_notifs="$(${notifs} | comm -23 - $dir/existing-notifs | grep -P '^\d+$')"
                [ $? -ne 0 ]
              do
                :
              done
              for i in $(echo "$new_notifs")
              do
                ${makoctl} dismiss -n $i
              done
              ${wl-paste} > $dir/screenshot.png

              ${wl-copy} < $dir/clip
              rm $dir/clip

              ${convert} "$dir/screenshot.png" ${builtins.concatStringsSep " " magick_args} "$dir/blurred.png"

              ${swaylock} -i $dir/blurred.png

              rm -r $dir
            '')
        ];
      })
    ];

    niri_config = {wide}: let
      only = cond: text:
        if cond
        then text
        else "/* ${text} */";
      binds = with builtins;
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
    in ''
      input {
          keyboard { xkb { layout "${keyboard_layout}"; }; }
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

    configs = {
      sodium.system = "x86_64-linux";
      sodium.modules = [
        {
          hardware.wooting.enable = true;
          users.users.sodiboo.extraGroups = ["input"];
        }
        ({pkgs, ...}: {
          environment.systemPackages = with pkgs; [
            openrazer-daemon
            polychromatic
          ];
        })
      ];
      sodium.home_modules = [
        {
          services.spotifyd.settings.global.device_name = "sodi computer";
          programs.niri.config = niri_config {wide = true;};
        }
      ];

      lithium.system = "x86_64-linux";
      lithium.modules = [
        {
          services.fprintd.enable = true;
          security.pam.services.swaylock.fprintAuth = false;
        }
        # stylix.nixosModules.stylix
        # ({pkgs, ...}: {
        #   stylix.image = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.src;
        # })
      ];
      lithium.home_modules = [
        # {
        #   home.file.".config/Code/User/settings.json".enable= false;
        # }
        {
          services.spotifyd.settings.global.device_name = "sodi laptop";
          programs.niri.config = niri_config {wide = false;};
        }
      ];
    };

    actualConfigs =
      builtins.mapAttrs (
        hostname: config:
          nixpkgs.lib.nixosSystem {
            system = configs.${hostname}.system;
            modules =
              [
                "${etc-nixos}/hardware-configuration.nix"
                {
                  networking.hostName = hostname;
                  nix.settings.experimental-features = ["nix-command" "flakes"];
                  nixpkgs.config.allowUnfree = true;
                  system.stateVersion = "23.11";
                }
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.sodiboo = {
                    home.username = "sodiboo";
                    home.homeDirectory = "/home/sodiboo";
                    home.stateVersion = "22.11";

                    imports = shared.home_modules ++ config.home_modules;
                  };
                }
              ]
              ++ shared.modules
              ++ config.modules;
          }
      )
      configs;
  in {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    nixosConfigurations = actualConfigs;
  };
}
