{nari, ...}: {
  personal.modules = [
    {
      programs.adb.enable = true;
      users.users.sodiboo.extraGroups = ["adbusers"];

      services.udisks2.enable = true;
      services.gvfs.enable = true;
      services.devmon.enable = true;
    }
  ];
  sodium.modules = [
    nari.nixosModules.default
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

        programs.droidcam.enable = true;
      })
  ];

  nitrogen.modules = [
    {
      services.upower.enable = true;
    }
  ];
}
