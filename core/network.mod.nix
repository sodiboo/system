{
  universal =
    { config, ... }:
    {
      services.resolved.enable = false;
      environment.etc."resolv.conf".text = ''
        ${builtins.concatStringsSep "\n" (map (ns: "nameserver ${ns}") config.networking.nameservers)}
        options edns0
      '';

      networking.nameservers = [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];
    };

  carbon = {
    systemd.network.enable = true;
    networking.useNetworkd = true;
  };

  iridium = {
    systemd.network.enable = true;
    networking.useNetworkd = true;
  };

  oxygen = {
    systemd.network.enable = true;
    networking.useNetworkd = true;

    # Contabo gives a /64 prefix, which requires manual configuration.
    # Without this, i only get IPv4.
    networking.defaultGateway6 = {
      address = "fe80::1";
      interface = "ens18";
    };
    networking.interfaces.ens18.ipv6.addresses = [
      {
        address = "2a02:c202:2189:7245::1";
        prefixLength = 64;
      }
    ];

    # But configuring IPv6 breaks the IPv4 connectivity?
    networking.defaultGateway = {
      address = "85.190.241.1";
      interface = "ens18";
    };
    networking.interfaces.ens18.ipv4.addresses = [
      {
        address = "85.190.241.69";
        prefixLength = 24; # <-- That's not supposed to be a /24??? What the fuck. /32 breaks it.
      }
    ];
  };

  nitrogen = {
    # should move to networkd eventually
    networking.networkmanager.enable = true;
    users.users.sodiboo.extraGroups = [ "networkmanager" ];
  };

  sodium = {
    systemd.network.enable = true;
    networking.useNetworkd = true;
  };
}
