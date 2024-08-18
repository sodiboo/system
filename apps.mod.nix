{vscode-server, ...}: {
  universal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        fastfetch
        fm-go
        python311
        ffmpeg_6-full
        pandoc
        p7zip
        ripgrep-all
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
    vscode-server.homeModules.default
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
        })
      ];
    })
  ];
  personal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        appimage-run
        dolphin
        firefox
        thunderbird
        gnome.seahorse
        obs-studio
        vlc
        mpv
        audacity
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
        wlvncc
        sodi-vscode-fhs
        krita
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
