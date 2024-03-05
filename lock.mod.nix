let
  blurred-locker = {
    pkgs,
    config,
    ...
  }: let
    # wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
    # wl-paste = "${pkgs.wl-clipboard}/bin/wl-paste";
    convert = "${pkgs.imagemagick}/bin/convert";
    grim = "${pkgs.grim}/bin/grim";
    jq = "${pkgs.jq}/bin/jq";
    swaylock = "${config.programs.swaylock.package}/bin/swaylock";
    niri = "${config.programs.niri.package}/bin/niri";
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

      for output in $(${niri} msg --json outputs | ${jq} -r "keys.[]"); do
        image="$dir/$output.png"

        ${grim} -o "$output" "$image"

        ${convert} "$image" ${builtins.concatStringsSep " " magick_args} "$image"

        args+=" -i $output:$image"
      done

      ${swaylock} $args

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
