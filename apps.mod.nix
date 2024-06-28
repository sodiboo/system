{vscode-server, ...}: {
  personal.modules = [
    {
      users.users.sodiboo.extraGroups = ["video"];
    }
  ];
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
        vesktop
        element-desktop
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
      ];
    })
    {
      programs = {
        helix.enable = true;
        vscode.enable = true;
      };
    }
  ];
}
