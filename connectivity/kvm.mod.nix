{
  lan-mouse,
  extras,
  ...
}: let
  inherit (extras) wireguard-ips;
  with-port = port: hosts: {
    modules = [
      {
        networking.firewall.interfaces.wg0 = {
          allowedUDPPorts = [port];
          allowedTCPPorts = [port];
        };
      }
    ];
    home_modules = [
      lan-mouse.homeManagerModules.default
      {
        programs.lan-mouse = {
          enable = true;
          settings = {inherit port;} // hosts;
        };
      }
    ];
  };
in {
  sodium = with-port 4242 {
    bottom.hostname = "nitrogen";
    bottom.ips = [wireguard-ips.nitrogen];
  };

  nitrogen = with-port 4242 {
    top.hostname = "sodium";
    top.ips = [wireguard-ips.sodium];
  };
}
