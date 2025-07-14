{
  nixpkgs-with-meilisearch-secrets,
  ...
}:
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
      disabledModules = [ "${modulesPath}/services/search/meilisearch.nix" ];
      imports = [ "${nixpkgs-with-meilisearch-secrets}/nixos/modules/services/search/meilisearch.nix" ];

      config = {
        documentation.nixos.checkRedirects = false;

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
