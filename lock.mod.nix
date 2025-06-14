let
  scripts =
    {
      pkgs,
      config,
      ...
    }:
    let
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
    in
    {
      lock = pkgs.writeScriptBin "blurred-locker" ''
        dir=/tmp/blurred-locker

        mkdir -p $dir

        for output in $(${niri} msg --json outputs | ${jq} -r "keys.[]"); do
          image="$dir/$output.png"

          ${grim} -o "$output" "$image"

          ${convert} "$image" ${magick_args} "$image"

          args+=" -i $output:$image"
        done

        ${niri} msg action do-screen-transition
        ${swaylock} $args

        rm -r $dir
      '';

      blur =
        image:
        pkgs.runCommand "blurred.png" { } ''
          ${convert} "${image}" ${magick_args} "$out"
        '';
    };
in
{
  personal =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      scripts' = scripts {
        inherit pkgs;
        config = config.home-manager.users.sodiboo;
      };
    in
    {
      options.stylix.blurred-image =
        with lib;
        mkOption {
          type = types.coercedTo types.package toString types.path;
          default = scripts'.blur config.stylix.image;
          readOnly = true;
        };

      config.home-shortcut =
        {
          lib,
          pkgs,
          config,
          nixosConfig,
          ...
        }:
        {
          options.suspend-when-idle = lib.mkEnableOption "suspend when idle";
          config =
            let
              scripts' = scripts {
                inherit pkgs config;
              };
              systemctl = config.systemd.user.systemctlPath;
              pidof = lib.getExe' pkgs.procps "pidof";
              niri = lib.getExe config.programs.niri.package;

              secondary =
                if config.suspend-when-idle then
                  "${systemctl} suspend"
                else
                  "${niri} msg action power-off-monitors";
            in
            # swaylock doesn't work with empty passwords
            # but the VM has an empty password
            lib.mkIf (!nixosConfig.is-virtual-machine) {
              home.packages = [
                scripts'.lock
              ];
              programs.swaylock.enable = true;

              services.swayidle.enable = true;
              services.swayidle.timeouts = [
                {
                  timeout = 30;
                  command = "${pidof} swaylock && ${secondary}";
                }
                {
                  timeout = 300;
                  command = "${pidof} swaylock || ${niri} msg action spawn -- ${lib.getExe scripts'.lock}";
                }
                {
                  timeout = 330;
                  command = "${pidof} swaylock && ${secondary}";
                }
              ];
              services.swayidle.events = [
                {
                  event = "before-sleep";
                  command = "${niri} msg action power-off-monitors";
                }
                {
                  event = "after-resume";
                  command = "${niri} msg action power-on-monitors";
                }
              ];
              # systemd.user.services.swayidle.Unit = {
              #   Wants = ["niri.service"];
              #   After = "niri.service";
              # };
            };
        };
    };

  sodium.home-shortcut = {
    suspend-when-idle = false;
  };
  nitrogen.home-shortcut = {
    suspend-when-idle = true;
  };
}
