{
  self,
  nixpkgs,
  ...
}: let
  public-keys = {
    iridium = "MKPEkYG4Kk26pLP4RwBE9LZKbPlwEzw3gqkbE+NRVwg=";
    sodium = "bEhUkNvrV2lvMKz1QaS8xpipgRq0gaASMH6maKe6vwA=";
    nitrogen = "jCaI67FtevJIFOCiSoe40LSORMhmQ5b14h/DG/8THms=";
    oxygen = "/C3FBaSjRXh2ln9sbTJETb3Dj5masxOAzi3xawdcSiA=";
  };

  ip = i: "10.8.0.${toString i}";
  subnet = "${ip 0}/24";

  ips = {
    iridium = ip 1;
    sodium = ip 2;
    nitrogen = ip 3;
    oxygen = ip 4;
  };

  ips' = builtins.mapAttrs (name: ip: "${ip}/32") ips;

  port-for = builtins.mapAttrs (machine: {config, ...}: toString config.networking.wireguard.interfaces.wg0.listenPort) self.nixosConfigurations;
  # Some network topology here:
  # - My home network has a subnet of 192.168.86.0/24
  # - My private wireguard network has a subnet of 10.8.0.0/24
  # - sodium and iridium are on the home network
  # - The home network has a public IP, but it is not mine to use. For all intents and purposes, i don't have a public IP.
  # - The home network routes {hostname}.lan to the corresponding IP on 192.168.86.x
  # - sodium and iridium can therefore view each other as {sodium,iridium}.lan
  #
  # - oxygen is a VPS with a public IP. Everyone can see it as vps.sodi.boo
  # - oxygen cannot directly access sodium or iridium
  #
  # - nitrogen is a laptop that is sometimes on the home network as nitrogen.lan, and sometimes not.
  # - it cannot reliably access sodium or iridium through lan, but can always see oxygen.
  # - nobody can reliably access nitrogen with a given hostname
  #
  # Therefore:
  # - iridium is the main server
  # - sodium connects to iridium always
  # - oxygen needs a weird reverse proxy thing to connect to iridium (really, iridium needs to connect to oxygen, but oxygen acts like the client)
  # - nitrogen wants to connect to iridium, but can't always. so it connects to oxygen when iridium is unavailable, taking a performance hit
in {
  extras = {wireguard-ips = ips;};

  universal.modules = [
    ({config, ...}: {
      networking = {
        nat = {
          enable = true;
          externalInterface = "eth0";
          internalInterfaces = ["wg0"];
        };
        firewall.allowedUDPPorts = [config.networking.wireguard.interfaces.wg0.listenPort];
        extraHosts = builtins.concatStringsSep "\n" (nixpkgs.lib.mapAttrsToList (name: ip: "${ip} ${name}.wg") ips);
        wireguard.interfaces.wg0 = {
          ips = ["${ips.${config.networking.hostName}}/24"];
          listenPort = 51820;
          privateKeyFile = config.sops.secrets.wireguard-private-key.path;
        };
      };
    })
  ];

  iridium.modules = [
    ({pkgs, ...}: {
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      networking.wireguard.interfaces.wg0 = {
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${subnet} -o eth0 -j MASQUERADE
        '';
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${subnet} -o eth0 -j MASQUERADE
        '';

        peers = [
          {
            publicKey = public-keys.sodium;
            allowedIPs = [ips'.sodium];
          }
          {
            publicKey = public-keys.nitrogen;
            allowedIPs = [ips'.nitrogen];
          }
          {
            publicKey = public-keys.oxygen;
            allowedIPs = [subnet];
            endpoint = "vps.sodi.boo:${port-for.oxygen}";
            persistentKeepalive = 25;
          }
        ];
      };
    })
  ];

  oxygen.modules = [
    ({pkgs, ...}: {
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      networking.wireguard.interfaces.wg0 = {
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${subnet} -o eth0 -j MASQUERADE
        '';
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${subnet} -o eth0 -j MASQUERADE
        '';

        peers = [
          {
            publicKey = public-keys.iridium;
            allowedIPs = [subnet];
          }
          {
            publicKey = public-keys.nitrogen;
            allowedIPs = [ips'.nitrogen];
          }
        ];
      };
    })
  ];

  sodium.modules = [
    {
      networking.wireguard.interfaces.wg0.peers = [
        {
          publicKey = public-keys.iridium;
          allowedIPs = [subnet];
          endpoint = "iridium.lan:${port-for.iridium}";
          persistentKeepalive = 25;
        }
      ];
    }
  ];

  nitrogen.modules = [
    {
      networking.wireguard.interfaces.wg0.peers = [
        # {
        #   publicKey = public-keys.iridium;
        #   allowedIPs = [subnet];
        #   endpoint = "iridium.lan:${port-for.iridium}";
        #   persistentKeepalive = 25;
        # }
        {
          publicKey = public-keys.oxygen;
          allowedIPs = [subnet];
          endpoint = "vps.sodi.boo:${port-for.oxygen}";
          persistentKeepalive = 25;
        }
      ];
    }
  ];
}
