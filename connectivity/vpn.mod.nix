{
  systems,
  ...
}:
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
{
  iridium.vpn.public-key = "Ir+/fE0wl3Jf6w0QDVEsNFd0r+HCODKHTLb4FjV7GSg=";
  sodium.vpn.public-key = "Na+/Y9EMTF7+XNmRb5tGDB+uky44WQ/tAoDtkAgM7nc=";
  nitrogen.vpn.public-key = "N+/sIpsJatALo42N1tcU0O/Ps3CMzU6zuN+A7tGMWzo=";
  oxygen.vpn.public-key = "O+/FwR66shEquZ19mghgyjyUKJ3uTWSLqeFkGuAALmA=";

  oxygen.vpn.public-endpoint = "vps.sodi.boo:${toString systems.oxygen.vpn.port}";

  universal =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.vpn = {
        enable = lib.mkEnableOption "virtual private network" // {
          default = true;
        };

        ip-address = lib.mkOption {
          type = lib.types.str;
          default = "10.8.0.${toString config.id}";
        };

        hostname = lib.mkOption {
          type = lib.types.str;
          default = "${config.networking.hostName}.wg";
        };

        public-endpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };

        public-key = lib.mkOption {
          type = lib.types.str;
        };

        port = lib.mkOption {
          type = lib.types.port;
          # School network seems to block UDP ports above 28000?
          default = 27462;
        };
      };

      config =
        let
          wg-interface = "wg-infra";
        in
        lib.mkIf config.vpn.enable {
          environment.systemPackages = with pkgs; [
            # This is how i generated the keys with elemental prefixes! :3
            wireguard-vanity-keygen
          ];
          networking = {
            nat = {
              enable = true;
              externalInterface = "eth0";
              internalInterfaces = [ wg-interface ];
            };
            firewall = {
              # always listen on the wireguard port on the external interfaces
              allowedUDPPorts = [ config.vpn.port ];

              # allow all traffic on the wireguard interface, no matter the port
              trustedInterfaces = [ wg-interface ];
            };

            hosts = lib.mkMerge (
              lib.mapAttrsToList (_: system: {
                ${system.vpn.ip-address} = [ system.vpn.hostname ];
              }) systems
            );

            wireguard.interfaces.${wg-interface} = {
              ips = [ "${config.vpn.ip-address}/24" ];
              listenPort = lib.mkForce config.vpn.port;
              privateKeyFile = config.sops.secrets.wireguard-private-key.path;
            };
          };

          sops.secrets.wireguard-private-key.key = "wireguard-private-keys/${config.networking.hostName}";
          sops.secrets.wgautomesh-gossip-secret = { };

          services.wgautomesh = {
            enable = true;
            gossipSecretFile = config.sops.secrets.wgautomesh-gossip-secret.path;
            settings = {
              interface = wg-interface;
              peers = lib.mapAttrsToList (
                _: system:
                lib.mkIf system.vpn.enable {
                  pubkey = system.vpn.public-key;
                  endpoint = system.vpn.public-endpoint;
                  address = system.vpn.ip-address;
                }
              ) systems;
            };
          };
        };
    };

}
