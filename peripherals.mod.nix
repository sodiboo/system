{
  personal = {
    programs.adb.enable = true;
    programs.droidcam.enable = true;
    users.users.sodiboo.extraGroups = ["adbusers"];

    services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.devmon.enable = true;
  };
  sodium.imports = [
    ({
      pkgs,
      lib,
      config,
      ...
    }:
      lib.mkIf (!config.is-virtual-machine) {
        hardware.wooting.enable = true;
        users.users.sodiboo.extraGroups = ["input"];

        environment.systemPackages = with pkgs; [
          openrgb-with-all-plugins
          openrazer-daemon
          polychromatic
        ];
      })

    {
      hardware.i2c.enable = true;
    }
  ];

  nitrogen = {
    services.upower.enable = true;
  };
}
