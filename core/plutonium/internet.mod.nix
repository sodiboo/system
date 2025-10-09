{
  iridium =
    { config, ... }:
    {
      sops.secrets.plutonium-wg-private-key = { };

      systemd.services.systemd-networkd.serviceConfig.LoadCredential = [
        "wireguard-plutonium-private-key:${config.sops.secrets.plutonium-wg-private-key.path}"
      ];

      systemd.network.netdevs."40-plutonium-inet" = {
        netdevConfig = {
          Name = "plutonium-inet";
          Kind = "wireguard";
          MTUBytes = 1280;
        };

        wireguardConfig = {
          PrivateKey = "@wireguard-plutonium-private-key";
        };
        wireguardPeers = [
          {
            PublicKey = "4Fp/ASabm9CwCZPyTLInJUWvR7+cAwF3oMm9wT3a0Rc=";
            Endpoint = "wg020.njalla.no:51820";
            PersistentKeepalive = 25;
            AllowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
          }
        ];
      };

      systemd.services."container@plutonium" = {
        requisite = [ "sys-subsystem-net-devices-plutonium\\x2dinet.device" ];
        after = [ "sys-subsystem-net-devices-plutonium\\x2dinet.device" ];
      };

      containers.plutonium.extraFlags = [ "--network-interface=plutonium-inet:internet" ];
    };

  plutonium =
    { lib, ... }:
    {
      systemd.network.networks."internet" = {
        matchConfig.Name = "internet";
        address = [
          "fd03:1337::236/64"
          "10.13.37.236/24"
        ];
        gateway = [
          "0.0.0.0"
          "::"
        ];
      };

      networking.nameservers = lib.mkForce [
        "95.215.19.53"
        "2001:67c:2354:2::53"
      ];
    };
}
