{
  lan-mouse,
  elements,
  ...
}:
let
  ip = i: "10.8.0.${toString i}";

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
    bottom.ips = [ (ip elements.nitrogen) ];
  };

  nitrogen = with-port 4242 {
    top.hostname = "sodium";
    top.ips = [ (ip elements.sodium) ];
  };
}
