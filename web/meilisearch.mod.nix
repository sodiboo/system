{
  oxygen =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      sops.secrets.meili-master-key = { };

      services.meilisearch = {
        enable = true;
        package = pkgs.meilisearch; # by default, on my state version, this is 1.11
        masterKeyFile = config.sops.secrets.meili-master-key.path;
        settings = {
          env = "production";

          # first one has shitty default.
          # set the rest for consistency.
          db_path = "/var/lib/meilisearch/data.ms";
          dump_dir = "/var/lib/meilisearch/dumps";
          snapshot_dir = "/var/lib/meilisearch/snapshots";
        };
      };
    };
}
