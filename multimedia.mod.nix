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

        krita
        swappy

        obs-studio
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
}
