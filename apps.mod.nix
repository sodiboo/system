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
    ({pkgs, ...}: {
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
      xdg.mimeApps.defaultApplications."inode/directory" = "org.kde.dolphin.desktop";

      programs = {
        helix.enable = true;
        vscode.enable = true;
        # vscode.package = pkgs.vscode-fhs;
      };
    })
  ];
}
