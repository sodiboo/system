{
  personal = {pkgs, ...}: {
    networking.networkmanager.enable = true;
    users.users.sodiboo.extraGroups = ["networkmanager"];

    hardware.bluetooth.enable = true;

    environment.systemPackages = with pkgs; [
      bluetuith
    ];
  };
}
