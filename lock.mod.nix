let
  scripts = {
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
    magick_args = builtins.concatStringsSep " " [
      "-scale 2%"
      "-blur 0x.5"
      "-resize 5000%"
    ];
  in {
    lock = pkgs.writeScriptBin "blurred-locker" ''
      dir=/tmp/blurred-locker

      mkdir -p $dir

      for output in $(${niri} msg --json outputs | ${jq} -r "keys.[]"); do
        image="$dir/$output.png"

        ${grim} -o "$output" "$image"

        ${convert} "$image" ${magick_args} "$image"

        args+=" -i $output:$image"
      done

      ${swaylock} $args

      rm -r $dir
    '';

    blur = image:
      pkgs.runCommand "blurred.png" {} ''
        ${convert} "${image}" ${magick_args} "$out"
      '';
  };
in {
  shared.modules = [
    ({
      lib,
      pkgs,
      config,
      ...
    }: {
      options.stylix.blurred-image = with lib;
        mkOption {
          type = types.coercedTo types.package toString types.path;
          default = (scripts {inherit pkgs config;}).blur config.stylix.image;
          readOnly = true;
        };
    })
  ];

  shared.home_modules = [
    ({
      pkgs,
      config,
      ...
    }: {
      programs.swaylock.enable = true;
      home.packages = [
        (scripts {inherit pkgs config;}).lock
      ];
    })
  ];
}
