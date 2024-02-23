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
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        settings.mainBar = {
          layer = "top";
          modules-center = ["clock"];
          modules-right = [
            "network"
            "bluetooth"
            "battery"
          ];

          battery = {
            interval = 5;
            format = "{icon}  {capacity}%";
            format-icons = [" " " " " " " " " "];
          };

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
        style =
          #  with config.lib.stylix.colors.withHashtag;
          ''
            * {
                border: none;
                font-family: Font Awesome, Roboto, Arial, sans-serif;
                font-size: 13px;
                border-radius: 20px;
            }

            window#waybar {
                background: transparent;
            }
            /*-----module groups----*/
            .modules-right {
                background-color: @base01;
                margin: 5px 10px 0 0;
            }
            .modules-center {
                background-color: @base01;
                margin: 5px 0 0 0;
            }
            .modules-left {
                margin: 5px 0 0 5px;
                background-color: @base01;
            }

            /*-----modules indv----*/
            #workspaces button {
                padding: 1px 5px;
                /* background-color: transparent; */
            }
            #workspaces button:hover {
                box-shadow: inherit;
            	  background-color: rgba(0,153,153,1);
            }

            #workspaces button.focused {
            	background-color: rgba(0,43,51,0.85);
            }

            #clock,
            #battery,
            #cpu,
            #memory,
            #temperature,
            #network,
            #pulseaudio,
            #custom-media,
            #tray,
            #mode,
            #custom-power,
            #custom-menu,
            #idle_inhibitor {
                padding: 0 10px;
            }
            #mode {
                color: #cc3436;
                font-weight: bold;
            }
            #custom-power {
                background-color: rgba(0,119,179,0.6);
                border-radius: 100px;
                margin: 5px 5px;
                padding: 1px 1px 1px 6px;
            }
            /*-----Indicators----*/
            #idle_inhibitor.activated {
                color: #2dcc36;
            }
            #pulseaudio.muted {
                color: #cc3436;
            }


            #battery.charging {
                color: #2dcc36;
            }
            #battery.warning:not(.charging) {
            	  color: #e6e600;
            }
            #battery.critical:not(.charging) {
                color: #cc3436;
            }


            #temperature.critical {
                color: #cc3436;
            }
          '';
      };
    })
  ];
}
