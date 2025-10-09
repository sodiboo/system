{ systems, ... }:
{
  iridium =
    { lib, config, ... }:
    {
      systemd.network.netdevs."40-plutonium-host" = {
        netdevConfig = {
          Name = "plutonium";
          Kind = "veth";
        };
        peerConfig.Name = "plutonium-host";
      };

      systemd.network.networks."plutonium" = {
        matchConfig.Name = "plutonium";
        networkConfig.LinkLocalAddressing = "no";
        address = [ "${config.vpn.ip-address}/32" ];
        routes = [
          {
            Destination = "${systems.plutonium.vpn.ip-address}/32";
            Source = "${config.vpn.ip-address}/32";
          }
        ];
      };

      systemd.services."container@plutonium" = {
        requisite = [ "sys-subsystem-net-devices-plutonium\\x2dhost.device" ];
        after = [ "sys-subsystem-net-devices-plutonium\\x2dhost.device" ];
      };

      containers.plutonium.extraFlags = [ "--network-interface=plutonium-host:iridium" ];
    };

  plutonium =
    { config, ... }:
    {
      systemd.network.networks."iridium" = {
        matchConfig.Name = "iridium";
        networkConfig.LinkLocalAddressing = "no";
        address = [ "${config.vpn.ip-address}/32" ];
        routes = [
          {
            Destination = "${systems.iridium.vpn.ip-address}/32";
            Source = "${config.vpn.ip-address}/32";
          }
        ];
      };
    };
}
