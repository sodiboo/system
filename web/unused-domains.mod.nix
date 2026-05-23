{
  oxygen =
    { lib, config, ... }:
    {
      caddy.sites =
        let
          unused-domains = [
            "catboy.rocks"
            "mrrp.ing"
            "sodi.lol"
            "girlcock.party"
            "yester.gay"
          ];
        in
        lib.genAttrs unused-domains (lib.const { routes = config.caddy.routes.unknown; });
    };
}
