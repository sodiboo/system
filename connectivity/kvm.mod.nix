{
  lan-mouse,
  systems,
  ...
}:
let
  with-port = port: hosts: {
    home-shortcut = {
      imports = [ lan-mouse.homeManagerModules.default ];
      config = {
        programs.lan-mouse = {
          enable = true;
          settings = {
            inherit port;
          } // hosts;
        };
      };
    };
  };
in
{
  sodium = with-port 4242 {
    bottom.hostname = "nitrogen";
    bottom.ips = [ systems.nitrogen.vpn.ip-address ];
  };

  nitrogen = with-port 4242 {
    top.hostname = "sodium";
    top.ips = [ systems.sodium.vpn.ip-address ];
  };
}
