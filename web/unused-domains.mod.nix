{
  oxygen =
    { lib, config, ... }:
    {
      caddy.sites =
        let
          unused-domains = [
            "catboy.rocks"
            "mrrp.ing"
            "enby.lol"
            "enby.live"
            "sodi.lol"
            "girlcock.party"
            "yester.gay"
            "infodumping.place"
          ];
        in
        lib.genAttrs unused-domains (lib.const { routes = config.caddy.routes.unknown; });
    };
}
