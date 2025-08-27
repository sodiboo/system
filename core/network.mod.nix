{
  carbon = {
    systemd.network.enable = true;
    networking.useNetworkd = true;
  };

  personal = {
    # should move to networkd eventually
    networking.networkmanager.enable = true;
    users.users.sodiboo.extraGroups = [ "networkmanager" ];
  };
}
