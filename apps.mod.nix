{
  shared.modules = [
    {
      programs.steam.enable = true;
    }
  ];
  shared.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        fastfetch
        fm-go
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
        python311
        ffmpeg_6-full
        pairdrop
        swayimg
        p7zip
        pandoc
        ripgrep-all
        simutrans
        stackblur-go
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
          # Shell prompt
          # starship.enable = true;
          # starship.settings = import ./starship.nix;

          bash.enable = true;

          helix.enable = true;
          micro.enable = true;
          vscode.enable = true;

          # eww.enable = true;
          # eww.package = pkgs.eww-wayland;
          # eww.configDir = ~/.eww;
        };
      }
    )
  ];
}
