{
  personal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        # the gods of multimedia
        ffmpeg-full
        imagemagick
        pandoc

        yt-dlp

        ripgrep-all # grep through pandocable files

        exiftool
        binwalk
        p7zip

        # audacity
        tenacity
        # sonic-visualiser

        # krita # <-- SHE DOES NOT SUPPORT WAYLAND
        gimp3 # <-- yay! wayland! :3
        swappy

        kdePackages.kdenlive
        # shotcut
        # flowblade
        # avidemux

        vlc
        mpv
        stremio
      ];
    })
  ];

  personal.modules = [
    {
      programs.obs-studio.enable = true;
      programs.obs-studio.enableVirtualCamera = true;
    }
  ];
}
