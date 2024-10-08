{
  personal.modules = [
    ({
      pkgs,
      lib,
      config,
      ...
    }:
      lib.mkIf (!config.is-virtual-machine) {
        boot.plymouth.enable = true;
        stylix.targets.plymouth.enable = false;
        boot.plymouth.theme = "bgrt";
        boot.initrd.verbose = false;
        boot.consoleLogLevel = 0;
        boot.kernelParams = ["quiet" "udev.log_priority=3"];
      })
  ];
}
