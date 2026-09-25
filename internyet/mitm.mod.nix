{
  nitrogen =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      services = {
        "cyberchef" = "10.13.39.243:80";
        "fontbob" = "10.13.39.163:5173";
      };
    in
    {
      internyet.dns.slugs = builtins.attrNames services |> map (service: "${service}/cyberpink");
      caddy.sites = services |> lib.concatMapAttrs (service: backend: {
        "${service}.cyberpink.g.nyet".routes = [
          {
            terminal = true;
            handle = [
              {
                handler = "reverse_proxy";
                upstreams = [ { dial = "${backend}"; } ];
              }
            ];
          }
        ];
      });
    };
}
