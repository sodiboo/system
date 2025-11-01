inputs: {
  personal =
    { lib, ... }:
    {
      users.users.sodiboo.extraGroups = [ "video" ];

      nixpkgs.overlays = [
        (final: prev: {
          wayvnc = inputs.nixpkgs-wayland.packages.x86_64-linux.wayvnc;
          zen-browser = inputs.zen-browser.packages.x86_64-linux.default;
        })
      ];

      home-shortcut =
        {
          pkgs,
          nixosConfig,
          ...
        }:
        {
          home.packages = with pkgs; [
            appimage-run
            kdePackages.dolphin
            firefox
            zen-browser
            thunderbird
            seahorse
            caligula
            vesktop
            element-desktop
            signal-desktop
            bitwarden-cli
            grim
            slurp
            gsettings-desktop-schemas
            playerctl
            brightnessctl
            pairdrop
            swayimg
            stackblur-go
            subversion
            wayvnc
            wlvncc
            rnote
          ];
          xdg.mimeApps.enable = true;
          xdg.mimeApps.defaultApplications =
            let
              file-manager = "org.kde.dolphin.desktop";
              web-browser =
                if nixosConfig.networking.hostName == "sodium" then "floorp.desktop" else "firefox.desktop";
            in
            {
              "inode/directory" = file-manager;

              "x-scheme-handler/http" = web-browser;
              "x-scheme-handler/https" = web-browser;
              "x-scheme-handler/chrome" = web-browser;
              "text/html" = web-browser;
              "application/x-extension-htm" = web-browser;
              "application/x-extension-html" = web-browser;
              "application/x-extension-shtml" = web-browser;
              "application/xhtml+xml" = web-browser;
              "application/x-extension-xhtml" = web-browser;
              "application/x-extension-xht" = web-browser;
            };
        };
    };
}
