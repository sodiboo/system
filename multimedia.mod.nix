{
  personal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        # the gods of multimedia
        ffmpeg-full
        imagemagick
        pandoc

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
        libsForQt5.kdenlive
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
