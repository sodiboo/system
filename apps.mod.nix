inputs: {
  universal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        fastfetch
        fm-go
        python311
        dig
        whois
        libqalculate
      ];

      programs = {
        micro.enable = true;

        btop.enable = true;
        btop.settings.theme_background = false;
      };
    })
    inputs.vscode-server.homeModules.default
    {
      services.vscode-server.enable = true;
    }
  ];

  personal.modules = [
    {
      users.users.sodiboo.extraGroups = ["video"];
    }
    ({lib, ...}: {
      nixpkgs.overlays = [
        (final: prev: {
          sodi-vscode-fhs = final.writeShellScriptBin "code-fhs" ''
            exec ${lib.getExe final.vscode-fhs} $@
          '';
          wayvnc = inputs.nixpkgs-wayland.packages.x86_64-linux.wayvnc;
          zen-browser = inputs.zen-browser.packages.x86_64-linux.default;
        })
      ];
    })
  ];
  personal.home_modules = [
    ({
      pkgs,
      nixosConfig,
      ...
    }: {
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
        sodi-vscode-fhs
        rnote
      ];
      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = let
        file-manager = "org.kde.dolphin.desktop";
        web-browser =
          if nixosConfig.networking.hostName == "sodium"
          then "floorp.desktop"
          else "firefox.desktop";
      in {
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

      programs = {
        helix.enable = true;
        vscode.enable = true;
        # vscode.package = pkgs.vscode-fhs;
      };
    })
  ];
}
