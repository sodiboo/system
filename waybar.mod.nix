{
  shared.home_modules = [
    ({
      config,
      lib,
      ...
    }: {
      # lol this breaks boot sequence
      # home.activation.restart-waybar = lib.hm.dag.entryAfter ["writeBoundary"] ''
      #   run ${config.systemd.user.systemctlPath} --user restart waybar.service
      # '';

      # systemd.user.services.waybar.Service.ExecStart = lib.mkForce (builtins.concatStringsSep " " [
      #   "${config.programs.waybar.package}/bin/waybar"
      #   "-c ${config.xdg.configFile."waybar/config".source}"
      #   "-s ${config.xdg.configFile."waybar/style.css".source}"
      # ]);

      programs.waybar = {
        enable = true;
        systemd.enable = true;
      };
      programs.waybar.settings.mainBar = {
        layer = "top";
        modules-center = ["clock"];
        modules-right = [
          "network"
          "bluetooth"
          "temperature"
          "battery"
        ];

        battery = {
          interval = 5;
          format = "{icon}  {capacity}%";
          format-icons = [" " " " " " " " " "];
          states.warning = 30;
          states.critical = 15;
        };

        clock = {
          interval = 1;
          format = "{:%Y-%m-%d    %H:%M:%S}";
        };

        network = {
          tooltip-format = "{ifname}";
          format-disconnected = "(disconnected)";
          format-ethernet = "(ethernet)";
          format-wifi = "{icon} {essid}";
          format-icons = ["󰤟 " "󰤢 " "󰤥 " "󰤨 "];
        };
      };
      stylix.targets.waybar.enable = false;
      programs.waybar.style = let
        colors = config.lib.stylix.colors;
      in ''
        * {
            border: none;
            font-family: ${config.stylix.fonts.sansSerif.name};
            font-size: ${toString config.stylix.fonts.sizes.desktop}px;
            color: #${colors.base07};
            border-radius: 20px;
        }

        window#waybar {
            background: transparent;
        }

        .modules-left, .modules-center, .modules-right {
            background-color: #${colors.base00};
            margin: 3px 10px;
            padding: 5px 7px;
            font-size: 1.2em;
        }

        #battery.charging {
            color: #${colors.green};
        }

        #battery.warning:not(.charging) {
            color: #${colors.yellow};
        }

        #battery.critical:not(.charging) {
            animation: critical-blink steps(8) 1s infinite alternate;
        }

        @keyframes critical-blink {
            to {
                color: #${colors.red};
            }
        }
      '';
    })
  ];
}
