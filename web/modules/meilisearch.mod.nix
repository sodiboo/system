{
  universal =
    {
      modulesPath,
      lib,
      pkgs,
      config,
      ...
    }:
    {
      config = {
        services.meilisearch.package = pkgs.meilisearch;

        services.meilisearch.settings =
          let
            cfg = config.services.meilisearch;
          in
          lib.mkForce {
            http_addr = "${cfg.listenAddress}:${toString cfg.listenPort}";
            no_analytics = lib.mkDefault true;
          };
      };
    };
}
