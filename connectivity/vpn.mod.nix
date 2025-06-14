{
  nixpkgs,
  elements,
  ...
}: let
  ip = i: "10.8.0.${toString i}";
  public-keys = {
    iridium = "Ir+/fE0wl3Jf6w0QDVEsNFd0r+HCODKHTLb4FjV7GSg=";
    sodium = "Na+/Y9EMTF7+XNmRb5tGDB+uky44WQ/tAoDtkAgM7nc=";
    nitrogen = "N+/sIpsJatALo42N1tcU0O/Ps3CMzU6zuN+A7tGMWzo=";
    oxygen = "O+/FwR66shEquZ19mghgyjyUKJ3uTWSLqeFkGuAALmA=";
  };
  endpoints = {
    oxygen = "vps.sodi.boo:27462";
  };
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
  universal = {
    config,
    pkgs,
    lib,
    ...
  }: {
    environment.systemPackages = with pkgs; [
      # This is how i generated the keys with elemental prefixes! :3
      wireguard-vanity-keygen
    ];
    networking = {
      nat = {
        enable = true;
        externalInterface = "eth0";
        internalInterfaces = ["wg0"];
      };
      firewall = {
        # always listen on the wireguard port on the external interfaces
        allowedUDPPorts = [config.networking.wireguard.interfaces.wg0.listenPort];

        # allow all traffic on the wireguard interface, no matter the port
        trustedInterfaces = ["wg0"];
      };
      extraHosts = builtins.concatStringsSep "\n" (nixpkgs.lib.mapAttrsToList (name: z: "${ip z} ${name}.wg") elements);
      wireguard.interfaces.wg0 = {
        ips = ["${ip (builtins.getAttr config.system.name elements)}/24"];
        # School network seems to block UDP ports above 28000?
        listenPort = 27462;
        privateKeyFile = config.sops.secrets.wireguard-private-key.path;
      };
    };

    sops.secrets.wireguard-private-key.key = "wireguard-private-keys/${config.networking.hostName}";
    sops.secrets.wgautomesh-gossip-secret = {};

    services.wgautomesh = {
      enable = config.networking.wireguard.enable; # disable when wireguard is disabled (e.g. in a VM)
      gossipSecretFile = config.sops.secrets.wgautomesh-gossip-secret.path;
      settings = {
        interface = "wg0";
        peers =
          lib.mapAttrsToList (name: z: {
            pubkey = public-keys.${name};
            endpoint = endpoints.${name} or null;
            address = ip z;
          })
          elements;
      };
    };
  };

  # iridium.modules = [
  #   ({pkgs, ...}: {
  #     boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  #     networking.wireguard.interfaces.wg0 = {
  #       postSetup = ''
  #         ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${subnet} -o eth0 -j MASQUERADE
  #       '';
  #       postShutdown = ''
  #         ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${subnet} -o eth0 -j MASQUERADE
  #       '';

  #       peers = [
  #         {
  #           publicKey = public-keys.sodium;
  #           allowedIPs = [ips'.sodium];
  #         }
  #         {
  #           publicKey = public-keys.oxygen;
  #           allowedIPs = [subnet];
  #           endpoint = "vps.sodi.boo:${port-for.oxygen}";
  #           persistentKeepalive = 25;
  #         }
  #       ];
  #     };
  #   })
  # ];

  # oxygen.modules = [
  #   ({pkgs, ...}: {
  #     boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  #     networking.wireguard.interfaces.wg0 = {
  #       postSetup = ''
  #         ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${subnet} -o eth0 -j MASQUERADE
  #       '';
  #       postShutdown = ''
  #         ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${subnet} -o eth0 -j MASQUERADE
  #       '';

  #       peers = [
  #         {
  #           publicKey = public-keys.iridium;
  #           allowedIPs = [subnet];
  #         }
  #         {
  #           publicKey = public-keys.nitrogen;
  #           allowedIPs = [ips'.nitrogen];
  #         }
  #       ];
  #     };
  #   })
  # ];

  # sodium.modules = [
  #   {
  #     networking.wireguard.interfaces.wg0.peers = [
  #       {
  #         publicKey = public-keys.iridium;
  #         allowedIPs = [subnet];
  #         endpoint = "iridium.lan:${port-for.iridium}";
  #         persistentKeepalive = 25;
  #       }
  #     ];
  #   }
  # ];

  # nitrogen.modules = [
  #   {
  #     networking.wireguard.interfaces.wg0.peers = [
  #       # {
  #       #   publicKey = public-keys.iridium;
  #       #   allowedIPs = [subnet];
  #       #   endpoint = "iridium.lan:${port-for.iridium}";
  #       #   persistentKeepalive = 25;
  #       # }
  #       {
  #         publicKey = public-keys.oxygen;
  #         allowedIPs = [subnet];
  #         endpoint = "vps.sodi.boo:${port-for.oxygen}";
  #         persistentKeepalive = 25;
  #       }
  #     ];
  #   }
  # ];
}
