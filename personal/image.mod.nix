{
  universal =
    { lib, pkgs, ... }:
    let

      magick = args: ''
        ${lib.getExe pkgs.imagemagick} convert "$1" ${builtins.concatStringsSep " " args} "$2"
      '';
    in
    {
      scripts.blur = magick [
        "-scale 2%"
        "-blur 0x.5"
        "-resize 5000%"
      ];

      scripts.modulate = magick [
        "-modulate 100,100,14"
      ];
    };
}
