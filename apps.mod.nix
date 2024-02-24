{
  shared.home_modules = [
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
      ];
    })
    (
      {
        config,
        pkgs,
        lib,
        ...
      }: {
        home.packages = with pkgs; [
          bitwarden-cli
          rustup
          clang
          grim
          slurp
          glib
          gsettings-desktop-schemas
          playerctl
          brightnessctl
          python311
          ffmpeg_6-full
          pairdrop
          git
          gh
        ];

        programs = {
          # Shell prompt
          # starship.enable = true;
          # starship.settings = import ./starship.nix;

          # But even so, sudo -i and nix-shell will create a bash shell. So it must also be enabled or i don't get my prompt
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
