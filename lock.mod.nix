let
  blurred-locker = {
    pkgs,
    config,
    ...
  }: let
    wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
    wl-paste = "${pkgs.wl-clipboard}/bin/wl-paste";
    convert = "${pkgs.imagemagick}/bin/convert";
    makoctl = "${pkgs.mako}/bin/makoctl";
    jq = "${pkgs.jq}/bin/jq";
    swaylock = "${config.programs.swaylock.package}/bin/swaylock";
    niri = "${config.programs.niri.package}/bin/niri";
    notifs = builtins.concatStringsSep " | " [
      "${makoctl} list"
      "${jq} '${
        builtins.concatStringsSep " |" [
          ''.data[0][]''
          ''select(.["app-name"].data == "niri" and .summary.data == "Screenshot captured")''
          ''.id.data''
        ]
      }'"
      "sort"
    ];
    # for quick iteration
    magick_args = [
      "-filter Gaussian"
      "-resize 2%"
      "-resize 5000%"
    ];
  in
    pkgs.writeScriptBin "blurred-locker" ''
      dir=/tmp/blurred-locker

      mkdir -p $dir

      ${wl-paste} --no-newline > $dir/clip

      ${notifs} > $dir/existing-notifs
      ${niri} msg action screenshot-screen
      while
        new_notifs="$(${notifs} | comm -23 - $dir/existing-notifs | grep -P '^\d+$')"
        [ $? -ne 0 ]
      do
        :
      done
      for i in $(echo "$new_notifs")
      do
        ${makoctl} dismiss -n $i
      done
      ${wl-paste} > $dir/screenshot.png

      ${wl-copy} < $dir/clip
      rm $dir/clip

      ${convert} "$dir/screenshot.png" ${builtins.concatStringsSep " " magick_args} "$dir/blurred.png"

      ${swaylock} -i $dir/blurred.png

      rm -r $dir
    '';
in {
  shared.home_modules = [
    ({
      pkgs,
      config,
      ...
    }: {
      programs.swaylock.enable = true;
      home.packages = [
        (blurred-locker {inherit pkgs config;})
      ];
    })
  ];
}
