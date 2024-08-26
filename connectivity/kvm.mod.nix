{lan-mouse, ...}: let
  with-port = port: hosts: {
    modules = [
      {
        networking.firewall = {
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
    bottom.hostname = "nitrogen.wg";
  };

  nitrogen = with-port 4242 {
    top.hostname = "sodium.wg";
  };
}
