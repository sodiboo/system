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
        tenacity # yeah i know it's a fork of audacity. i like both
        sonic-visualiser

        krita
        swappy

        obs-studio

        vlc
        mpv
        stremio
      ];
    })
  ];
}
