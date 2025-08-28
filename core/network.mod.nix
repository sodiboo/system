{
  carbon = {
    systemd.network.enable = true;
    networking.useNetworkd = true;
  };

  iridium = {
    systemd.network.enable = true;
    networking.useNetworkd = true;
  };

  oxygen =
    { lib, config, ... }:
    {
      options.public-ipv4 = lib.mkOption {
        type = lib.types.str;
      };
      options.public-ipv6 = lib.mkOption {
        type = lib.types.str;
      };
      config = {
        # These should match `vps.sodi.boo` DNS records.
        # All other domains are (flattened) CNAMEs to `vps.sodi.boo`.
        public-ipv4 = "85.190.241.69";
        public-ipv6 = "2a02:c202:2189:7245::1";

        networking = {

          enableIPv6 = true;
          defaultGateway6.address = "fe80::1";
          defaultGateway6.interface = "ens18";
          interfaces.ens18.ipv6.addresses = [
            {
              address = config.public-ipv6;
              prefixLength = 64;
            }
          ];
        };
      };
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
