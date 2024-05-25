{
  personal.modules = [
    {
      programs.steam.enable = true;
    }
  ];

  universal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        fastfetch
        fm-go
        python311
        ffmpeg_6-full
        p7zip
        ripgrep-all
        dig
        whois
      ];

      programs.micro.enable = true;
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
        pandoc
        stackblur-go
        simutrans
        subversion
        wlvncc
      ];
    })
    (
      {
        config,
        pkgs,
        lib,
        ...
      }: {
        programs = {
          helix.enable = true;
          vscode.enable = true;

          btop.enable = true;
          btop.settings.theme_background = false;
        };
      }
    )
  ];
}
